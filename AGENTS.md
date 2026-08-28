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
- A tap is a jump, judged where the cat is at the instant it is made: it only
  reaches a bridge that has closed to within half a row spacing, on the lane
  being jumped to. Anything else is a jump into open sky and the run ends.
  (Approved 2026-08-27, overriding the entry in section 3 — see below.)

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
- ~~Tap = immediate full physical jump toward the next platform.~~
  - Originally rejected because timing + direction became confusing and too
    difficult. REINSTATED on explicit request, 2026-08-27: without it the tap
    could be made at any point in the beat and nothing was being timed. The
    confusion it caused the first time came from a row stack that snapped into
    place; the world now scrolls continuously across every beat, so the
    arriving bridge is visible to time the jump against. See
    PROTOTYPE_HISTORY.md, "The lean was a free pass". Do not remove it again
    without the same explicit approval.
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

### Music
- Every track is C major at A=440, has no percussion and no tempo, and stays out
  of 250–1100 Hz. The cadence accelerates continuously inside one run, so
  anything with a beat fights it. See AUDIO_RULES.md and docs/audio/PROMPTS.md.
- A missing audio file must never break the game. Slots fall back to synthesis
  or to silence.

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

The camera hangs above and looks straight DOWN, as in a vertical scrolling
flight game. Every element is drawn from overhead, never in profile.

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
- warm/cute character against dramatic sky — a cat seen from above, crossing
  bridges hung in the sky
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

A second card exists on cat acquisition, and the share URL carries the cat id so
the receiver's codex records it as witnessed. See section 14 and `PROGRESSION.md`.

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

## 14. Progression / cat codex

Approved 2026-08-28. Full spec in `PROGRESSION.md`; the illustrated version is
`docs/progression/sky-cat-codex.html`.

Hard rules:
- Cats are PURELY cosmetic. Never let an equipped cat change judgement, cadence,
  score, hitbox or death.
- Score is not experience. One landing pays `(560 / step_interval)²`, so depth
  always beats repetition. Do NOT simplify this to "score += exp".
- EXP is never deducted. Lineage's experience loss is deliberately not carried
  over; it fights section 2's "restart must feel immediate".
- Level cats stop at Lv 30. Levels above that are a prestige number only — never
  hang content behind them.
- 11 of the 24 cats open on a single run's score or feat, not on level. That
  placement is the design, not an oversight: it is what makes acquisition
  shareable. See PROGRESSION.md section 6 before moving any of them.
- The acquisition card must not block retry. One line on the result card, opened
  only by tapping it.
- The share URL carries `?seen=<cat>`, which marks that cat witnessed in the
  receiver's codex. No backend.

Section 3 of `GAME_DESIGN.md` ("do not add currencies or level complexity during
prototype validation") predates this and was written for the validation phase.
The port is now feature-complete against the prototype and the user approved this
system explicitly; the rule stands for anything else.

## 15. Story and languages

Approved 2026-08-28. Full spec in `STORY.md`.

The cat is **Tori**. Its person died first and went on ahead; Tori is walking to
find them. The game formerly had no story and the starting cat was called
HALF-STEP; both changed, and a save from before the rename still works.

The game is called **토리: 조금만 더 / TORI: Just a Little Further** (`TITLE` and
`SUBTITLE` in the translation table). The repository, the save file
`user://half_step.cfg` and the `HalfStep*` identifiers keep their old names on
purpose — see STORY.md section 0. Do not "finish" the rename by touching the
save path; that takes every player's progress.

Hard rules:
- **No player-visible string may be a literal.** Every one is a key in
  `assets/i18n/half_step.csv`. The fonts are subsets built from that file, so a
  literal is a string with no glyphs on the player's screen. This has already
  shipped broken once — see PROTOTYPE_HISTORY.md.
- Look strings up with `I18n.t()`, not `Object.tr()`: most text here is drawn
  from static functions where `tr()` does not exist.
- After changing any translated string, run `tools/build_fonts.py` and commit
  the fonts. `progression_test.gd` fails if you forget, naming the character and
  the locale — this shipped broken twice before that guard existed.
- The ending is gated on **distance walked as Tori** (`StoryConfig.REUNION_STEPS`),
  never on score and never on level. A failed run still counts toward it. Do not
  move it onto a skill axis: see STORY.md section 1.
- The ending does NOT end the game. Play continues unchanged afterwards.
- The title screen appears on a **cold launch only**. Retry must never pass
  through it.
- The epilogue at score 1000 has no card and no text. It is a thing seen, not a
  thing announced, and it shares its threshold with the BEYOND sky and the
  codex's last cat. Do not give it a threshold of its own.
- The ending's replay row appears only after it has been seen. Showing it early
  gives away that there is an ending.
- Zone names, milestone tags and PLAY · FAIL · SHARE · REPEAT stay English. They
  are stylised proper nouns, not untranslated strings.

## 16. Agent completion checklist

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
