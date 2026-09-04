#!/usr/bin/env ruby
# frozen_string_literal: true

# Assert the invariants an intent log must hold. Run after every write.
# --fix rewraps the file instead of complaining about it.

require "json"
require "date"
require "optparse"

options = {log: "docs/intent-log.md", year: Date.today.year, max_words: 400,
           max_bullet: 20, width: 79, fix: false, repo: nil, dir: "docs/intent"}
parser = OptionParser.new do |opts|
  opts.banner = "usage: check.rb [docs/intent-log.md] [options]"
  opts.on("--year YEAR", Integer, "year the headings belong to") { options[:year] = _1 }
  opts.on("--max-words N", Integer, "longest a day may run (default: 400)") { options[:max_words] = _1 }
  opts.on("--max-bullet N", Integer, "longest a bullet may run (default: 20)") { options[:max_bullet] = _1 }
  opts.on("--width N", Integer, "wrap width (default: 79)") { options[:width] = _1 }
  opts.on("--repo OWNER/NAME", "repo the PRs belong to (default: cwd)") { options[:repo] = _1 }
  opts.on("--dir PATH", "per-person sources, if any (default: docs/intent)") { options[:dir] = _1 }
  opts.on("--fix", "rewrap the file rather than report on it") { options[:fix] = true }
end
parser.parse!
options[:log] = ARGV.shift if ARGV.any?

# A line that opens its own unit: a bullet, a **why:** sub-line under one, an
# italic tail, or a section label.
OPENER = /\A(?:- |\s*\*\*|\*|[A-Z][A-Za-z ]*:\s*\z)/

# A sub-line reasons under the bullet above it and is indented to say so.
SUBLINE = /\A\s*\*\*/

# A backticked span is one token: `#7 dropped` must never break across lines.
def wrap(text, width)
  text.split.join(" ").scan(/`[^`]*`\S*|\S+/).each_with_object([+""]) do |word, lines|
    if lines.last.empty? then lines[-1] = +word
    elsif lines.last.length + 1 + word.length <= width then lines.last << " " << word
    else lines << +word
    end
  end.join("\n")
end

# Wrapping a Wanted/Shipped block by paragraph would glue its bullets into one.
def units(block)
  block.each_line.with_object([]) do |line, list|
    line = line.rstrip
    next if line.empty?
    if list.empty? || line.match?(OPENER) then list << +line
    else list.last << " " << line.strip
    end
  end
end

def rewrap_units(block, width)
  units(block).map do |unit|
    next "- " + wrap(unit.delete_prefix("- "), width - 2).gsub("\n", "\n  ") if unit.start_with?("- ")
next "  " + wrap(unit.strip, width - 2).gsub("\n", "\n  ") if unit.match?(SUBLINE)

    wrap(unit, width)
  end.join("\n")
end

def rewrap(source, width)
  source.split("\n\n").filter_map do |block|
    block = block.strip
    next if block.empty?
    next block if block.start_with?("#", "---", "```")
    next rewrap_units(block, width) if block.lines.any? { _1.match?(OPENER) }

    wrap(block, width)
  end.join("\n\n") + "\n"
end

def pull_requests(repo)
  target = repo ? "--repo #{repo}" : ""
  raw = `gh pr list #{target} --state all --limit 500 --json number,state,title,author`
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

# Every "Wed Jul 15" in a heading, so a range heading is checked at both ends.
def heading_days(heading, year)
  heading.scan(/([A-Z][a-z]{2}) +([A-Z][a-z]{2}) +(\d{1,2})/).filter_map do |weekday, name, day|
    month = Date::ABBR_MONTHNAMES.index(name)
    [weekday, Date.new(year, month, day.to_i)] if month
  end
end

# A composed day carries one `### Name` section per author, and a day with a
# single author carries none. Either way the word cap is one person's.
def author_sections(text)
  parts = text.split(/^### +(.+)$/)
  return [[nil, text]] if parts.size == 1

  parts[1..].each_slice(2).map { |name, body| [name.strip, body.to_s] }
end

# Bullets, reassembled from their continuation lines.
def bullets(text)
  text.split("\n\n").flat_map { units(_1) }.filter_map { _1.delete_prefix("- ") if _1.start_with?("- ") }
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

unlogged = Hash.new { |h, k| h[k] = [] }
tagged = Hash.new { |h, k| h[k] = [] }
body.scan(/#(\d+)(?: (dropped|open))?/) { |number, marker| tagged[number.to_i] << marker }

expected = {"MERGED" => nil, "CLOSED" => "dropped", "OPEN" => "open"}
known.sort.each do |number, pr|
  markers = tagged[number]
  if markers.empty?
    who = pr.dig("author", "login")
    unlogged[who] << number if who
    by = who ? " by #{who}" : ""
    failures << "##{number} (#{pr["state"].downcase})#{by} is in no entry: #{pr["title"]}"
    next
  end

  want = expected.fetch(pr["state"])
  markers.reject { _1 == want }.each do |got|
    shown = got ? "`##{number} #{got}`" : "a bare `##{number}`"
    wanted = want ? "`##{number} #{want}`" : "a bare `##{number}`"
    failures << "#{shown} marks a #{pr["state"].downcase} PR; expected #{wanted}"
  end
  failures << "##{number} is tagged #{markers.size} times; tag it on one bullet" if markers.size > 1
end
(tagged.keys - known.keys).sort.each { failures << "##{_1} is tagged but no such PR exists" }

# lines stay wrapped, so a hand edit cannot leave a 200-char line behind
body.lines.each.with_index(1) do |line, number|
  line = line.chomp
  next unless line.length > options[:width] && line[0, options[:width]].include?(" ")

  failures << "line #{number} is #{line.length} chars; rerun with --fix"
end

# entries run oldest first, hold lists rather than prose, and stay short
dated = entries(body).filter_map { |heading, text| [heading, text, heading_date(heading, options[:year])] if heading_date(heading, options[:year]) }
dated.each_cons(2) do |(_, _, earlier), (heading, _, later)|
  failures << "'#{heading}' comes after #{earlier}; entries run oldest first" if later < earlier
end
dated.each do |heading, text, _|
  author_sections(text).each do |who, section|
    words = section.gsub(/^[-*#]\s*/, "").split.size
    next unless words > options[:max_words]

    whose = who ? "#{who}'s half of '#{heading}'" : "'#{heading}'"
    failures << "#{whose} is #{words} words; keep a day under #{options[:max_words]}"
  end

  failures << "'#{heading}' is prose, not a list" if bullets(text).empty?

  heading_days(heading, options[:year]).each do |weekday, date|
    real = date.strftime("%a")
    failures << "'#{heading}' calls #{date} #{weekday}; it was a #{real}" unless weekday == real
  end

  bullets(text).each do |bullet|
    size = bullet.split.size
    next unless size > options[:max_bullet]

    failures << "'#{heading}' has a #{size}-word bullet; keep one under #{options[:max_bullet]}: #{bullet[0, 60]}..."
  end
end

# A teammate who shipped and wrote nothing is the failure a team log has that a
# solo one cannot: the entries left are all correct, and a person is missing.
if Dir.exist?(options[:dir])
  compose = File.join(__dir__, "compose.rb")
  if File.exist?(compose)
    `ruby #{compose} --dir #{options[:dir]} --out #{options[:log]} --year #{options[:year]} --check 2>&1`
    failures << "#{options[:log]} is out of date with #{options[:dir]}; run compose.rb" unless $?.success?
  end

  unlogged.each do |who, numbers|
    next if who.end_with?("[bot]")
    next if File.exist?(File.join(options[:dir], "#{who}.md"))

    failures << "#{who} has #{numbers.size} PR(s) here and no #{options[:dir]}/#{who}.md"
  end
end

if failures.any?
  puts "#{failures.size} problem(s):"
  failures.each { puts "  - #{_1}" }
  exit 1
end

puts "ok: #{known.size} PRs accounted for across #{dated.size} entries"
