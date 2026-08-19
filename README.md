# Intent log

I ship a lot of code I did not write. Thirty pull requests in three weeks on one
project, and my colleague could not stay on top of it. Neither could I, if I am
honest: I could not have reviewed that much code either.

The code is in git. What is not in git is what I *wanted*, and that turns out to
be the part a teammate needs to help me.

So: one short paragraph per day of work, in order, tagged with the PRs it
produced. Under 2,000 words for three weeks. A colleague reads it in five
minutes and knows where to jump in.

```markdown
## Fri Aug 14

The pier ships. `#26` Changed my mind about placement: not centre-outwards,
everyone gets a random free spot, so you actually have to search for your
friends. [...] Wanted a "send hi" button that opens a Slack DM with that person,
decided it's a whole feature and postponed it.

*From review: `#28` `#36`*

*Could use a hand: that Slack DM deep link. Still want it, still not built.*
```

[`example/sfruby-cards.md`](example/sfruby-cards.md) is a real one: three weeks
of building a conference game, 61 PRs, reconstructed from my own prompts.

## What goes in it

Intent and outcome. Nothing else.

A sentence earns its place if it traces to something I said, decided, refused,
changed my mind about, or gave up on. If it would still be true after somebody
rewrites the implementation, it belongs. Otherwise it is PR-body material.

Back and forth is the default condition of this work, so narrating it says
nothing. It earns a line in three cases: I gave up, I reversed myself, or I
parked something. That is why the log carries "the ocean I could not get right
at any volume, so I pulled it out entirely" and carries none of the six rounds
of volume tuning that led there.

Work the agent started and I never asked for is not intent. It goes in the day's
`*From review:*` tail, so the PR is still accounted for without pretending it
was my idea.

## Install

```sh
git clone https://github.com/irinanazarova/intent-log ~/.claude/skills/intent-log
```

Then `/intent-log` in Claude Code, in any repo. It writes `docs/intent-log.md`.

## The two scripts

`SKILL.md` holds the rules for writing an entry. The scripts hold the parts that
should never be a judgment call:

```sh
ruby extract.rb blocks --repo ~/code/myapp        # what the work blocks were
ruby extract.rb dump 2026-08-14 --repo ~/code/myapp
ruby check.rb docs/intent-log.md                  # invariants
ruby check.rb docs/intent-log.md --fix            # rewrap
```

`extract.rb` reads only your own prompts, never the assistant's turns. Every
rule in it exists because reconstructing that example log without it produced a
wrong answer:

- **Transcript timestamps are UTC.** Bucketing on the raw date moves anything
  before ~07:00 local onto the wrong day. Go-live landed a day late, and a
  decision made on Sunday evening showed up as Monday's.
- **Worktree sessions live in sibling directories.** `~/.claude/projects/` holds
  a separate directory per worktree. Missing six of them made my own asks look
  like work the agent started on its own.
- **A day is a work block, not a calendar date.** Sessions run past midnight, so
  it segments on a five-hour idle gap and labels the block by the day it began.

`check.rb` asserts every PR appears exactly once with the right state marker,
entries run oldest first, no day runs long, and lines stay wrapped. It catches
dropped PRs that reading does not.

## Why this might be worth something

The hypothesis is not that a log replaces review. It is that a colleague who
reads three weeks of intent in five minutes knows where to spend an hour, and
that is a much better question than "can you review 30 PRs".

Unverified so far. That is the point of the example.
