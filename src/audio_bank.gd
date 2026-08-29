class_name AudioBank
extends RefCounted

## Where the game looks for sound files, and what it does when they are not
## there yet.
##
## Every cue and every track has a slot. A slot with a file plays the file; a
## slot without one falls back to the synthesised sound the prototype shipped
## with, or to silence for music. So the game is never broken by missing audio,
## and adding a sound is dropping an `.ogg` into `assets/audio/` — the same
## contract the story stills use.
##
## Prompts for producing them: `docs/audio/PROMPTS.md`.

const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"

## The cat crossing to the other lane. Fires on the tap, not on the landing.
const CUE_CROSS := "cross"
## Falling out of the sky. Replaces the prototype's pitch slide.
const CUE_FALL := "fall"
## A cat opening in the codex.
const CUE_UNLOCK := "unlock"
## Arriving — the ending, once ever.
const CUE_ARRIVE := "arrive"
## The sky changing under the cat. Rides the zone banner, so it fires ten times
## in a very long run and never during the first one.
const CUE_ZONE := "zone"
## A milestone flash. Rarer and bigger than a zone, and the last of them is at
## the score almost nobody reaches.
const CUE_MILESTONE := "milestone"
## Putting a different cat on the bridge, from inside the codex.
const CUE_EQUIP := "equip"
## A button that changes what is on screen. Deliberately used in three places
## only — see docs/audio/PROMPTS.md on why the run itself stays quiet.
const CUE_UI := "ui"

## Music tracks, one per band of skies rather than one per sky: eleven zones
## would be eleven downloads, and the skies change faster than music should.
const MUSIC_TITLE := "title"
const MUSIC_INTRO := "intro"
const MUSIC_ENDING := "ending"
## Under the memorial, which holds for as long as the player wants it. The
## ending's one-shot would run out under that card and leave it in silence.
const MUSIC_MEMORIAL := "memorial"
const MUSIC_BANDS: Array[Dictionary] = [
	{"score": 0, "track": "day"},
	{"score": 60, "track": "dusk"},
	{"score": 150, "track": "star"},
	{"score": 300, "track": "deep"},
	{"score": 550, "track": "beyond"},
]

static var _cache: Dictionary = {}


## The track that should be playing at [param score].
static func music_for_score(score: int) -> String:
	var track := String(MUSIC_BANDS[0].track)
	for band in MUSIC_BANDS:
		if score >= int(band.score):
			track = String(band.track)
	return track


## Ogg first, then WAV. Music has to be Ogg to be affordable, but a short cue
## as a WAV is a few kilobytes and decodes instantly, so whatever came out of
## the editor can be dropped in without a conversion step.
const EXTENSIONS: PackedStringArray = [".ogg", ".wav"]


static func sfx(id: String) -> AudioStream:
	return _find(SFX_DIR, id)


static func music(id: String) -> AudioStream:
	var stream := _find(MUSIC_DIR, id)
	# Gameplay beds run under a run of any length, so they loop; the three
	# one-shots do not, or the ending would start again over the result card.
	var looping := id != MUSIC_INTRO and id != MUSIC_ENDING
	if stream is AudioStreamOggVorbis:
		stream.loop = looping
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		stream.loop_end = stream.data.size() / (2 * (2 if stream.stereo else 1))
	return stream


static func _find(directory: String, id: String) -> AudioStream:
	for extension in EXTENSIONS:
		var stream := _load("%s/%s%s" % [directory, id, extension])
		if stream != null:
			return stream
	return null


## Whether a slot has been filled yet. Used by the tests, so a missing file is
## reported as "not recorded" rather than as a failure.
static func has(path: String) -> bool:
	return ResourceLoader.exists(path)


static func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = ResourceLoader.load(path) as AudioStream
	_cache[path] = stream
	return stream
