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
