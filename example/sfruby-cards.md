# Intent log

What I worked on, day by day, tagged with the PRs it produced. One short list a
day, no matter how many came out of it.

Written by me (Irina) with Claude, from my own session prompts.

---

## Wed Jul 15-16

- last year's app refreshed for this year's conference, in an 8-bit style
- the characters generated in that style too

## Sun Jul 26

- relaunch for SF Ruby Startup Conference 2026, 8-bit UI and 8-bit images
- last year's ticket holders archived, nothing deleted
- returning attendees' cards made from the photo they already gave us
- the near-black background off the card pages, it fights our design system

## Wed Jul 29

- one app, two conferences `#1`

## Thu Jul 30

- the character prompt is mine: 16-bit chibi sprite off a style reference
- people must look good in it, nobody shares a card that flatters them badly
- the "Join..." wording painted by us, never asked of a model
- the Rails security bump before anything else `#2`

## Fri Jul 31

- no money on the cards: rubies, hearts and martians, not coins and tickets
  `#3`
- backgrounds any San Francisco scene instead of clouds
- returning attendees' cards generated before we ever write to them `#4`
- upload screening off, this crowd already holds tickets `#5`
- Vova: generation code out of `app/models/card` and into `app/agents/<event>`,
  first
- the card text in a shaped badge, Steam capsule art as my reference
  `#7 dropped`
- real Luma integration, last year I uploaded a CSV by hand every single day
  `#8`
- a profile page where people edit everything except their email
- the arc: Luma ticket, invitation, card, then tasks and points until the
  conference
- palkan's layered-rails skills and Solaris' pr-review skill, so reviews follow
  his conventions

## Tue Aug 4 - Wed Aug 5

- the logo from the middle of the card's strip to the top left corner
- last year's gallery kept on its own public page, linked from the footer
- the sfruby.com footer with the conference links, reused here
- a gallery headline that sells the conference rather than being cute

## Mon Aug 10

- merge everything, keep 2026 switched off, import the real ticket holders
- their cards reviewed in admin against a checkerboard, so I see the cutouts
  first `#9`
- coins and hearts, every accrual and spend recorded, quests for publishing and
  sharing `#10`
- the wallet page fixed, it was 500ing, and full-size previews in admin review
  `#12`
- source photo previews on the card page `#15`
- one app: passwordless sign-in, the same nav and footer everywhere, my card as
  home `#14`
- links sent before go-live keep working `#16`
- Vova: enrolling each guest is its own small job, in first
- the word "veteran" off returning attendees, we have actual veterans in the
  community

*From review: `#11` `#13` `#17`*

## Tue Aug 11

- go live: 2026 current, 2025 archived `#6`
- the team: the page can't look the same to me and to a stranger, so split them
  `#19`
- the gallery one full-size card per row, details in a modal
- a public API so sfruby.com shows the newest cards live `#18`
- no utm tail, what we share is sfruby.com and not us `#21`
- name, company, role and intro on the card; speaker and organizer tags off,
  too busy
- sharing to X, LinkedIn and Bluesky, mentioning the conference account, no
  hashtag
- share buttons kept apart from a person's own links, and the rename to Pixel
  Card `#20`
- the invitation email rewritten by me: one line about the first quest, it used
  to greet twice
- pausing the Luma sync, I thought we'd invited everyone instead of ticket
  holders `#22 dropped`
- Plausible `#24`

*From review: `#23`*

## Wed Aug 12

- imgproxy on the gallery images
- dropped an isometric painting of San Francisco into the repo, late at night

## Thu Aug 13

- our pixel people standing on that city: find yourself for 10 coins, then find
  others
- the characters already on production, no new ones generated
- gave up solving placement, drew the mask of where feet may go by hand
- a pipeline that draws cropped legs back without touching the face

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
- free recuts for last year's cutouts `#27`
- what the pier costs to load, which is how images went behind imgproxy `#29`
- the map zoomed 2.5x, a city you scroll into `#30`, and a short address `#31`
- the team: renaming myself repaints the cards I already have `#32`
- a "send hi" button on a card that opens a Slack DM

*From review: `#28`*
*Could use a hand: the Slack DM deep link. I decided it's a whole feature and
postponed it, still want it.*

## Sat Aug 15

- one field for a person's name, not `name` and `full_name` both `#34`
- the blimp full size, a small one doesn't read as real `#33`
- the pier laid out like Google Maps, full screen, panels collapsed on top
  `#35`
- what our links look like pasted in Slack, so og tags on the pier `#37` and
  cards `#40`
- no hover on a phone: first tap shows a sponsor's bubble, second opens the
  card `#38`
- modals that overflow, fixed `#39` `#41`
- the city can be dragged `#42`
- people can move their characters; I turned down an arrow pointing at your
  target `#43`
- three masks: where you walk, where you walk hidden and need x-ray, swim
  routes
- positions streamed live over AnyCable whispers
- people and creatures greet you when you come near; ghost paths only while
  walking
- a player says the game wants music: free library sounds, each animal its own

*From review: `#36`*

## Sun Aug 16

- walking on a phone: press your character and swipe the way you want them to
  go `#46`
- lead and speed 300, dropped to 60 on phones; the grab area too small on a
  tablet `#47`
- my own greeting bubble quiet while I'm the one walking
- one quest list shown in both places, newest on top `#44`
- the +1 sat too far from its heart, and the button's corners broke our design
  system `#45`
- a quest board in admin: everyone who accepted, their quests, their balances
  `#49`

*Postponed: AnyCable streams history.*

## Mon Aug 17

- invitation emails in the pixel design `#50`
- the logo fixed, SAN FRANCISCO in white disappears on light backgrounds `#48`
- company and job title in the API for sfruby.com `#53`
- sounds on hover: a splash for the sea lions and the whale, real parrots, a
  real pelican `#52`
- the human "hey" replaced by a neutral activation sound, it was annoying
- Sonic Pi credited, it's a Ruby tool and that's good for us
- gave up on the ocean at any volume `#55` `#56`
- chat, the last gameplay piece missing: walk up, click, say 140 characters
  `#54`
- one inbox per person, both sides of it, in order, over AnyCable
- palkan should like PR 54, we need him to

*From review: `#51`*

## Tue Aug 18

- a coin leaderboard, tucked into the pier footer links `#58`
- every heart and coin emoji replaced by our 8-bit sprites `#60`
- chats encrypted and never in Avo; not anonymous, we trust attendees
- a rare foghorn instead of ambient sound, once a minute or so `#57`
- the sound button says what is true, it takes two presses `#59`
- whispered positions drift on production, find out why `#61`
- dragging my character on a phone scrolls the map `#63`
- the camera keeps the character centred while walking `#66`
- quests on the pier only, newest and open on top; pier at root `#68`
- a quest for talking to five people: send and get a reply `#69`
- an intent log: 30 PRs in a few days, palkan can't follow that `#62`
- what was said lands in the chatbox `#64`, the pier's JS tidied `#65`
- the browser's own state kept through a render `#67`

*Could use a hand: an ambient background sound for the pier. I've tried twice
and nothing feels right.*

## Wed Aug 19

- Svyat got a 422 clicking his card on production, pull the logs `#70`
- the production image built only when something it's made of changed `#71`
- a shared card link that is short and previews as the card, `/?card=<slug>`
  `#72`
- share the game rather than the conference site, it links out to the
  conference anyway
- our admin link to a person is their sign-in token; make it a public profile
- Rosa's page says "talks on RubyEvents" without saying how many
- one canonical address per person, `/e/2026-bits/<slug>`, the pier behind
  their card `#73`
- `/e/2026-bits/pier/<slug>` redirects to it, and social sharing uses it
- logged in as Vova, walked up to Irina and couldn't send: "did not reach the
  Pier" `#74`
- the og tags checked: the inspector flags a long title and a short description
  `#75`
- Vova on this log: fewer words, one list a day, status read off the PR
