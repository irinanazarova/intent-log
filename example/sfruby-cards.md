# Intent log

What I wanted, day by day, and what shipped. Short on purpose: one paragraph a
day, no matter how many PRs came out of it.

Written by me (Irina) with Claude, reconstructed from my own session prompts.

---

## Wed Jul 15-16

First look. Refresh last year's product for this year's conference, sfruby.com
for context, we're on an 8-bit style now and the characters should be generated
in it.

## Sun Jul 26

The real brief. Relaunch the app for SF Ruby Startup Conference 2026, 8-bit for
the UI and the generated images both. Archive last year's ticket holders
without deleting anything. For people who came last year, reuse the photo they
already gave us so their card is ready before they show up. The near-black
background on the card pages had to go, it looked off against our design
system.

## Wed Jul 29

One app, two conferences. `#1`

## Thu Jul 30

Wrote the character prompt myself: 16-bit chibi sprite off a style reference,
tuned so people look good, because nobody shares a card that flatters them
badly. The cards can vary but the "Join..." wording is a composite overlay for
sure, we paint it, we don't ask a model for it. Rails security bump lands
before anything else. `#2`

## Fri Jul 31

Two threads. On the cards: I didn't want people surrounded by money symbols,
the coins and tickets the model added read as cash, so rubies, hearts and our
martians instead, and the background moved from clouds to any San Francisco
scene. `#3` Returning attendees get a card generated from last year's photo
automatically, before we ever write to them `#4`, and upload screening goes off
for this crowd, they're ticket holders `#5`. Vova reviewed and said the
generation code doesn't belong in `app/models/card`, it belongs in
`app/agents/<event>`, and I had it refactored before building anything else. In
a separate worktree I laid out where this is going: someone buys a ticket on
Luma, gets an invitation from us straight away, makes their card, then keeps
getting tasks and points all the way to the conference, with a gift for whoever
scores highest. Last year I exported and uploaded a CSV by hand every single
day, so I asked for real Luma integration, we're on Luma Plus, 82 people
already hold tickets, plus a profile page where people edit everything except
their email. `#8` Tried getting the card text into a shaped badge instead of a
rectangular bar, Steam capsule art as my reference, never landed it
`#7 dropped`. Brought the review tooling in, the pr-review skill from Solaris
and palkan's layered-rails skills, so reviews here are held to his conventions
and not mine.

## Tue Aug 4 - Wed Aug 5

The logo moves from the middle of the card's strip to the top left corner. Last
year's gallery is preserved on its own public page instead of vanishing, linked
from the footer, and we reuse the sfruby.com footer with the conference links.
Rewrote the gallery headline to sell the conference rather than just be cute.

## Mon Aug 10

Pre-launch. Vova reviewed the Luma work and said enrolling each guest should be
its own small job, so that went in first. Merge everything, keep 2026 switched
off, import the real ticket holders, generate their cards and review them in
admin against a checkerboard so I can see the cutouts before anyone else does
`#9` `#15`. The game economy: coins and hearts, every accrual and spend
recorded, quests for publishing and sharing `#10`. The wallet page was 500ing,
and admin review wanted full-size previews `#12`. The whole thing should feel
like one app: sign-in without passwords, the same nav and footer everywhere,
your own card as your home page, conference links in the footer `#14`. People
invited before go-live keep working links `#16`. Refused the word "veteran" for
returning attendees, we have actual veterans in the community.

*From review: `#11` `#13` `#17`*

## Tue Aug 11

Went live at about eight in the evening. `#6` Before that: the team said the
page can't look the same to you and to a stranger, so the two got split, and
the gallery became one full-size card per row with details in a modal `#19`. A
public API so sfruby.com can show the newest cards live `#18`. What we share is
sfruby.com and not us, so the utm tail comes off `#21`. Name, company, role and
intro go on the card, and the speaker and organizer tags come back off, the
cards looked busy. Sharing to X, LinkedIn and Bluesky, dropping the hashtag in
favour of mentioning the conference account. Sharing buttons and a person's own
social links stop being the same thing, and the whole thing is renamed Pixel
Card `#20`. Rewrote the invitation email myself, it greeted people twice and
explained itself, so it's one line about the first quest now. Then a scare: too
many notifications went out and I thought we'd invited everyone on Luma instead
of only ticket holders. I asked to pause the sync `#22 dropped`, checked the
numbers, found most were last year's, and closed it. Added Plausible `#24`.

*From review: `#23`*

## Wed Aug 12

Quiet day. Asked for imgproxy on the gallery images. Late at night I dropped an
isometric painting of San Francisco into the repo, and that started the pier.

## Thu Aug 13

I want our pixel people standing on that city: first you find yourself and get
10 coins, then you go looking for other people. Use the characters we already
have on production, don't generate new ones. Placement fought me all day,
characters on roofs, on walls, on top of trees, whole lawns empty, so I gave up
on working it out and drew the mask of where feet may go by hand. Separately: a
lot of characters on production have their legs cropped, and I want a pipeline
that draws the missing legs back without touching the face or anything already
painted.

## Fri Aug 14

The pier ships. `#26` Changed my mind about placement: not centre-outwards,
everyone gets a random free spot, so you actually have to search for your
friends. I want to edit the mask myself and re-run. Sponsor banners stand on
rooftops, sized by tier, Pickaxe biggest, never overlapping each other or
people. 450 cloned attendees, so I can see a full pier before the real one
fills. The city should feel alive, so martians in different outfits, a phoenix,
rubies, and a blimp flying over, and I prepared the artwork myself so placement
is ours and not a model's. Hover bubbles: sponsors say something their
marketing team would like, animals say something funny. The leg repair ships as
something I approve in admin rather than something that just happens `#25`,
with free recuts for last year's cutouts `#27`. Asked what the pier costs to
load, which is how images ended up behind imgproxy `#29`. Zoomed the map 2.5x
so the city is something you scroll into and discover `#30`, and gave it a
short address to send people to `#31`. A request from the team: when I change
my name on my profile it should change on the cards I already have, and that's
just repainting, no model involved `#32`. Wanted a "send hi" button on the card
modal that opens a Slack DM with that person, decided it's a whole feature and
postponed it.

*From review: `#28` `#36`*

*Could use a hand: that Slack DM deep link. Still want it, still not built.*

## Sat Aug 15

I don't want two fields on a person that both mean their name, so `name` and
`full_name` merge into one `#34`. The blimp is full size and flies over
everything, a small one doesn't read as real `#33`. The pier gets laid out like
Google Maps, full screen with the panels collapsed on top of it `#35`. Asked
what our links look like when pasted in Slack, which turned into og tags on the
pier `#37` and on the cards `#40`. On mobile there's no hover, so tapping a
sponsor or an animal shows the bubble first and opens the card on the second
tap `#38`, modals that overflow get fixed `#39` `#41`, and the city can be
dragged `#42`. In the evening, the big one: people can move their characters.
I'd prepared three masks for it, where you can walk, where you walk hidden
behind buildings and need an x-ray view to be seen, and a few swim routes to
the ferries, with positions streamed live over AnyCable whispers for up to 450
people. Turned down the easy version, an arrow pointing you at your target, I
wanted the hard one. People and creatures greet you automatically when you come
near, and ghost paths show only while you're walking. `#43` A player told us
the game wants music, so I asked what we can use legally and free and decided:
action sounds from a library, each animal makes its own animal's sound, quests
chime, no background music yet.

## Sun Aug 16

Walking on a phone: you press on your character and swipe the direction you
want them to go, lead and speed 300, dropped to 60 on phones `#46` `#47`, and
your own greeting bubble goes quiet while you're the one walking. Quests become
one list shown in both places, newest on top `#44`, and the quest-complete
modal gets tidied, the +1 sat too far from its heart and the button's rounded
corners broke our design system `#45`. Postponed AnyCable streams history. The
area you can grab to walk is too small on a tablet, so make it a full circle
1.5x the character's height. And I want a quest board in admin, every
participant who accepted with their quests and their balances, so I can see how
the game is actually going.

## Mon Aug 17

The quest board ships `#49`. Our invitation emails were still in last year's
plain style when we'd already built the pixel design, so they got dressed
properly `#50`. Tweaked the logo myself because SAN FRANCISCO in white
disappeared on light backgrounds, which meant refreshing the map and both
walking masks around it and re-running the spots, the ground had changed `#48`.
sfruby.com needed company and job title from our API `#53`. Then sounds: they
fire on hover, the sea lions and whale get a water splash, the parrots need
their true sound, the pelicans had something that isn't a pelican, the human
"hey" was annoying so I asked for a neutral activation sound instead, and we
credit Sonic Pi because it's a Ruby tool and that's good for us `#52`. The
ocean I could not get right at any volume `#55`, so I pulled it out entirely
`#56`. And chat, which I thought was the only gameplay feature still missing:
you walk up to somebody, click them, a "say" button, 140 characters, emoji
allowed, and one simple inbox per person showing who said what in order, both
sides of it, over AnyCable `#54`.

*From review: `#51`*

## Tue Aug 18

Still no ambient San Francisco background sound, so a rare foghorn instead,
about once a minute and a bit random `#57`. A leaderboard ranked by coins,
tucked into the pier footer `#58`. The sound button needed two presses before
you heard anything, so it says what is true now `#59`. Every heart and coin
emoji becomes our 8-bit sprites, everywhere `#60`. Came back to the chat and
asked how private it is: we should never see these in admin or anywhere else,
so they're encrypted and there's no organizer screen. Not anonymous though: we
trust attendees and every line carries a name. Positions on production drift
when they're whispered `#61 open`, and dragging my own character on mobile
still scrolls the map instead.

*Could use a hand: an ambient background sound for the pier. I've tried twice
and nothing feels right.*
