# Intent log

**One short list per day of what you wanted, tagged with the PRs it produced.**

When an agent writes the code, you ship more of it than your team can read. The
code is in git. What is *not* in git is what you were after: what you asked for,
what you refused, what you changed your mind about, what you gave up on. That
turns out to be the part a colleague needs in order to help.

So it is one list a day, in order, and a PR tag on each line saying where that
line got to. A teammate reads a month of it in one sitting and knows where to
spend an hour.

**It is not a changelog and not `git log`.** Those tell you what changed. This
tells you what was wanted, including the things that left no trace in git at
all, because they were dropped, postponed, or never built:

|  | answers |
| --- | --- |
| `git log` | what changed |
| a changelog | what shipped |
| **an intent log** | **what was wanted, and what came of it** |

---

## What one day looks like

```markdown
## Fri Aug 14

- the pier: find-yourself map, quests, sponsors, wildlife `#26`
- changed my mind on placement: a random free spot each, so you search for
  your friends
- sponsor banners on rooftops, sized by tier, never overlapping anyone
- leg repair I approve in admin rather than something that just happens `#25`
- a "send hi" button on a card that opens a Slack DM

*From review: `#28`*
*Could use a hand: the Slack DM deep link. I decided it's a whole feature and
postponed it, still want it.*
```

The tag carries the status, so nothing needs a second list to report an outcome:

- `` `#26` `` — merged, it's done
- `` `#61 open` `` — still in progress
- `` `#7 dropped` `` — the PR was closed
- no tag — nothing shipped for it

That last one is the point. `a "send hi" button` has no tag, so a month later it
is still visibly missing, and `*Could use a hand:*` says so out loud.

## Real numbers

[`example/sfruby-cards.md`](example/sfruby-cards.md) is a real log, not a
sample: four weeks of building a conference game, reconstructed from the
session prompts that built it.

- **75 pull requests** across **16 entries**
- **1,444 words** — about six minutes of reading, for the month
- every PR accounted for exactly once, asserted by `check.rb`:

```sh
ruby check.rb example/sfruby-cards.md --year 2026 --repo palkan/sfruby-clouds
# ok: 75 PRs accounted for across 16 entries
```

## Install

```sh
git clone https://github.com/irinanazarova/intent-log ~/.claude/skills/intent-log
```

Then in any repo, in Claude Code:

```
/intent-log
```

It reads your own prompts, asks `gh` what shipped, and writes
`docs/intent-log.md`. Run it at the end of a working day, or point it at a date
range to backfill a project that is already built.

## The two scripts

`SKILL.md` holds the rules for writing an entry. The scripts hold the parts that
should never be a judgment call:

```sh
ruby extract.rb blocks --repo ~/code/myapp          # what the work blocks were
ruby extract.rb dump 2026-08-14 --repo ~/code/myapp # that day's prompts
ruby check.rb docs/intent-log.md                    # invariants
ruby check.rb docs/intent-log.md --fix              # rewrap
```

**`extract.rb` reads only your own prompts, never the assistant's turns.** Every
rule in it is there because reconstructing the example without it produced a
wrong answer:

- **Transcript timestamps are UTC.** Bucketing on the raw date moves anything
  before ~07:00 local onto the wrong day. Go-live landed a day late, and a
  decision made on Sunday evening showed up as Monday's.
- **Worktree sessions live in sibling directories.** `~/.claude/projects/` holds
  a separate directory per worktree, so missing them makes your own asks look
  like work the agent started on its own. Six were missed the first time.
- **A day is a work block, not a calendar date.** Sessions run past midnight, so
  it segments on a five-hour idle gap and labels the block by the day it began.

**`check.rb` asserts what reading cannot.** Every PR appears exactly once with
the right state marker, entries run oldest first, each day is a list rather than
prose, no bullet runs to a paragraph, no day runs long, and the weekday in a
heading is the real one. It catches dropped PRs; the weekday rule is in there
because three headings in the example named the wrong day.

## Capturing as you go

Reconstructing weeks later is lossy and slow. `intent-stage.rb` is a `SessionEnd`
hook that drops each session's prompts into `.intent/staging/<date>.jsonl` while
they are fresh, so the day's entry is written from real material instead of
archaeology. It also sidesteps the timezone and worktree traps above, because a
session knows its own transcript and directory.

```sh
cp intent-stage.rb ~/code/myapp/.claude/hooks/
```

```json
{"hooks": {"SessionEnd": [{"hooks": [
  {"type": "command", "command": "ruby \"$CLAUDE_PROJECT_DIR/.claude/hooks/intent-stage.rb\"", "timeout": 15}
]}]}}
```

Put that in `.claude/settings.local.json` rather than the committed
`settings.json`, so nobody on the team inherits a hook they did not ask for, and
add `.intent/` to `.gitignore`.

## Why this might be worth something

The claim is not that a log replaces review. It is that a colleague who reads a
month of intent in six minutes knows where to spend an hour, and that is a much
better question to put to them than "can you review 75 PRs".

Unverified so far. That is what the example is for.
