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

## The epilogue: past this score in a single run, someone is walking the bridges
## ahead of Tori. No card, no text, no interruption — it is a thing the player
## sees, and almost nobody will.
##
## This is the rare half of the split STORY.md section 1 describes. The ending
## is the story's payoff and has to be reachable; this is the part worth
## filming, and it reuses a threshold the game already has (BEYOND, and the
## hardest cat in the codex) instead of inventing one.
const EPILOGUE_SCORE := 1000
## How many rows ahead the figure walks. Always a little further.
const EPILOGUE_LEAD := 3


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
	MEMORIAL_FRAME,
]

## The memorial. It has no still, because it is drawn from the save file: the
## portrait, the date, and what this player and this cat actually did. It holds
## until the player leaves it, which is the only frame that does — the rest of
## the game gives you no way to stay anywhere.
const MEMORIAL_FRAME := {"text": "MEMORIAL_LINE_1", "memorial": true, "hold": true, "sky": 10}

## The same card on its own, for the records row on the title screen: somebody
## coming back to look at Tori should not have to sit through the ending first.
const MEMORIAL: Array[Dictionary] = [MEMORIAL_FRAME]

## The day. Written here rather than built from a timestamp so it can never be
## localised into some other date by a helpful formatter.
const MEMORIAL_DATE := "2019. 09. 21."


static func frames(which: String) -> Array[Dictionary]:
	match which:
		"ending":
			return ENDING
		"memorial":
			return MEMORIAL
	return INTRO


static func duration(which: String) -> float:
	return float(frames(which).size()) * (FRAME_MS + FADE_MS)
