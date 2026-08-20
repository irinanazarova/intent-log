---
name: intent-log
description: Keep docs/intent-log.md, one short list per day of what a person worked on, each line tagged with the PR it produced, so a teammate can see where the work got to without reading every pull request. Use when asked to write, update, backfill, or reconstruct an intent log, or to catch a colleague up on a burst of agent-assisted work.
---

# Intent log

A team ships faster than it can review. The code is in git; what the person
*wanted* is not, and that is what a returning teammate actually needs. This
skill keeps `docs/intent-log.md`: one short list per day of work, in
chronological order, tagged with PR numbers.

## Format

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

**One list of what the person worked on. The PR tag says where it got to**, so
nothing needs a second list to report an outcome:

| tag | means |
| --- | --- |
| `` `#26` `` | merged, it's done |
| `` `#61 open` `` | still in progress |
| `` `#7 dropped` `` | the PR was closed |
| no tag | nothing shipped for it |

Read the state off `gh pr list`, never off memory, and tag each PR **exactly
once**, on the bullet naming the work it came out of. That bullet is often on an
earlier day than the PR: the ask goes where it was made, and the tag follows the
ask. Newest entries at the **bottom**.

A merged PR that abandoned the thing is the one case the tag gets wrong on its
own, so the bullet says it, in words: *gave up on the ocean at any volume*,
tagged with the PRs that took it out.

## What goes in a bullet

**One ask, one line, under 20 words.** If it needs a second clause to justify
itself, cut the justification.

**No before-state, no reasoning, no flourish.** The reader knows what the app
looked like last week and can read the diff for how it changed. Vova's example:

> Our invitation emails were still in last year's plain style when we'd already
> built the pixel design, so they got dressed properly

is one bullet: `invitation emails in the pixel design`.

**Name the concrete thing.** "Two fields that both mean the name" is unreadable
a week later; "`name` and `full_name`" is not. A vague noun is the single most
common way one of these entries goes stale.

**Say where an idea came from** when it wasn't the author's: a reviewer, a
player, the team. That is the collaboration signal a teammate reads the log for.

**Say a thing once.** Not in a bullet and again in the help line.

Plain and laid back, first person, the way the person actually talks. No
"leveraged", no "implemented", no "successfully". Prefer the verbs of intent:
asked, wanted, refused, decided, changed my mind.

## What stays out

Back and forth is the default condition of the work, so narrating it carries no
information. Cut reviews run, tests written, iterations tried, servers
restarted, things checked on a phone. A reversal is an ordinary Wanted bullet:
`changed my mind on placement: everyone gets a random spot`.

Three things earn a tail line instead, because they are what a colleague can act
on:

- `*Dropped: ...*` — gave up, nothing landed
- `*Postponed: ...*` — parked it deliberately, still wanted
- `*From review: `#28`*` — work the agent started and the human never asked for,
  so the PR is still accounted for
- `*Could use a hand: ...*` — genuinely stuck or wanted. This is the point of
  the whole file: it turns a diary into a list a colleague can act on.

**A day stays under 180 words**, even if it produced 18 PRs.

## The file header is two sentences and a byline

Say what the log is and that it is one list a day, then start. Resist
explaining the conventions inside the file: a reader works out `#22 dropped` and
`*From review:*` on sight, and a page of preamble is the first thing that makes
somebody stop reading a document meant to be read in five minutes. The rules on
this page are for whoever writes the log, not for whoever reads it.

## Updating (the normal case)

1. `ruby <skill>/extract.rb blocks --repo <repo>` to see the work blocks, then
   `ruby <skill>/extract.rb dump <YYYY-MM-DD> --repo <repo>` for the prompts.
2. `gh pr list --state all --limit 100 --json number,state,title,createdAt,mergedAt`
   for what shipped and what state it is in. **Convert those timestamps to local time**; `gh` returns UTC.
3. Write the list. Append at the bottom.
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
  branches. They merge into one entry; `extract.rb` marks blocks that span
  more than one source with `[+worktree]`.
- **The author's memory of dates is a hypothesis.** Check it against the
  transcript before rewriting an entry.

## Verifying

`check.rb` asserts every PR appears exactly once with the right state marker,
entries run oldest first, every day is a list, no bullet runs to a paragraph,
and no day runs long. Run it after every write; it
catches dropped PRs that reading cannot. `--fix` rewraps the file, keeping
bullets hanging-indented.

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
