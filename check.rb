#!/usr/bin/env ruby
# frozen_string_literal: true

# Assert the invariants an intent log must hold. Run after every write.
# --fix rewraps the file instead of complaining about it.

require "json"
require "date"
require "optparse"

options = {log: "docs/intent-log.md", year: Date.today.year, max_words: 260, width: 79, fix: false, repo: nil}
parser = OptionParser.new do |opts|
  opts.banner = "usage: check.rb [docs/intent-log.md] [options]"
  opts.on("--year YEAR", Integer, "year the headings belong to") { options[:year] = _1 }
  opts.on("--max-words N", Integer, "longest a day may run (default: 260)") { options[:max_words] = _1 }
  opts.on("--width N", Integer, "wrap width (default: 79)") { options[:width] = _1 }
  opts.on("--repo OWNER/NAME", "repo the PRs belong to (default: cwd)") { options[:repo] = _1 }
  opts.on("--fix", "rewrap the file rather than report on it") { options[:fix] = true }
end
parser.parse!
options[:log] = ARGV.shift if ARGV.any?

# A backticked span is one token: `#7 dropped` must never break across lines.
def wrap(text, width)
  text.split.join(" ").scan(/`[^`]*`\S*|\S+/).each_with_object([+""]) do |word, lines|
    if lines.last.empty? then lines[-1] = +word
    elsif lines.last.length + 1 + word.length <= width then lines.last << " " << word
    else lines << +word
    end
  end.join("\n")
end

def rewrap(source, width)
  source.split("\n\n").filter_map do |block|
    block = block.strip
    next if block.empty?
    next block if block.start_with?("#", "---", "```")

    wrap(block, width)
  end.join("\n\n") + "\n"
end

def pull_requests(repo)
  target = repo ? "--repo #{repo}" : ""
  raw = `gh pr list #{target} --state all --limit 500 --json number,state,title`
  abort "gh pr list failed" unless $?.success?
  JSON.parse(raw).to_h { [_1["number"], _1] }
end

def entries(body)
  body.split(/^## +(.+)$/)[1..].to_a.each_slice(2).map { |heading, text| [heading.strip, text.to_s] }
end

def heading_date(heading, year)
  match = heading.match(/([A-Z][a-z]{2}) +(\d{1,2})/)
  month = Date::ABBR_MONTHNAMES.index(match[1]) if match
  Date.new(year, month, match[2].to_i) if month
end

source = File.read(options[:log])

if options[:fix]
  File.write(options[:log], rewrap(source, options[:width]))
  puts "rewrapped #{options[:log]} at #{options[:width]}"
  exit
end

# the header may show example tags; only entries count
body = source.include?("\n## ") ? source[source.index("\n## ")..] : source
known = pull_requests(options[:repo])
failures = []

tagged = Hash.new { |h, k| h[k] = [] }
body.scan(/#(\d+)(?: (dropped|open))?/) { |number, marker| tagged[number.to_i] << marker }

expected = {"MERGED" => nil, "CLOSED" => "dropped", "OPEN" => "open"}
known.sort.each do |number, pr|
  markers = tagged[number]
  if markers.empty?
    failures << "##{number} (#{pr["state"].downcase}) is in no entry: #{pr["title"]}"
    next
  end

  want = expected.fetch(pr["state"])
  markers.reject { _1 == want }.each do |got|
    shown = got ? "`##{number} #{got}`" : "a bare `##{number}`"
    wanted = want ? "`##{number} #{want}`" : "a bare `##{number}`"
    failures << "#{shown} marks a #{pr["state"].downcase} PR; expected #{wanted}"
  end
  failures << "##{number} is tagged #{markers.size} times; tag it on one sentence" if markers.size > 1
end
(tagged.keys - known.keys).sort.each { failures << "##{_1} is tagged but no such PR exists" }

# lines stay wrapped, so a hand edit cannot leave a 200-char line behind
body.lines.each.with_index(1) do |line, number|
  line = line.chomp
  next unless line.length > options[:width] && line[0, options[:width]].include?(" ")

  failures << "line #{number} is #{line.length} chars; rerun with --fix"
end

# entries run oldest first, and stay short
dated = entries(body).filter_map { |heading, text| [heading, text, heading_date(heading, options[:year])] if heading_date(heading, options[:year]) }
dated.each_cons(2) do |(_, _, earlier), (heading, _, later)|
  failures << "'#{heading}' comes after #{earlier}; entries run oldest first" if later < earlier
end
dated.each do |heading, text, _|
  words = text.split.size
  failures << "'#{heading}' is #{words} words; keep a day under #{options[:max_words]}" if words > options[:max_words]
end

if failures.any?
  puts "#{failures.size} problem(s):"
  failures.each { puts "  - #{_1}" }
  exit 1
end

puts "ok: #{known.size} PRs accounted for across #{dated.size} entries"
