# HALF STEP — Progression & Cat Codex

Approved 2026-08-28. The interactive version of this document, with all 24 cats
drawn from the game's own geometry, lives at `docs/progression/sky-cat-codex.html`.

Nothing here changes how the game plays. Cats are purely cosmetic: judgement,
cadence, score and death are untouched by which cat is equipped.

---

## 1. The three ways a cat opens

| Axis | Cats | Opened by | What it is for |
|---|---:|---|---|
| Level | 12 | Cumulative EXP | Retention. Brings the player back tomorrow. |
| Run | 11 | One run's score or feat | Virality. Every one of them is a claim you can put on a card. |
| Witness | 1 | Someone else's share link | The social lock. Cannot be opened alone. |

The split is the whole design. See section 6 for why the difficulty sits mostly
on the run axis rather than the level axis.

24 is not arbitrary: the success melody cycles every 24 notes
(`HalfStepState.NOTE_COUNT`), and the codex cycles in 24 slots.

---

## 2. Experience

**One landing's EXP = `(560 / step_interval)²`**, where `step_interval` is the
value `HalfStepState` already maintains — `max(24, 560 × 0.9964^score)`.

EXP accrues in `resolve_landing()`, beside the line that already updates
`step_interval`. It is never lost: death does not deduct it. (Lineage's EXP-loss
mechanic is deliberately NOT carried over — it fights AGENTS.md section 2,
"restart must feel immediate".)

### Why not the score itself

Score 400 is not ten times harder than score 40; because the cadence decays
exponentially it is hundreds of times harder. If score were EXP directly, the
optimal strategy would be **farming short runs**, and the codex would measure
patience instead of skill. Weighting each step by the square of its speed makes
depth always dominate repetition — the same structure as a stronger monster
paying exponentially better EXP.

The speed floor of 24 ms is reached at score 874, so every step past that pays a
flat 544.

| Score | Zone | EXP per step | EXP for the run | Run length |
|---:|---|---:|---:|---:|
| 10 | BLUE SKY | 1.1 | 10 | 5s |
| 30 | GOLDEN WIND | 1.2 | 34 | 16s |
| 60 | SUNSET RUN | 1.5 | 75 | 30s |
| 100 | NIGHT BREAK | 2.1 | 147 | 47s |
| 200 | STAR RUSH | 4.2 | 450 | 80s |
| 300 | RED STRATOS | 8.7 | 1,072 | 102s |
| 400 | VOID CURRENT | 17.9 | 2,352 | 118s |
| 550 | CHROMA STORM | 52.8 | 7,212 | 134s |
| 750 | WHITE HORIZON | 223.6 | 30,969 | 145s |
| 1000 | BEYOND | 544.4 | 144,545 | 151s |

One score-1000 run is worth 1,900 score-60 runs.

---

## 3. The level curve

Requirement multiplies each level: ×1.24 for Lv 1–9, ×1.27 for 10–19, ×1.30 for
20–29, ×1.33 for 30–39, ×1.36 for 40–50, starting from 40 EXP, each result
rounded to two significant figures. Ten levels costs roughly ten times the
previous ten — the Lineage shape.

**Level 1 is free.** The player starts there owning HALF-STEP, and each row's
"Need" is the cost of arriving at that level from the one below. The table is
`Progress.LEVEL_STEPS`, and `progression_test.gd` asserts these exact numbers.

**Level cats stop at Lv 30. Everything above is a prestige number**: the level
keeps climbing and appears on the share card, but no content is locked behind it.
Hiding six cats behind a 5,918-hour wall would mean building content nobody ever
sees, which contradicts AGENTS.md section 8's requirement that later content
exist to be *wanted*.

Hours below are pure play time for four archetypes, defined by their average
score across runs (7 s of overhead per run is included):

| Archetype | Avg score | Run length | EXP/hour |
|---|---:|---:|---:|
| Beginner | 15 | 15s | 3,775 |
| Regular | 60 | 37s | 7,300 |
| Strong | 200 | 87s | 18,682 |
| Elite | 400 | 126s | 67,551 |

| Lv | Need | Cumulative | Cat | Beginner | Regular | Strong | Elite |
|---:|---:|---:|---|---:|---:|---:|---:|
| 1 | — | 0 | HALF-STEP | 1s | 1s | 1s | 1s |
| 2 | 40 | 40 | MILK | 38s | 20s | 8s | 2s |
| 3 | 50 | 90 | SOOT | 1m | 44s | 17s | 5s |
| 4 | 62 | 152 | BUTTER | 2m | 1m | 29s | 8s |
| 5 | 76 | 228 | TUXEDO | 4m | 2m | 44s | 12s |
| 7 | 120 | 443 | CALICO | 7m | 4m | 1m | 24s |
| 9 | 180 | 773 | EMBER | 12m | 6m | 2m | 41s |
| 12 | 350 | 1,623 | MIDNIGHT | 26m | 13m | 5m | 1m |
| 16 | 920 | 4,283 | NIMBUS | 1.1h | 35m | 14m | 4m |
| 20 | 2,400 | 11,283 | RAIN | 3.0h | 1.5h | 36m | 10m |
| 25 | 8,600 | 38,483 | FROST | 10h | 5.3h | 2.1h | 34m |
| 30 | 32,000 | 140,483 | GALAXY | 37h | 19h | 7.5h | 2.1h |
| 35 | 130,000 | 539,483 | prestige | 143h | 74h | 29h | 8.0h |
| 40 | 540,000 | 2,199,483 | prestige | 583h | 301h | 118h | 33h |
| 45 | 2,500,000 | 9,499,483 | prestige | 2,516h | 1,301h | 508h | 141h |
| 50 | 11,000,000 | 43,199,483 | prestige | 11,444h | 5,918h | 2,312h | 640h |

These hours assume each archetype sustains that average. Real averages sit well
below a player's best, so measured times will be longer. The shape holds.

---

## 4. The roster

Every cat is a parameter set, never a sprite — see section 5. Sky is the
gradient the codex card is drawn on, taken from `ZoneConfig`.

### Level — 12

| Lv | Name | Code | Sky | Pattern / ears / tail / build |
|---:|---|---|---|---|
| 1 | 반걸음 | HALF-STEP | BLUE SKY | tabby · pricked · long · standard |
| 2 | 우유 | MILK | BLUE SKY | solid · pricked · long · slim |
| 3 | 그을음 | SOOT | BLUE SKY | tabby · pricked · long · standard |
| 4 | 버터 | BUTTER | GOLDEN WIND | spotted · pricked · plume · chonk |
| 5 | 턱시도 | TUXEDO | GOLDEN WIND | tuxedo · pricked · long · standard |
| 7 | 삼색 | CALICO | GOLDEN WIND | calico · pricked · long · standard |
| 9 | 노을등 | EMBER | SUNSET RUN | tabby · tufted · plume · chonk |
| 12 | 자정 | MIDNIGHT | NIGHT BREAK | solid · folded · long · standard |
| 16 | 구름솜 | NIMBUS | SUNSET RUN | van · pricked · plume · chonk |
| 20 | 밤비 | RAIN | NIGHT BREAK | spotted · pricked · bob · slim |
| 25 | 서리 | FROST | STAR RUSH | point · pricked · long · slim |
| 30 | 은하 | GALAXY | STAR RUSH | spotted · pricked · plume · standard |

### Run — sky, 7

Each requires reaching that score **in a single run**. The player has seen that
sky; the cat is the proof.

| Score | Name | Code | Zone | Pattern / ears / tail / build |
|---:|---|---|---|---|
| 100 | 침묵 | SILENCE | NIGHT BREAK | solid · curl · long · standard, no markings |
| 210 | 오로라 | AURORA | AURORA EDGE | bicolor · curl · long · slim, aura |
| 300 | 잿불 | CINDER | RED STRATOS | tabby · pricked · kinked · standard |
| 400 | 공허 | VOID | VOID CURRENT | solid · pricked · long · standard, alpha 0.8 |
| 550 | 색채 | CHROMA | CHROMA STORM | bicolor · curl · plume · standard, aura |
| 750 | 백색 | HORIZON | WHITE HORIZON | solid · pricked · plume · chonk, aura |
| 1000 | 너머 | BEYOND | BEYOND | a cat-shaped hole; the sky shows through |

### Run — feat, 4

Not how far, but how it was walked. **These four thresholds are estimates made
before anyone has played the tap-as-jump build. They are the first thing to
retune against real data.**

| Condition | Name | Code | Sky | Notes |
|---|---|---|---|---|
| 40 lane crossings in one run | 자오선 | MERIDIAN | VOID CURRENT | van · tufted · plume · chonk, aura |
| Score 100 on the first run after launch | 흑요 | OBSIDIAN | NIGHT BREAK | solid · folded · long · slim, aura |
| Three consecutive runs all scoring 60+ | 북극 | POLAR | STAR RUSH | tabby · tufted · plume · chonk |
| 30 consecutive jumps taken in the first 10% of the crossing window | 마지막걸음 | LAST-STEP | BLUE SKY | silhouette filled with the current sky |

The crossing window opens at the midpoint of each beat
(`HalfStepState.CROSS_REACH`); the first 10% of it is the earliest and riskiest
moment to leave.

### Witness — 1

| Condition | Name | Code | Sky |
|---|---|---|---|
| Witness 5 different cats on other players' cards | (no name) | NAMELESS | BEYOND |

Its condition is hidden in the codex until the fifth witness lands.

---

## 5. A cat is a parameter set, not a sprite

`src/art.gd` already builds the cat from primitives, so a cat is one dictionary.
No sprite sheet, no atlas, no art pipeline. Nine axes:

| Axis | What it changes |
|---|---|
| `fur` / `fur_dark` | base and marking colour (`FUR_COLOR`, `FUR_DARK_COLOR`) |
| `paw` | paws and whiskers — the only parts drawn outside the silhouette |
| `inner_ear` | the two dots that say which way the head points |
| `pattern` | tabby · solid · spotted · tuxedo · calico · point · van · bicolor · window · hole |
| `ears` | pricked · folded · curl · tufted |
| `tail` | long · plume · bob · kinked (`TAIL_SEGMENTS` count and thickness) |
| `build` | slim · standard · chonk (`BODY` radii) |
| `marks` | the tabby "M", present or absent |
| `aura` | alpha, glow, trail — late cats only |

### Pose cache

`Art._cat_poses` currently holds up to 16 tail phases × 7 leap steps = 112 merged
silhouettes. Ears, tail and build change the silhouette, so the key must include
the cat — which would be 2,688 entries across 24 cats. **Cache only the equipped
cat and clear on change.** The codex screen draws static poses and needs no cache.

`Art.draw_cat()` takes the cat as a new trailing argument defaulting to HALF-STEP,
so every existing call keeps working.

---

## 6. Why the difficulty sits on the run axis

The first draft of this system put all 24 cats on the level curve, with the last
six behind hundreds to thousands of hours. That was rejected. Scarcity does not produce sharing;
**provable** scarcity does.

| | Time axis | Run axis |
|---|---|---|
| Proof | No screenshot exists. One number, unverifiable. | The sky reached is the card's background. |
| Frequency | 24 events per lifetime, 20 of them in month one. | Fires whenever skill improves — follows the growth curve. |
| Receiver | "Thousands of hours? I'm out." A deterrent, not an invitation. | "I got to 320" — one more run away. |
| Skill | Skill cannot fold time. | The difficulty *is* the brag. |

**The total difficulty went up, not down.** Completing the codex now requires
score 1000 in a single run, which is incomparably harder than 400 hours of
grinding. Only its location changed — from a wall nobody sees to a wall everybody
wants to see.

It also lands where AGENTS.md section 8 already put the rule: players who cannot
reach a sky do not get to see it. The seven sky cats simply obey the rule that
was already there.

---

## 7. Sharing

See `VIRAL_DESIGN.md` for the card contents. Two things are new:

1. **An acquisition card** alongside the existing run card.
2. **The share URL carries the cat id** (`?seen=aurora`). Opening the link marks
   that cat **witnessed** in the receiver's codex: art, name and condition are
   revealed, but it stays locked. No backend — one query parameter.

That is the actual loop. Sharing used to give the receiver nothing. Now opening a
link puts something in their codex, and NAMELESS cannot be opened without five of
them, so the codex cannot be completed alone.

Each cat also remembers the best score achieved while equipped, printed on the run
card (`반걸음 · best 412`). 24 cats become 24 personal records, so the same cat
keeps producing new content instead of being a one-time collectible.

### The acquisition moment

Must not fight AGENTS.md section 2's "restart must feel immediate":

1. The result card gains **one line** — "new cat · AURORA" and a thumbnail.
2. Tapping that line, and only that, opens the full acquisition card.
3. Sharing goes out through the OS sheet: image plus the `?seen=` link.
4. Not tapping it retries exactly as before.

### Locked, witnessed, owned

- **Locked** — silhouette only, plus the unlock condition. No name, no colour, no sky.
- **Witnessed** — full art and name, visibly desaturated, still locked.
- **Owned** — full card.

---

## 8. Implementation map

| File | Role |
|---|---|
| `src/cat_config.gd` | The 24-cat table and unlock conditions. Static data shaped like `ZoneConfig`. |
| `src/progress.gd` | Cumulative EXP, level, owned/witnessed sets, per-cat best score, equipped cat. Persists into the existing `user://half_step.cfg`. |
| `src/run_feats.gd` | Per-run tallies — crossings and the longest run of early-window jumps. The streaks that span runs live in `progress` instead, because they outlast a run. |
| `src/art.gd` | `draw_cat()` gains a `cat` argument, default HALF-STEP. |
| `src/game_state.gd` | Accrue EXP in `resolve_landing()`. |
| `src/codex_screen.gd` | The grid, four tabs, the bar to the next unlock. |
| `src/share_card.gd` | Acquisition card; run card gains the equipped cat and its best. |
| `src/game.gd` | Equips the cat, feeds `run_feats`, folds the run into `progress` on death, draws the acquisition card, and reads `?seen=` at start (`JavaScriptBridge` on web; a mobile deep link is still to do). |
| `tools/render_cats.gd` | Renders all 24 cats onto their skies as one sheet, for checking the roster at a glance. |
| `tests/progression_test.gd` | The experience formula, the curve, all four unlock paths, and the save round-trip. |

---

## 9. Open values

1. **The four feat thresholds** (40 crossings, 30 early-window jumps, 3×60, first-run 100).
   Chosen blind. Too easy is not a brag; too hard is never seen.
2. **Average-score assumptions** behind every hour in section 3.
3. **Witness reach.** "Five cats from five people" depends on how many players
   exist. If it becomes a slot that never opens for players without friends, drop
   it to three, or accept any public link.
