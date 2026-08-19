---
name: intent-log
description: Keep or reconstruct docs/intent-log.md, a short chronological record of what the human wanted and what shipped, so a teammate who was away can catch up in five minutes and see where to help. Use when asked to update, write, backfill, or reconstruct an intent log, or when catching a colleague up on a burst of AI-assisted work.
---

# Intent log

A team ships faster than it can review. The code is in git; what the person
*wanted* is not, and that is what a returning teammate actually needs. This
skill keeps `docs/intent-log.md`: one short paragraph per day of work, in
chronological order, tagged with PR numbers.

## What belongs in it

**Intent and outcome. Nothing else.**

Every sentence must trace to something the human said, decided, refused, changed
their mind about, or gave up on. If a sentence would still be true after
somebody rewrites the implementation, it belongs. Otherwise it is PR-body
material and gets cut.

Back and forth is the default condition of the work, so narrating it carries no
information. It earns a line only in three cases:

- **They gave up.** "The ocean I could not get right at any volume, so I pulled
  it out entirely."
- **They reversed a decision.** "Changed my mind about placement: not
  centre-outwards, everyone gets a random free spot."
- **They parked something.** "Decided it's a whole feature and postponed it."

Cut everything else: reviews run, tests written, iterations tried, servers
restarted, things checked on a phone. Work the agent initiated and the human
never asked for is not intent; it goes in the day's `*From review:*` tail so the
PR is still accounted for.

## Style

Plain and laid back, first person, the way the person actually talks. No
"leveraged", no "implemented", no "successfully". Prefer the verbs of intent:
asked, wanted, refused, decided, changed my mind, postponed, gave up.

**Name the concrete thing.** "Two fields that both mean the name" is
unreadable a week later; "`name` and `full_name`" is not. A vague noun is the
single most common way one of these entries goes stale.

**Say where an idea came from** when it wasn't the author's: a reviewer's
comment, a player's feedback, the team. That is the collaboration signal a
teammate reads the log for.

**Say a thing once.** "Not anonymous though, this communication isn't
anonymous" says it twice in one breath. So does a paragraph that describes the
open problem and then repeats it in the day's `*Could use a hand:*` line: let
the help line carry it, and keep the paragraph to what shipped.

**One paragraph per day**, under 260 words even if the day produced 18 PRs.

End a day with `*Could use a hand: ...*` when something is genuinely stuck or
wanted. This is the point of the whole file: it turns a diary into a list a
colleague can act on.

## Format

```markdown
## Fri Aug 14

The pier ships. `#26` Changed my mind about placement: not centre-outwards,
everyone gets a random free spot, so you actually have to search for your
friends. [...] Wanted a "send hi" button that opens a Slack DM with that person,
decided it's a whole feature and postponed it.

*From review: `#28` `#36`*

*Could use a hand: that Slack DM deep link. Still want it, still not built.*
```

Newest entries go at the **bottom**. PRs are tagged on the sentence that asked
for them: `` `#43` `` merged, `` `#22 dropped` `` closed, `` `#61 open` `` open.

**The file's header is two sentences and a byline.** Say what the log is and
that it's one paragraph per day, then start. Resist explaining the conventions
inside the file: a reader works out `#22 dropped` and `*From review:*` on
sight, and a page of preamble is the first thing that makes somebody stop
reading a document meant to be read in five minutes. The rules on this page are
for whoever writes the log, not for whoever reads it.

## Updating (the normal case)

1. `ruby <skill>/extract.rb blocks --repo <repo>` to see the work blocks, then
   `ruby <skill>/extract.rb dump <YYYY-MM-DD> --repo <repo>` for the prompts.
2. `gh pr list --state all --limit 100 --json number,state,title,createdAt,mergedAt`
   for what shipped. **Convert those timestamps to local time**; `gh` returns UTC.
3. Write the paragraph. Append at the bottom.
4. `ruby <skill>/check.rb docs/intent-log.md`.

## Backfilling a repo for the first time

Same loop, one work block at a time, oldest first. Read the whole range's blocks
before writing anything, because threads span days: a decision on Saturday
evening ships on Monday.

**A day is a work block, not a calendar date.** `extract.rb` segments on a
five-hour idle gap, so a session running to 01:00 stays with the day it started.
Label the entry with the date the block began.

**Attribute PRs by evidence, not adjacency.** Match a PR's opened-at time to the
prompt window before it in the same block. A PR with no matching prompt is
*unexplained*: look at it before writing it off as review noise, because the ask
may sit in a worktree session or a parallel one.

## Traps

These each produced a wrong log before the scripts existed:

- **Transcript timestamps are UTC.** Bucketing by the raw date moves anything
  before 07:00 local onto the wrong day, and go-live lands a day late.
- **Worktree sessions live in sibling project dirs.** `~/.claude/projects/`
  holds a separate directory per worktree; `extract.rb` globs all of them.
  Missing those makes the author's own asks look like agent-initiated work.
- **Injected content arrives as a user turn.** Skill bodies, image
  placeholders and caveats all land as `type: "user"`, and reading them as
  prompts puts a page of skill documentation in the log. They carry
  `isMeta: true`; filter on that rather than on a list of prefixes.
- **Parallel sessions interleave.** One day may hold three sessions on different
  branches. They merge into one paragraph; `extract.rb` marks blocks that span
  more than one source with `[+worktree]`.
- **The author's memory of dates is a hypothesis.** Check it against the
  transcript before rewriting an entry.

## Verifying

`check.rb` asserts every PR appears exactly once with the right state marker,
entries run oldest first, and no day runs long. Run it after every write; it
catches dropped PRs that reading cannot.

## Capturing as you go

Reconstruction is lossy and slow. `intent-stage.rb` is a `SessionEnd` hook that
drops each session's prompts into `.intent/staging/<date>.jsonl` (gitignore it),
so the daily entry is written from fresh material rather than archaeology. It
also sidesteps the timezone and worktree traps, because a session knows its own
transcript and cwd.

Register it per-person in `.claude/settings.local.json`, never in the committed
`.claude/settings.json`, so nobody inherits a hook they did not ask for:

```json
{"hooks": {"SessionEnd": [{"hooks": [
  {"type": "command", "command": "ruby \"$CLAUDE_PROJECT_DIR/.claude/hooks/intent-stage.rb\"", "timeout": 15}
]}]}}
```

Install it only when asked.
