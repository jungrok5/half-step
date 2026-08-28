# HALF STEP — Game Design

## One-line pitch

A one-thumb endless rhythm/reaction game: the player toggles between two lanes and must be on the safe sky platform at every beat while the world accelerates.

## Why it works

The skill is not learning many rules. The skill is:
- reading the next safe side
- internalizing the current cadence
- reacting without breaking rhythm
- maintaining control as speed becomes absurd

The intended player feeling is:
> "I understand this immediately."
> "Oh, I'm getting used to the rhythm."
> "Wait, this is getting fast."
> "I almost had it."
> "One more run."

## Screen

Portrait.

Two platform lanes:
- LEFT
- RIGHT

Player remains near lower-middle screen.
World streams toward the player / downward to communicate forward travel.

## Core loop

1. Upcoming platform pattern approaches.
2. Player taps whenever they want to toggle lane.
3. Automatic landing event occurs on cadence.
4. Correct lane → success sound + impact + score.
5. Incorrect lane → fall into depth.
6. Retry instantly.

## Score

1 successful landing = +1 point.

No stage system is required.

Best score is persisted locally initially.

## Same-lane rows

Patterns can contain repeated safe lanes:
- L L R R
- R R R L
etc.

The player does not need to tap every beat.

This is intentional and creates variation without changing the rhythm itself.

## Difficulty

Primary difficulty variable: cadence interval.

Difficulty must be monotonic within a run.

No random slowdowns.

Pattern complexity may increase modestly, but speed remains the main challenge.

## Feedback

Successful landing:
- one melodic note
- slight character squash
- slight platform compression
- expanding/fading impact ghost
- tiny pixel particles
- optional short vibration

Failure:
- descending/fading fall sound
- character shrinks from failed position into depth
- result card appears shortly afterward

## Visual progression

The player's score determines sky atmosphere.

Early run:
- bright clean sky
- gentle clouds
- little/no wind

Mid run:
- sunset / night / stars
- faster clouds
- stronger streaks

Extreme run:
- visually surprising hidden skies
- aurora / void / chromatic storm / white horizon / beyond
- increasingly strange but readable world

Gameplay rule does NOT change just because the world changes.

## Retention philosophy

Do not solve repetition by adding currencies, missions, upgrade trees, or level complexity during prototype validation.

Superseded in one place, 2026-08-28: the cat codex adds an experience level and a
collection. It was approved explicitly, after the prototype port was
feature-complete, and it adds no currency, no upgrade tree and no gameplay
complexity — cats are purely cosmetic. See `PROGRESSION.md`. The rule stands for
everything else.

First validate:
- replay urge
- speed curve
- score bragging
- visual curiosity
- share behavior

## Monetization

Ads only for first release.

Potential:
- interstitial every N deaths
- rewarded optional continuation once per run

Do not interrupt every retry.

## Initial release scope

- endless game
- local best score
- sound
- vibration
- high-score sky zones
- result screen
- share
- cat codex (24 cats, experience levels, acquisition card, witness link)
- Android
- ads

No:
- account
- server
- leaderboard at launch unless trivial
- inventory
- stage map
- multiplayer
