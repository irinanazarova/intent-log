#!/usr/bin/env ruby
# frozen_string_literal: true

# Lift every **promise:** sub-line out of the intent log into docs/promises.rb.
# The log says how we came to want something. This file says what must stay
# true today, in the words it was said in, and points each promise at the
# oracle that checks it, so the next agent knows what it must not break.
#
# Add-only. A promise already in the file, by its words, is left alone, so
# whatever somebody attached to it survives the next run. Why, and how an
# oracle gets written, is in SKILL.md.

require "date"
require "optparse"
require "pathname"
require "ripper"

options = {log: "docs/intent-log.md", year: Date.today.year, check: false, strict: false}
OptionParser.new do |opts|
  opts.banner = "usage: promote.rb [options]"
  opts.on("--log PATH", "solo log, read when there is no --dir (default: docs/intent-log.md)") { options[:log] = _1 }
  opts.on("--dir PATH", "per-person files, read when present (default: intent/ beside the log)") { options[:dir] = _1 }
  opts.on("--out PATH", "the promises file (default: promises.rb beside the log)") { options[:out] = _1 }
  opts.on("--year YEAR", Integer, "year the headings belong to") { options[:year] = _1 }
  opts.on("--check", "exit 1 if a promise is missing or an oracle does not check it") { options[:check] = true }
  opts.on("--strict", "with --check, a promise with no oracle fails too") { options[:strict] = true }
end.parse!
options[:dir] ||= File.join(File.dirname(options[:log]), "intent")
options[:out] ||= File.join(File.dirname(options[:log]), "promises.rb")

HEADER = <<~RUBY
  # What must stay true, in the words it was said in, with the oracle that checks it.
  # promote.rb adds new ones at the bottom from the intent log; edit the rest by hand.
  # Retire a promise rather than delete it: the log still says it, so it would come back.
RUBY

Promise = Struct.new(:slug, :said, :from, :oracle, :retired, keyword_init: true)

# docs/promises.rb reads as Ruby and is never run. check.rb runs on whatever
# branch is checked out, and evaluating this file would run that branch's code.
class Book
  KEYWORDS = %w[from oracle retired].freeze

  def self.read(path)
    return [] unless File.exist?(path)

    tree = Ripper.sexp(File.read(path)) or abort "#{path} is not valid Ruby; `ruby -c #{path}` says where"
    tree[1].reject { _1.first == :void_stmt }.map { new(path).promise(_1) }
  end

  def initialize(path) = @path = path

  def promise(node)
    args = arguments(node)
    slug, said, options = args.map { literal(_1, node) }
    options ||= {}
    refuse(node, "a promise is a symbol and its words") unless slug.is_a?(Symbol) && said.is_a?(String) && !said.strip.empty?

    unknown = options.keys - KEYWORDS
    refuse(node, "unknown #{unknown.join(", ")}") if unknown.any?
    refuse(node, "from: is a string") unless options.fetch("from", "").is_a?(String)
    refuse(node, "retired: is a string saying who and why") unless options.fetch("retired", "").is_a?(String)

    oracle = options.fetch("oracle", :pending)
    unless oracle == :pending || oracle.is_a?(String) || (oracle.is_a?(Array) && oracle.all?(String))
      refuse(node, "oracle: is :pending or a path, not #{oracle.inspect}")
    end

    Promise.new(slug:, said:, from: options["from"], oracle:, retired: options["retired"])
  end

  private

  def arguments(node)
    case node
    in [:command, [:@ident, "promise", _], [:args_add_block, args, false]] then args
    in [:method_add_arg, [:fcall, [:@ident, "promise", _]], [:arg_paren, [:args_add_block, args, false]]] then args
    else refuse(node, "only promise calls belong here")
    end
  end

  def literal(value, node)
    case value
    in [:symbol_literal, [:symbol, [_, name, _]]] then name.to_sym
    in [:string_literal, [:string_content, *parts]] if parts.all? { _1.first == :@tstring_content }
      parts.map { _1[1] }.join.gsub(/\\(.)/m, '\1')
    in [:string_concat, left, right] then literal(left, node) + literal(right, node)
    in [:array, Array => items] then items.map { literal(_1, node) }
    in [:bare_assoc_hash, pairs]
      pairs.to_h do |pair|
        pair in [:assoc_new, [:@label, label, _], item] or refuse(node, "only plain keywords belong here")
        [label.delete_suffix(":"), literal(item, node)]
      end
    else refuse(node, "only literal values belong here")
    end
  end

  def refuse(node, reason)
    abort "#{@path}:#{node.flatten.grep(Integer).first}: #{reason}"
  end
end

# Where a repo keeps its oracles, wherever this was run from.
def project_root(path)
  dir = Pathname(File.expand_path(path)).dirname
  (dir.ascend.find { (_1 + ".git").exist? } || dir.parent).to_s
end

# A line that opens its own unit, so a wrapped sub-line can be put back
# together before it is read.
OPENER = /\A(?:- |\s*\*\*|\*|[A-Z][A-Za-z ]*:\s*\z)/

def units(block)
  block.each_line.with_object([]) do |line, list|
    line = line.rstrip
    next if line.empty?
    if list.empty? || line.match?(OPENER) then list << +line
    else list.last << " " << line.strip
    end
  end
end

def heading_date(heading, year)
  match = heading.match(/([A-Z][a-z]{2}) +(\d{1,2})/)
  month = Date::ABBR_MONTHNAMES.index(match[1]) if match
  Date.new(year, month, match[2].to_i) if month
end

# A composed day carries one `### Name` section per author.
def author_sections(text)
  parts = text.split(/^### +(.+)$/)
  return [[nil, text]] if parts.size == 1

  parts[1..].each_slice(2).map { |name, body| [name.strip, body.to_s] }
end

# Per-person files when the team keeps them, the one log when it doesn't.
def logs(options)
  if Dir.exist?(options[:dir])
    Dir.glob(File.join(options[:dir], "*.md")).reject { File.basename(_1).start_with?("_") }.sort.map do |path|
      [path, File.read(path)[/\A\s*#\s+(.+)$/, 1]&.strip || File.basename(path, ".md")]
    end
  elsif File.exist?(options[:log])
    [[options[:log], nil]]
  else
    []
  end
end

# Every **promise:** sub-line, with who said it, the day, and the PR of the
# bullet it sits under. The year is carried forward as compose.rb does it.
def said(path, display, fallback)
  year = nil
  File.read(path).split(/^## +(.+)$/)[1..].to_a.each_slice(2).flat_map do |heading, text|
    named = heading[/\b(20\d{2})\b/, 1]&.to_i
    year = named || year || fallback
    date = heading_date(heading, year)
    next [] unless date

    author_sections(text.to_s).flat_map do |who, body|
      bullet = nil
      body.split("\n\n").flat_map { units(_1) }.filter_map do |unit|
        if unit.start_with?("- ")
          bullet = unit
          next
        end

        words = unit[/\A\s*\*\*promise:\*\*\s*(.+)\z/i, 1]
        next unless words

        pr = bullet&.[](/`#(\d+)/, 1)
        from = [who || display, date.strftime("%b %-d, %Y"), pr && "##{pr}"].compact.join(", ")
        {said: words.strip, from:}
      end
    end
  end
end

def key(text) = text.downcase.gsub(/[^\p{Alnum}\s]/, "").split.join(" ")

FILLER = %w[a an the is are be it its of to that this when we our and or].freeze

def slug(text, taken)
  words = key(text).split - FILLER
  base = words.first(5).join("_")
  base = "promise" if base.empty?
  base = "p_#{base}" if base.match?(/\A\d/)
  name, n = base, 1
  name = "#{base}_#{n += 1}" while taken.include?(name)
  taken << name
  name
end

def render(promise)
  <<~RUBY
    promise :#{promise.slug},
      #{promise.said.inspect},
      from: #{promise.from.inspect},
      oracle: :pending
  RUBY
end

sources = logs(options)
all_said = sources.flat_map { |path, display| said(path, display, options[:year]) }
kept = Book.read(options[:out])
known = kept.map { key(_1.said) }
fresh = all_said.reject { known.include?(key(_1[:said])) }.uniq { key(_1[:said]) }

if options[:check]
  failures = []
  fresh.each do |item|
    failures << "promise not in #{options[:out]}: \"#{item[:said]}\" (#{item[:from]}); run promote.rb"
  end
  kept.group_by(&:slug).each do |slug, same|
    failures << ":#{slug} names #{same.size} promises; give each its own" if same.size > 1
  end
  live = kept.reject(&:retired)
  root = project_root(options[:out])
  live.each do |promise|
    next if promise.oracle == :pending

    Array(promise.oracle).each do |oracle|
      path = File.expand_path(oracle, root)
      unless File.file?(path)
        failures << ":#{promise.slug} points at #{oracle}, which does not exist"
        next
      end

      source = File.read(path).scrub
      next if key(source).include?(key(promise.said)) || source.include?(promise.slug.to_s)

      failures << ":#{promise.slug} points at #{oracle}, which never names it; " \
        "put the promise's words in the test's name"
    end
  end

  told = %w[CLAUDE.md AGENTS.md .claude/CLAUDE.md].any? do |name|
    path = File.join(root, name)
    File.file?(path) && File.read(path).scrub.include?(File.basename(options[:out]))
  end
  puts "note: no CLAUDE.md or AGENTS.md mentions #{File.basename(options[:out])}, so an agent here never reads it" if live.any? && !told

  pending = live.select { _1.oracle == :pending }
  if pending.any?
    line = "#{pending.size} promise(s) with no oracle yet: #{pending.map { ":#{_1.slug}" }.join(", ")}"
    options[:strict] ? failures << line : puts("note: #{line}")
  end

  if failures.any?
    puts "#{failures.size} problem(s):"
    failures.each { puts "  - #{_1}" }
    exit 1
  end
  puts "ok: #{live.size} promise(s) kept, #{live.size - pending.size} checked by an oracle"
  exit
end

if fresh.empty?
  puts "ok: #{options[:out]} already holds every promise in the log"
  exit
end

taken = kept.map { _1.slug.to_s }
added = fresh.map { Promise.new(slug: slug(_1[:said], taken), said: _1[:said], from: _1[:from]) }
existing = File.exist?(options[:out]) ? File.read(options[:out]) : HEADER
File.write(options[:out], existing.rstrip + "\n\n" + added.map { render(_1) }.join("\n"))
puts "promoted #{added.size} promise(s) into #{options[:out]}:"
added.each { puts "  :#{_1.slug}  #{_1.said}" }
