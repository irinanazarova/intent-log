# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class PromisesTest < Minitest::Test
  SKILL = File.expand_path("../skills/intent-log", __dir__)
  RUBY = RbConfig.ruby

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, ".git"))
    FileUtils.mkdir_p(File.join(@root, "docs"))
    # check.rb asks gh for the repo's PRs; these logs tag none
    @bin = Dir.mktmpdir
    File.write(File.join(@bin, "gh"), "#!/bin/sh\necho '[]'\n")
    File.chmod(0o755, File.join(@bin, "gh"))
  end

  def teardown
    FileUtils.rm_rf([@root, @bin])
  end

  def write(path, text)
    full = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, text)
  end

  def read(path) = File.read(File.join(@root, path))

  def run_script(script, *args, cwd: @root, env: {})
    env = {"PATH" => "#{@bin}:#{ENV.fetch("PATH")}"}.merge(env)
    output, status = Open3.capture2e(env, RUBY, File.join(SKILL, script), *args, chdir: cwd)
    [output, status.success?]
  end

  def promote(*args) = run_script("promote.rb", *args)

  def check(*args) = run_script("check.rb", *args)

  def log(*promises)
    lines = promises.map { "  **promise:** #{_1}" }.join("\n")
    write("docs/intent-log.md", "# Log\n\n## Mon Aug 10, 2026\n\n- the economy\n#{lines}\n")
  end

  def test_lifts_a_promise_with_who_said_it_when_and_the_pr
    write("docs/intent/irina.md", <<~MD)
      # Irina

      ## Mon Aug 10, 2026

      - the economy `#10`
        **promise:** every accrual and spend
        recorded
    MD
    output, ok = promote

    assert ok, output
    assert_includes read("docs/promises.rb"), %(promise :every_accrual_spend_recorded,\n  "every accrual and spend recorded",)
    assert_includes read("docs/promises.rb"), %(from: "Irina, Aug 10, 2026, #10",\n  oracle: :pending)
  end

  def test_a_second_run_adds_nothing_and_keeps_hand_edits
    log("archiving deletes nothing")
    promote
    edited = read("docs/promises.rb")
      .sub(":archiving_deletes_nothing", ":archive_keeps_all")
      .sub("oracle: :pending", %(oracle: "spec/oracles/archive_spec.rb"))
    write("docs/promises.rb", edited)
    output, ok = promote

    assert ok, output
    assert_equal edited, read("docs/promises.rb")
  end

  def test_promises_outside_latin_stay_distinct
    log("баланс всегда равен сумме", "платёж никогда не дублируется")
    promote

    assert_includes read("docs/promises.rb"), "баланс всегда равен сумме"
    assert_includes read("docs/promises.rb"), "платёж никогда не дублируется"
    assert_includes read("docs/promises.rb"), "promise :баланс_всегда_равен_сумме,"
    output, ok = promote("--check")

    assert ok, output
  end

  def test_quotes_and_interpolation_shaped_text_survive_a_round_trip
    log(%(the "Join" line is painted), 'a #{name} stays literal')
    promote
    output, = promote

    assert_includes output, "already holds every promise"
    assert_equal 2, read("docs/promises.rb").scan(/^promise :/).size
  end

  def test_promises_file_is_never_executed
    log("archiving deletes nothing")
    write("docs/promises.rb", %(File.write("#{@root}/pwned", "x")\n))
    output, ok = promote("--check")

    refute ok
    assert_includes output, "docs/promises.rb:1: only promise calls belong here"
    refute File.exist?(File.join(@root, "pwned"))
  end

  def test_a_computed_value_is_refused
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes \#{`whoami`}"\n))
    output, ok = promote("--check")

    refute ok
    assert_includes output, "only literal values belong here"
  end

  def test_check_rb_reports_a_broken_promises_file
    log("archiving deletes nothing")
    write("docs/promises.rb", "promise :x,\n")
    output, ok = check

    refute ok
    assert_includes output, "promises.rb is not valid Ruby"
  end

  def test_a_mistyped_oracle_is_refused_rather_than_counted_as_checked
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes nothing", oracle: :pendng\n))
    output, ok = promote("--check")

    refute ok
    assert_includes output, "oracle: is :pending or a path, not :pendng"
  end

  def test_an_unknown_keyword_is_refused
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes nothing", orcale: "x.rb"\n))
    output, ok = promote("--check")

    refute ok
    assert_includes output, "unknown orcale"
  end

  def test_an_oracle_path_that_does_not_exist_fails
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes nothing", oracle: "spec/gone_spec.rb"\n))
    output, ok = promote("--check")

    refute ok
    assert_includes output, ":a points at spec/gone_spec.rb, which does not exist"
  end

  def test_an_oracle_that_never_names_the_promise_fails
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a_slug, "archiving deletes nothing", oracle: "spec/empty_spec.rb"\n))
    write("spec/empty_spec.rb", "\n")
    output, ok = promote("--check")

    refute ok
    assert_includes output, "which never names it"
  end

  def test_an_oracle_counts_when_it_carries_the_words
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a_slug, "archiving deletes nothing", oracle: ["spec/a_spec.rb", "spec/b_spec.rb"]\n))
    write("spec/a_spec.rb", %(it "Archiving deletes\n  nothing" do\nend\n))
    write("spec/b_spec.rb", "# :a_slug\n")
    output, ok = promote("--check")

    assert ok, output
    assert_includes output, "1 promise(s) kept, 1 checked by an oracle"
  end

  def test_a_retired_promise_stays_out_of_the_way_and_does_not_come_back
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes nothing",\n  oracle: "spec/gone_spec.rb",\n  retired: "Irina, Sep 3: cold storage"\n))
    before = read("docs/promises.rb")
    promote
    output, ok = promote("--check")

    assert_equal before, read("docs/promises.rb")
    assert ok, output
    refute_includes output, "no oracle yet"
  end

  def test_pending_is_a_note_unless_strict
    log("archiving deletes nothing")
    promote
    output, ok = promote("--check")

    assert ok, output
    assert_includes output, "note: 1 promise(s) with no oracle yet: :archiving_deletes_nothing"
    output, ok = promote("--check", "--strict")

    refute ok, output
  end

  def test_says_when_no_agent_would_read_the_file
    log("archiving deletes nothing")
    promote
    output, = promote("--check")

    assert_includes output, "no CLAUDE.md or AGENTS.md mentions promises.rb"
    write("AGENTS.md", "Read docs/promises.rb first.\n")
    output, = promote("--check")

    refute_includes output, "no CLAUDE.md"
  end

  def test_check_works_from_outside_the_repo
    log("archiving deletes nothing")
    write("docs/promises.rb", %(promise :a, "archiving deletes nothing", oracle: "spec/a_spec.rb"\n))
    write("spec/a_spec.rb", %(it "archiving deletes nothing"\n))
    output, ok = run_script("check.rb", File.join(@root, "docs/intent-log.md"), cwd: SKILL)

    assert ok, output
    assert_includes output, "ok: 0 PRs"
  end

  def test_a_repo_with_no_promises_sees_no_change
    write("docs/intent-log.md", "# Log\n\n## Mon Aug 10, 2026\n\n- the economy\n")
    output, ok = check

    assert ok, output
    assert_equal "ok: 0 PRs accounted for across 1 entries\n", output
    refute File.exist?(File.join(@root, "docs/promises.rb"))
  end

  def test_extract_reads_staging_once_transcripts_are_gone
    home = Dir.mktmpdir
    write(".intent/staging/2026-08-18.jsonl", [
      {at: "2026-08-18T10:00:00-07:00", text: "the price is coins or hearts, but never both", session: "s"},
      {at: "2026-08-18T10:05:00-07:00", text: "make the button blue", session: "s"}
    ].map(&:to_json).join("\n"))
    output, ok = run_script("extract.rb", "dump", "2026-08-18", "--repo", @root, env: {"HOME" => home})

    assert ok, output
    assert_includes output, "make the button blue"
    output, ok = run_script("extract.rb", "promises", "--repo", @root, env: {"HOME" => home})

    assert ok, output
    assert_includes output, "never both"
    refute_includes output, "button blue"
  ensure
    FileUtils.rm_rf(home)
  end
end
