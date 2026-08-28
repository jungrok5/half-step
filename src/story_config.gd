class_name StoryConfig
extends RefCounted

## Tori's story: where the intro and the ending sit, and what they are made of.
## See STORY.md for why the ending is gated on distance rather than score.

## The ending opens after this many landings made as Tori.
##
## Distance, not score. The story is a cat walking to someone who went ahead, so
## every run counts toward it — a failed run still moved Tori forward. That is
## also why it cannot be farmed or locked behind skill: it only asks the player
## to keep coming back, which is exactly what the story is about.
##
## Roughly 40 to 60 minutes of total play, across two to four sessions.
const REUNION_STEPS := 3000

## One frame of a cut scene. `image` is optional: with no art the frame paints
## the sky beneath its caption, so the sequence runs before the assets exist.
## `ms` is how long the frame holds once it has faded in.
const FRAME_MS := 3400.0
const FADE_MS := 700.0

const INTRO: Array[Dictionary] = [
	{"text": "STORY_INTRO_1", "image": "res://assets/story/intro_1.png", "sky": 0},
	{"text": "STORY_INTRO_2", "image": "res://assets/story/intro_2.png", "sky": 2},
	{"text": "STORY_INTRO_3", "image": "res://assets/story/intro_3.png", "sky": 3},
]

const ENDING: Array[Dictionary] = [
	{"text": "STORY_END_1", "image": "res://assets/story/ending_1.png", "sky": 9},
	{"text": "STORY_END_2", "image": "res://assets/story/ending_2.png", "sky": 9},
	{"text": "STORY_END_3", "image": "res://assets/story/ending_3.png", "sky": 10},
]


static func frames(which: String) -> Array[Dictionary]:
	return ENDING if which == "ending" else INTRO


static func duration(which: String) -> float:
	return float(frames(which).size()) * (FRAME_MS + FADE_MS)
