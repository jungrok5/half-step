# HALF STEP — Prototype History

This file exists so future agents do not repeat failed design experiments.

## Prototype 1 — DAY 1

Strongest baseline.

What worked:
- tap toggles lane immediately
- world/platform rows move on fixed cadence
- fast retry
- gradual acceleration
- simple left/right reading

User reaction: fun immediately.

Core insight:
The satisfying part was adapting to the speed/rhythm and feeling "I'm doing well."

## Prototype 2 — Feel / PERFECT / audio

Added:
- landing squash
- platform bounce
- vibration
- audio
- PERFECT
- rising pitch

Positive:
- rising notes on consecutive successes felt good.

Later decision:
- PERFECT itself was not useful/readable and has since been removed.
- rising success melody remains.

## Prototype 3 — Variable rhythm + stars

Added:
- rhythm/interval variation
- occasional two-safe platforms
- star reward

Rejected strongly.

Reason:
- slowing down after learning a rhythm felt unpleasant
- speed changes were hard to interpret
- star mechanic was not compelling

Permanent lesson:
Never use sudden slowdowns or irregular cadence as difficulty/content.

## Clarity experiment — tap causes physical jump

Changed tap into immediate physical jump toward next platform.

Rejected:
- too confusing
- too hard
- mixed timing and direction decisions

## Queue experiment

Tap queued next landing lane; automatic jump showed intended target.

Rejected:
- too easy
- too much planning time
- lost reaction pressure

## Day1 refined

Returned closer to original but blocked inputs during landing.

Rejected:
- taps sometimes felt ignored
- user died despite pressing

Permanent lesson:
Never drop input.

## Responsive Day1

Accepted taps during short hop/landing.

Result:
- returned close to original fun
- not obviously better than DAY 1, but acceptable
- rising-note audio remained desired

## Cloud concept 1

Initial cloud movement accidentally communicated ascending upward.

Rejected direction.

Correct interpretation:
- traveling FORWARD through/above clouds
- vertical-scrolling airplane-game sensation
- clouds stream downward toward player

## Death evolution

Bad:
- character moved toward center vanishing point
- character fell toward phone bottom edge

Correct:
- character misses at its current position
- stays nearly at same x/y
- shrinks/fades into distant depth
- falling pitch also decreases and fades

## PERFECT removal

PERFECT text was not reliably visible and added unnecessary complexity.

Final decision:
- remove PERFECT concept entirely
- no PERFECT score
- no PERFECT text
- no PERFECT bonus chord

## Landing impact refinement

Current desired effect:
- original platform remains readable
- a temporary duplicate/ghost expands and disappears
- tiny pixel fragments
- subtle original platform compression

This improves impact without destroying positional clarity.

## Viral progression

High-score sky regions were introduced so high-score footage itself becomes desirable/shareable.

Key idea:
Do not expose all late-game visuals in marketing.
Players who cannot reach them should be curious about them.

## Godot port of the pixel skin prototype

The Godot project is a direct port of
`reference/web-prototypes/half_step_pixel_skin.html`: same layout constants,
step cycle, easing curves, zone table, melody, result card and share image, all
working in the prototype's CSS pixel units.

Five prototype behaviours were fixed instead of copied. They are flaws, not
design, and each has a regression test — do not restore them:

1. **A row decided two landings.** Rows stayed eligible after being landed on,
   and the post-landing slide left the used row 14px from the player while the
   next was 78px away, so `nearestRow()` picked the used one again. Every run
   opened with a forced repeat of `pattern[0]`. Rows are now marked resolved.
2. **Speed stopped increasing around score 322.** The 125ms hop and 50ms settle
   gate each step, so their 175ms sum capped the cadence exactly where the late
   zones begin. They now compress once the cadence is shorter than they are, so
   acceleration continues to the 24ms technical floor.
3. **Retry was not immediate.** Taps were swallowed for the whole fall and the
   card only answered its own buttons. Any tap now retries at once; SHARE is the
   only exempt target.
4. **A resize ended the run.** `window.onresize` called `reset()`, so a phone
   browser hiding its address bar killed a good run. The row stack is now
   re-laid out around the new player height.
5. **A bare strip at the top of tall screens.** Only seven rows were built at
   the start. The opening stack is now filled to the top of the screen.

Permanent lesson:
Port the feel, not the defects. When the prototype contradicts `AGENTS.md`,
`AGENTS.md` wins.

## Playtest, top-down build

Two things found by actually playing the exported build in a browser rather than
by reading code.

### Retrying on the death tap ate the death

An earlier change let any tap retry the moment the run ended, to satisfy the
"restart must feel immediate" rule. But a player dies mid-rhythm, so a tap is
almost always already in flight when the run ends: it was consumed as a retry,
and the fall animation and the score card never appeared. In a filmstrip of six
seconds of rhythmic tapping the card never survived a single frame — the run
just silently started over.

Fix: taps are ignored until the card is up, then a tap anywhere retries. Retry
still costs one tap and no button hunting.

Permanent lesson:
"Never drop input" is about lane taps during play. The tap that arrives at the
moment of death is a different tap, and consuming it destroys the death.

### Platforms read as gates, not as bridges

The landing was judged against the row a full spacing above the cat, and the
stack only snapped down afterwards. On screen the cat never jumped onto
anything: a platform hung overhead, the score ticked, and the platform then
teleported under the cat. It read as passing through a door.

Fix: the stack slides toward the cat across the jump, so the bridge arrives
underneath exactly as the landing resolves. The rows themselves still move once,
at the end of the step — only the drawn offset is animated, so no rule changed.

Permanent lesson:
Where the judgement happens and where the player sees it happen must be the same
place. A correct rule that resolves somewhere the player is not looking reads as
a different game.

### The cat stood on nothing

The tap flipped the lane and the cat was drawn in the new lane straight away.
But the bridge under it belongs to the row it already landed on, and the other
lane of that row is empty — so for most of a beat the cat hovered over open sky,
and nothing happened. Measured: after a tap the cat sat at x=247 while its
bridge was at x=125.

The rule was never wrong; only the landing instant decides. What was wrong was
showing a player floating over a gap and surviving it, which makes the bridges
look decorative.

Fix: the cat keeps standing on its own deck and leans toward the lane it has
committed to; the jump carries it across. It is now always on a bridge or in the
air.

Permanent lesson:
Do not let the character occupy a place the rules do not support, even briefly.
Players read position as truth, and a survivable impossible position teaches
them the obstacles are fake.

### The lean was a free pass (2026-08-27)

Leaning solved the floating cat but left the game trivially easy: a tap could be
made at any point in the beat and the cat was carried across regardless. Nothing
was being timed. As the player put it — a tap made early is not a beat spent
hovering, it is a jump into empty space, and it should end the run.

Fix, on explicit request: a tap is a jump, resolved at the instant it is made.
`HalfStepState.can_cross()` asks whether the arriving bridge has closed to
within `CROSS_REACH` (half a row spacing) of the cat and is on the lane being
jumped to. If not, the cat completes its arc and falls. Because the window is a
fraction of the row spacing rather than a fixed number of milliseconds, it opens
at the midpoint of every beat at every cadence, so the timing demand scales with
the speed curve instead of being outrun by it.

This reinstates a design AGENTS.md section 3 records as rejected ("Tap =
immediate full physical jump toward the next platform"). It was rejected for
being confusing; the difference now is that the world scrolls continuously
across the beat, so the arriving bridge is visible to time against — the
information the original version never showed. Do not remove it again without
the same explicit approval that put it back.

Verified with a headless bot that taps at a fixed point in every beat: tapping
before the midpoint dies within two beats; tapping anywhere from the midpoint on
survives to score 400.

Permanent lesson:
A difficulty knob only exists if the player can see what it is measuring. The
same rule that was unreadable against a snapping row stack is fair against a
sliding one.

### The run opened in mid-air (2026-08-27)

With landings now visibly physical, the first frame of every run showed the cat
hanging over open sky for a whole beat — the row stack started a full spacing
above it. `rebuild_rows()` now lays a bridge at the player's own height, marked
resolved so it never decides a landing. It only exists so the opening frame says
"you are standing on a bridge".

Permanent lesson:
The first frame teaches the rules. It has to show the state the game wants the
player to protect.

## Progression design — the cat codex (2026-08-28)

The goal was collection with a Lineage-grade levelling curve: score is experience,
and reaching certain levels opens cats one at a time.

### Score itself cannot be experience

Rejected immediately. The cadence decays exponentially, so score 400 is hundreds
of times harder than score 40, not ten times. Adding score straight to a lifetime
pool makes **farming short runs the optimal strategy** and turns the codex into a
measure of patience. One landing pays `(560 / step_interval)²` instead, which is
the game's own speed constant squared — no new tuning value, and one score-1000
run is worth 1,900 score-60 runs.

Permanent lesson:
When a game's difficulty curve is exponential, any linear reward on top of it
pays the wrong behaviour.

### First draft: all 24 cats on the level curve — rejected

The curve was built and the numbers computed: Lv40 at 400 hours for a regular
player, Lv50 at 8,110. Six cats sat behind that. It was rejected before shipping,
on the grounds that the difficulty was on an axis nobody can see.

The user's intent was that difficulty itself be the viral driver. Half right:
scarcity does not produce sharing, provable scarcity does. "I ground for 400
hours" has no screenshot, no verification and no envy. "Score 750, WHITE HORIZON"
is a picture, and the receiver compares it to their own best instantly. A wall of
hours reads to a viewer as *give up*; a wall of skill reads as *one more run*.

The fix moved 11 of 24 cats onto single-run conditions — seven sky scores and four
in-run feats — and stopped level cats at Lv 30. **The curve was not softened.**
Levels 31–50 keep the brutal shape as a pure prestige number that appears on the
share card, because a wall with content behind it is content nobody sees, while a
wall with a number behind it costs nothing. Completing the codex now needs score
1000 in one run, which is far harder than the version that was rejected.

Permanent lesson:
Difficulty and virality are not the same axis. Put the wall where a screenshot
can prove it was climbed, and leave the invisible grind carrying nothing but a
number.

### The witness link

Every share of a run or a cat carries `?seen=<cat>`. Opening the link records
that cat as witnessed in the receiver's codex — fully drawn and named, still
locked. It needs no backend, and NAMELESS opens only after five different
witnesses, so the codex cannot be completed alone.

Permanent lesson:
A share that gives the receiver nothing is a boast, not a loop. Make opening the
link change something on the receiver's side.
