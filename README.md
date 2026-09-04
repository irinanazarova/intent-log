# Intent log

A daily log of what we worked on, and what shipped or got dropped. One short
list per day, tagged with the PRs it produced.

**Why:** so teammates can stay on track and step in where they're needed,
without reading every pull request.

**And, in theory:** context for a future refactor. Months later the log says
what was intentional and what was just how it came out.

## How it works

One list a day, in order. Each line is something we worked on, and the PR tag
says where it got to. A real day, from the example below:

```markdown
## Fri Aug 14

- the pier: find-yourself map, quests, sponsors, wildlife `#26`
- changed my mind on placement: a random free spot each, so you search for your
  friends
- the mask editable by me and re-runnable
- sponsor banners on rooftops, sized by tier, Pickaxe biggest, never
  overlapping anyone
- 450 cloned attendees, so I see a full pier before the real one fills
- the city alive: martians, a phoenix, rubies, a blimp, on artwork I prepared
  myself
- hover bubbles: sponsors say what their marketing would like, animals
  something funny
- leg repair I approve in admin rather than something that just happens `#25`
  **why:** characters generated on production came back with their legs cut off
  **I decided:** I approve each repair rather than have one happen to a card I
  never looked at
- free recuts for last year's cutouts `#27`
- what the pier costs to load, which is how images went behind imgproxy `#29`
- the map zoomed 2.5x, a city you scroll into `#30`, and a short address `#31`
- the team: renaming myself repaints the cards I already have `#32`
- a "send hi" button on a card that opens a Slack DM

*From review: `#28`*
*Could use a hand: the Slack DM deep link. I decided it's a whole feature and
postponed it, still want it.*
```

- `` `#26` `` — merged, it's done
- `` `#61 open` `` — still in progress
- `` `#7 dropped` `` — the PR was closed
- no tag — nothing shipped for it

The last line of that day has no tag, so a month later the Slack DM button is
still visibly missing, and `*Could use a hand:*` says so out loud.

## The reasoning under a bullet

A bullet is the index and stays one line. Two optional sub-lines carry the
thinking, indented under the bullet they belong to:

- `**why:**` — the state of the world that made the ask. The bug seen, the
  thing that read wrong, the question asked before the work started.
- `**I decided:**` — the call made inside the work, above all one that closed
  off an alternative: a number picked, a check dropped, a shape turned down.

This is the part a reviewer cannot get from the diff. Five libraries, three
models and a refactor into jobs all read the same in a pull request, so the log
records human decisions only: what somebody asked for is here, and anything in
the diff that is not here was the model's idea.

Both are read off the session prompts rather than inferred from the diff. A
decision you cannot point at a prompt for is one the model made, and it stays
out; a bullet with nothing to say under it stays one line.

[`skills/intent-log/example/sfruby-cards.md`](skills/intent-log/example/sfruby-cards.md)
is the whole thing: four weeks of building a conference game, 75 PRs, 1,444
words.

## Two people, or ten

Prompts never leave the machine they were typed on, so nobody can write anybody
else's entry. Everything below follows from that.

**Each person owns `docs/intent/<github-login>.md`** and appends only to their
own. Two people appending to the bottom of one shared file conflict on every
commit that shares a day; separate files cannot. The name is the GitHub login so
that `gh pr list` ties a PR to whoever owed the entry for it.

**`compose.rb` merges them into `docs/intent-log.md`**, which stays the one file
you read and link, and which is generated rather than edited.

```sh
ruby compose.rb                 # docs/intent/*.md -> docs/intent-log.md
ruby compose.rb --check         # exit 1 if the log is behind its sources
```

**A day written by one person gets no byline**, so a solo log composes to
exactly the file it already had: one author is the degenerate case of ten, not a
second format. A day with two or more gets a heading each, and the length limit
applies to one person's day rather than the whole team's.

```markdown
## Thu Sep 3

### Irina

- stop policing how far a step came `#119`

### Vova

- the queue database was throwing busy timeouts all day `#87`
```

**The `*Could use a hand:*` lines are lifted to the top of the composed log**,
each with a name and a date. At ten people a day is ten lists, and the one line
somebody can act on is the first thing to get buried.

**`check.rb` names a teammate who shipped and logged nothing.** That is the
failure a team log has and a solo one cannot: every entry that is there is
correct, and a person is missing.

## Install

```sh
git clone https://github.com/irinanazarova/intent-log
cp -r intent-log/skills/intent-log ~/.claude/skills/
```

Then `/intent-log` in any repo, in Claude Code. It writes `docs/intent-log.md`.

## What the scripts do

`SKILL.md` holds the rules for writing an entry. The scripts do the parts that
shouldn't be a judgment call. The skill runs them itself; to run them by hand,
do it from `~/.claude/skills/intent-log`.

**`extract.rb` — pulls the day's prompts out of the transcripts**, grouped into
work blocks, so an entry is written from what was actually asked for rather than
from memory. It reads only your own turns, never the assistant's.

```sh
ruby extract.rb blocks --repo ~/code/myapp           # what the work blocks were
ruby extract.rb dump 2026-08-14 --repo ~/code/myapp  # that day's prompts
```

Three things it handles, each of which got the log wrong when done by hand:
transcript timestamps are UTC, so anything before ~07:00 local lands on the
wrong day; every worktree gets its own directory under `~/.claude/projects/`,
and missing them makes your own asks look like the agent's; and a day is a work
block rather than a date, so a session running past midnight stays with the day
it started.

**`check.rb` — asserts what reading misses.** Every PR appears exactly once with
the right state marker, entries run oldest first, each day is a list rather than
prose, no bullet runs past 20 words, no day runs long, and a heading's weekday
is the real one.

Headings carry no year, so the first one names its own (`## Wed Jul 15-16,
2026`) and the rest carry it forward until another names one. Without that a log
is dated to whatever year it's read in, and every weekday in it goes wrong the
January after it was written; `check.rb` asks for the anchor and `compose.rb`
refuses a day that goes backwards without one.

```sh
ruby check.rb ~/code/myapp/docs/intent-log.md --repo owner/name
ruby check.rb ~/code/myapp/docs/intent-log.md --repo owner/name --fix  # rewrap
```

**`compose.rb` — merges the per-person files into the log you read.** Skip it
in a repo where one person writes everything and there is no `docs/intent/`.

**`intent-stage.rb` — saves each session's prompts as you go**, into
`.intent/staging/<date>.jsonl`, so the entry is written from fresh material
instead of archaeology weeks later. It's a `SessionEnd` hook.

**`intent-nag.rb` — says when the log has fallen behind**, because staging runs
itself and the write-up doesn't. The log this skill was built against lapsed for
16 days and 62 PRs while the hook beside it staged every one of those days
perfectly; nothing noticed because nothing was looking. It's a `Stop` hook that
counts the staged days the log hasn't accounted for and asks for them at three
or more (`INTENT_NAG_DAYS`), at most once a day, reading your own file so a
teammate logging today doesn't answer for you.

```sh
cp ~/.claude/skills/intent-log/intent-{stage,nag}.rb ~/code/myapp/.claude/hooks/
```

```json
{"hooks": {
  "SessionEnd": [{"hooks": [
    {"type": "command", "command": "ruby \"$CLAUDE_PROJECT_DIR/.claude/hooks/intent-stage.rb\"", "timeout": 15}
  ]}],
  "Stop": [{"hooks": [
    {"type": "command", "command": "ruby \"$CLAUDE_PROJECT_DIR/.claude/hooks/intent-nag.rb\"", "timeout": 15}
  ]}]
}}
```

Put it in `.claude/settings.local.json` rather than the committed
`settings.json`, so nobody inherits a hook they didn't ask for, and add
`.intent/` to `.gitignore`.
