# TORI — Audio Rules

Prompts for producing the music and the effects: `docs/audio/PROMPTS.md`.
Slots live in `assets/audio/`; a slot with no file falls back to synthesis or to
silence, so the game is never broken by audio that has not been made yet.

## Core principle

Audio is part of the rhythm loop, not decoration.

## Music

Added 2026-08-28. Nine beds — five bands of skies (`AudioBank.MUSIC_BANDS`),
plus title, intro, ending and the memorial, crossfaded over 2.2 s when the score
crosses a band or the screen changes.

The memorial has its own bed because it is the only frame in the game that never
times out: the ending's one-shot would run out under that card and leave a
player sitting in silence with a photograph.

Three rules, and they are not stylistic:

- **C major, A=440.** The landing melody plays over everything, several times a
  second. Another key is a wrong note dozens of times a minute. The melody's
  root was retuned from the prototype's 260 Hz to exactly middle C (261.63) for
  this; AUDIO_RULES already allowed the base frequency to be tuned.
- **No percussion, no tempo.** The cadence runs from 560 ms to 24 ms per beat
  inside one run, continuously. Nothing with a fixed tempo can stay with it.
  The player's tapping is the rhythm section; the music is harmony and weather.
- **Quiet, and out of the way.** Keep 250–1100 Hz clear — that is where the
  melody lives.

## The two jumps

Staying in the same lane costs no tap and makes only the landing note. Crossing
adds a cat: `sfx/cross` fires on the TAP, not the landing, and rides on top of
the melody rather than replacing it. The melody says *you survived*; the cue
says *you jumped*.

It can fire several times a second at speed, so it is short, and the engine
refuses to retrigger it inside 160 ms.

`sfx/equip` is the third cat sound: the cat the player just chose, answering from
inside the codex. Lower, calmer and longer than `cross`, because it plays in a
quiet menu where a bright chirp would be startling — and because the two must
never be mistaken for each other.

## Landing success melody

Each successful landing advances ONE note.

The note sequence ignores lane direction.

Examples:

Safe pattern:
L → L → L → R → R

Audio:
note 1 → note 2 → note 3 → note 4 → note 5

The player does not need to switch lanes for the melody to advance.

## Scale

Current prototype intent:

Major scale:
Do Re Mi Fa Sol La Ti Do

Implementation as semitone offsets:
0, 2, 4, 5, 7, 9, 11, 12

Progress through 3 octaves:
- notes 1–8: octave 1
- notes 9–16: octave 2
- notes 17–24: octave 3
- note 25 restarts at low register

Exact base frequency can be tuned.

## Timbre

Keep the successful landing family coherent.

Avoid:
- random unrelated sounds
- surprise chords
- milestone jingles interrupting the rhythmic melody
- PERFECT bonus sounds

High-score world changes should primarily be visual.

### The zone and milestone cues, against that rule

Added 2026-08-29, and they sit close enough to the line to be worth stating.

`sfx/zone` fires with the sky banner and `sfx/milestone` with a milestone flash.
Both are within the rule as written, and the brief keeps them there:

- Neither is a **jingle**. Both are specified with no downbeat, no percussion
  and no impact transient — air and ring-out, opening rather than hitting. A
  fanfare at score 250 is still forbidden.
- Neither **interrupts** anything. They play on their own voices; the landing
  melody keeps firing underneath, unchanged.
- The world change is still **primarily visual**. The banner, the sky fade and
  the music crossfade do the work; a 1.2-second swell is the seam, not the
  event.

If either ever starts reading as a reward rather than as weather, delete the
file: both slots fall back to silence and nothing else has to change.

## Landing impact sound

May add a very subtle transient if it does not obscure the melody.
Current priority is melody clarity.

## Death sound

Pitch decreases continuously while volume fades.

Desired perception:
player is becoming smaller/farther away.

This sound is allowed to break the melody because the run has ended.

## Vibration

Very short vibration on landing may be used.
Stronger pattern on death.

Must be tested on real Android hardware.
