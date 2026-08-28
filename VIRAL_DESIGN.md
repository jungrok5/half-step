# HALF STEP — Viral / Share Design

## Goal

A high-score run should produce footage or a screenshot that makes viewers ask:

- "What score is that?"
- "Why does their sky look different?"
- "What happens after that?"
- "Can I reach it?"

## Viral principle

The player's skill unlocks spectacle.

Do not unlock late visuals via payment or menu selection.

A viewer who has only reached score 50 should not casually see the score-750 world in their own game.

## High-score secrecy

Do not reveal every score threshold publicly.

Internal threshold concepts:
30 / 60 / 100 / 150 / 210 / 300 / 400 / 550 / 750 / 1000

Some extreme zones can remain undocumented in-game.

## Share trigger

On death:
- visible Share button
- native OS share sheet
- no forced share

## Share payload

Text example:

HALF STEP 437
Reached VOID CURRENT.
Can you beat this?

For high scores:
HALF STEP 437
Reached VOID CURRENT.
The sky changes after 300.
Can you beat this?

Do not reveal future thresholds.

## Share image/card

Generate a vertical image suitable for:
- messaging
- Instagram stories
- TikTok repost/content
- Discord
- social feed posts

Include:
- HALF STEP
- giant score
- reached zone
- actual zone colors
- falling character
- small challenge phrase

Potential phrases:
- CAN YOU REACH THIS SKY?
- YOU SHOULD NOT BE HERE
- THE SKY IS GONE
- HOW FAR CAN YOU GO?

Use milestone-specific phrase only if the player actually reached it.

## Better future version

Instead of a generic card, render/capture the actual death frame:
- current sky
- current cloud/star state
- falling character
- score overlay

Then composite title/challenge typography.

This makes each player's share more authentic.

## Social footage

The game should naturally look more extreme as score rises:
- speed
- cloud motion
- wind
- color
- rare sky phenomena

This means a screen recording of a skilled run is itself marketing content.

## Acquisition card (added 2026-08-28)

A second card, shown when a new cat opens. Full spec in `PROGRESSION.md`.

Contents:
- HALF STEP
- the cat, large, on the sky it came from
- its name and the condition that opened it
- three silhouettes of slots the player has NOT opened — curiosity, without
  revealing what they are
- the challenge line

Text example:

HALF STEP · Got AURORA
210 in one run · AURORA EDGE
How far can you go?

The acquisition card must never block retry. The result card gains one line and a
thumbnail; only tapping that line opens the card. Not tapping it retries exactly
as before.

## Witness link

The share URL carries the cat id: `?seen=aurora`.

Opening the link marks that cat **witnessed** in the receiver's codex — art, name
and unlock condition are revealed, but it stays locked. No backend, no account:
one query parameter, read at startup.

This is the part that makes sharing a loop rather than a boast. Sharing used to
give the receiver nothing. And NAMELESS opens only after witnessing five
different cats, so the codex cannot be completed alone.

## Per-cat records

Each cat remembers the best score reached while equipped, printed on the run card
("HALF-STEP · best 412"). 24 cats become 24 personal records, so the same cat
keeps producing new content instead of being a one-time collectible.

## Leaderboard

Not required for v1.

A global percentile such as "top 0.1%" could strengthen sharing later, but only if backed by real server data.
Never fake a percentile.
