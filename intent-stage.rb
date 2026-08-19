#!/usr/bin/env ruby
# frozen_string_literal: true

# SessionEnd hook: stage this session's own prompts for the intent log.
#
# Reconstructing intent weeks later is lossy, so each session drops its prompts
# into .intent/staging/<date>.jsonl while they are fresh and /intent-log writes
# the day's paragraph from them. Only user turns are read, never the assistant's.
#
# Never blocks and never fails a session: any error exits 0 silently.

require "json"
require "set"
require "time"
require "fileutils"

# Claude Code marks injected content (skill bodies, image placeholders, caveats)
# with isMeta, which covers far more than a list of prefixes ever did.
NOISE_PREFIXES = ["<", "[Request", "This session is being continued"].freeze

NOISE_EXACT = [
  "continue", "continue from where you left off.", "/compact", "/clear",
  "go", "ok", "yes", "yep", "thanks", "thank you", "push", "merge"
].freeze

def message_text(content)
  case content
  when String then content
  when Array then content.filter_map { _1["text"] if _1.is_a?(Hash) && _1["type"] == "text" }.join(" ")
  end
end

def prompts_in(transcript)
  File.foreach(transcript).filter_map do |line|
    record = begin
      JSON.parse(line)
    rescue JSON::ParserError
      next
    end
    next unless record["type"] == "user" && record["timestamp"]
    next if record["isMeta"]

    text = message_text(record.dig("message", "content"))&.strip
    next if text.nil? || text.length < 4
    next if NOISE_PREFIXES.any? { text.start_with?(_1) } || NOISE_EXACT.include?(text.downcase)

    {"at" => Time.parse(record["timestamp"]).localtime.iso8601, "text" => text}
  end
end

begin
  event = JSON.parse($stdin.read)
  transcript = event["transcript_path"]
  root = event["cwd"] || Dir.pwd
  exit 0 unless transcript && File.file?(transcript)

  staging = File.join(root, ".intent", "staging")
  FileUtils.mkdir_p(staging)

  prompts_in(transcript).group_by { _1["at"][0, 10] }.each do |day, prompts|
    file = File.join(staging, "#{day}.jsonl")
    seen = File.exist?(file) ? File.readlines(file).map(&:strip).to_set : Set.new
    fresh = prompts.map { JSON.generate(_1.merge("session" => event["session_id"])) }.reject { seen.include?(_1) }
    File.open(file, "a") { |f| fresh.each { |line| f.puts(line) } } if fresh.any?
  end
rescue StandardError
  # staging is a convenience, never a reason to fail a session
end

exit 0
