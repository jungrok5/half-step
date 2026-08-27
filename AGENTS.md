# HALF STEP — AGENTS.md

This repository is developed with AI agents (ChatGPT Work / Codex-style agents) and human mobile-device testing.

Read this file before making ANY gameplay change.

## 1. Product goal

HALF STEP is a portrait, one-thumb, endless score game built in Godot + GDScript.

The game should feel:
- instantly understandable
- rhythmically satisfying
- increasingly intense
- visually shareable at high scores
- easy to restart
- hard to master
- suitable for a tiny ad-supported mobile release

The core game must remain small. Do not add systems merely to create content.

## 2. CORE RULES — DO NOT CHANGE WITHOUT EXPLICIT APPROVAL

### Input
- One screen tap toggles player lane immediately: LEFT ↔ RIGHT.
- Input must NEVER be discarded.
- Do not add an input lock that causes taps to be ignored.
- Do not queue future lane decisions.
- Do not require swipe, hold, double tap, or multi-button input.

### Cadence
- The player advances automatically on a fixed current cadence.
- During a run the cadence may ONLY get faster.
- NEVER suddenly slow the cadence.
- NEVER introduce irregular beat multipliers or arbitrary tempo variation.
- The pleasure comes from the player becoming accustomed to the rhythm and surviving as it accelerates.

### Landing
- Each upcoming row has one safe platform.
- At the landing instant, player lane must match the safe platform lane.
- Same-lane consecutive successes are valid and intentional.
- Changing lane is not inherently more valuable than staying in the same lane.

### Death
- If the platform is missed, the player falls from that exact screen position into depth.
- Do NOT move the player toward the screen center.
- Do NOT animate the player falling off the bottom edge of the phone.
- The player should shrink and fade at nearly the same X/Y position, communicating falling downward into the distant sky.

### Restart
- Restart must feel immediate.
- No long transitions before retry.

## 3. Explicitly rejected designs

Do NOT reintroduce these unless the user explicitly asks:

- Variable rhythm that slows down or changes beat length.
  - Rejected because it breaks learned rhythm and feels unpleasant.
- Tap = immediate full physical jump toward the next platform.
  - Rejected because timing + direction became confusing and too difficult.
- Queued next-lane indicator / input buffering as visible gameplay.
  - Rejected because it gave too much planning time and made the game too easy.
- Star risk/reward platform mechanic.
  - Rejected because it did not feel compelling.
- PERFECT timing system.
  - Removed. Do not restore it.
- Input lock during hop/landing animation.
  - Rejected because taps felt unresponsive.
- Gameplay systems added only to fight boredom.
  - Prefer stronger feel, visuals, speed, sound, and high-score spectacle instead.

## 4. Current successful feel

The strongest prototype feeling came from the early DAY 1 version:
- immediate lane switching
- fixed cadence
- reaction pressure
- gradual monotonic acceleration
- instant retry

Later improvements that should remain:
- every successful landing produces an audio note
- landing impact feedback
- forward-moving cloud background
- stronger wind / speed visuals as score increases
- hidden high-score sky zones
- score sharing
- depth-fall death animation

## 5. Audio rules

### Success melody
- Every successful landing advances the melody by exactly one note.
- LEFT/RIGHT choice does not affect pitch.
- Same-lane consecutive landing still advances by one note.
- Current intended pattern:
  - major scale: Do Re Mi Fa Sol La Ti Do
  - climb through 3 octaves = 24 success notes
  - after 24 notes, restart from the low register
- Keep the audio family coherent.
- Do not insert random reward chords or unrelated sound effects between landing notes.

### Death
- Falling sound should descend in pitch and volume.
- It should communicate distance: "falling away into depth."

## 6. Landing feel

When a platform is successfully landed on:
- original platform remains in place
- platform itself may compress very slightly
- spawn a temporary impact ghost at the same platform
- impact ghost enlarges slightly and fades
- a few tiny pixel particles may burst outward
- keep the effect short and readable

Goal: stronger impact without disturbing platform position recognition.

## 7. Speed / difficulty

Difficulty is primarily speed.

Do not make platform logic dramatically more complex at high scores.

Prototype acceleration intent:
- ~0 score: 560 ms cadence
- ~100: ~390 ms
- ~200: ~270 ms
- ~300: ~190 ms
- ~400: ~130 ms
- extreme score regions may become far faster

Important:
- We expect extreme outlier players.
- Do not assume 300 or 400 is unreachable.
- Design content and progression for 500 / 750 / 1000+.
- Technical minimum cadence should be far beyond ordinary human play, not a visible early ceiling.

Balance values are subject to playtesting; the monotonic principle is not.

## 8. High-score visual progression

High score should become content people want to record/share.

Current conceptual zones:

| Score | Zone |
|---:|---|
| 0 | BLUE SKY |
| 30 | GOLDEN WIND |
| 60 | SUNSET RUN |
| 100 | NIGHT BREAK |
| 150 | STAR RUSH |
| 210 | AURORA EDGE |
| 300 | RED STRATOS |
| 400 | VOID CURRENT |
| 550 | CHROMA STORM |
| 750 | WHITE HORIZON |
| 1000 | BEYOND |

These thresholds may be balanced, but the principle must stay:
- later zones should not merely be recolors
- environment becomes increasingly extraordinary
- players who cannot reach later scores should not see everything
- high-score clips should create "what happens after that?" curiosity

Secret milestone text concepts:
- 300: YOU SHOULD NOT BE HERE
- 400: THE SKY IS GONE
- 550: KEEP GOING
- 750: NO ONE WAS SUPPOSED TO SEE THIS
- 1000: BEYOND

Use sparingly. The game should not become text-heavy.

## 9. Forward-motion visual rule

The game is NOT climbing upward through the sky.

Intended sensation:
- the character is traveling FORWARD rapidly above/in the clouds
- similar spatial motion to a vertical-scrolling airplane game
- clouds move from upper screen toward lower screen
- near elements move faster than distant elements
- wind streaks intensify as speed rises

Do not return to an "ascending vertically" visual interpretation.

## 10. Art direction

Target final art:
- flat vector mobile game, drawn from primitives at runtime — Flappy Bird's level
  of simplicity and polish
- readable silhouettes
- clean small palette
- warm/cute character against dramatic sky
- smooth edges, generous rounding, no outlines
- platforms remain instantly readable at speed
- cloud forms should have depth/parallax but stay visually simple

The earlier pixel-art direction was replaced on request; see `ART_DIRECTION.md`.
Prototype CSS art is only a reference for motion/feel, not final quality.

## 11. Viral / sharing loop

On death:
- show score
- show best score
- show reached sky zone
- offer immediate retry
- offer OS-native share

Preferred share message:
HALF STEP {score} · Reached {zone}. Can you beat this?

Preferred shared image:
- HALF STEP logo/title
- giant score
- reached zone
- falling character
- visual appearance of the actual reached sky
- curiosity line such as CAN YOU REACH THIS SKY?
- do not reveal future zones

Web prototype used navigator.share(). Native Godot implementation should use appropriate Android/iOS native sharing integration.

## 12. Ads

Target monetization:
- ads only
- do not destroy retry flow
- sparse interstitials after multiple runs rather than every death
- optional rewarded ad may be considered for a carefully designed one-time continuation
- do not make revive mandatory to achieve high scores

Exact ad cadence is not finalized.

## 13. Godot implementation principles

Target:
- Godot 4.x
- GDScript
- portrait mobile
- Android first

Architecture should remain small and testable.

Prefer:
- pure gameplay state separated from presentation
- deterministic difficulty calculation
- zone configuration in data/constants
- testable lane / landing / score logic
- no unnecessary service architecture

## 14. Agent completion checklist

After gameplay changes:
1. Run Godot project import/validation headlessly.
2. Run deterministic gameplay tests.
3. Run difficulty curve tests.
4. Render visual-test screenshots if environment permits.
5. Verify no input lock was introduced.
6. Verify cadence never decreases during a run.
7. Verify same-lane consecutive success still works.
8. Verify death stays at failed X location and shrinks into depth.
9. If Android export tooling exists, produce/test an Android debug build.
10. Summarize changes and any unverified visual/device assumptions.

Never claim a device behavior was tested unless it actually was.
