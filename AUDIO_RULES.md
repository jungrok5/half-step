# HALF STEP — Audio Rules

## Core principle

Audio is part of the rhythm loop, not decoration.

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
