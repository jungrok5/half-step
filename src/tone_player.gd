class_name TonePlayer
extends AudioStreamPlayer

## Web Audio equivalent for the prototype's `tone()` and `fallSound()`.
##
## Both prototype sounds are a single oscillator with an exponential gain ramp,
## so the same envelopes are synthesised here into an AudioStreamGenerator.
## Voices are mixed rather than replaced: past a few hundred points the cadence
## is shorter than a note, exactly as overlapping oscillators behave in Web Audio.

enum Wave { TRIANGLE, SINE }

const MIX_RATE := 44100.0
const BUFFER_LENGTH := 0.06
## `successSound()` — major scale across three octaves.
const SCALE := [0, 2, 4, 5, 7, 9, 11, 12]
const PHRASE_LENGTH := 24
## Middle C. The prototype used a round 260 Hz, which is eleven cents flat and
## beats audibly against anything tuned to A=440 — and music is coming, all of
## it in C major so it sits under this melody (docs/audio/PROMPTS.md).
## AUDIO_RULES.md allows the base frequency to be tuned; this is that.
const BASE_FREQUENCY := 261.63
const MAX_VOICES := 12
## Two crossings inside this many seconds play one cue. Past a few hundred
## points the cadence is shorter than the sound, and a meow per beat is noise.
const CUE_GAP := 0.16

class Voice:
	var wave: int = Wave.TRIANGLE
	var frequency_from := 440.0
	var frequency_to := 440.0
	var frequency_seconds := 1.0
	var gain_from := 0.06
	var gain_to := 0.001
	var gain_seconds := 0.09
	var duration := 0.09
	var elapsed := 0.0
	var phase := 0.0

var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Voice] = []
## Recorded cues, when the files exist. Several players so a fall can ring under
## a crossing without cutting it off.
var _cue_players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _last_cue := {}


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	# The project routes web audio through sampled playback, which a generator
	# cannot provide — on the web export that silences the game and logs
	# "trying to play a sample from a stream that cannot be sampled".
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	play()
	_playback = get_stream_playback()
	for i in 4:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_cue_players.append(player)


## Frequency of the note played for [param phrase_position] (0-23).
static func note_frequency(phrase_position: int) -> float:
	var position := posmod(phrase_position, PHRASE_LENGTH)
	var degree: int = SCALE[position % 8]
	var octave: int = position / 8
	return BASE_FREQUENCY * pow(2.0, float(degree + 12 * octave) / 12.0)


## `successSound()` — one note per successful landing, left/right agnostic.
func play_success_note(phrase_position: int) -> void:
	var voice := Voice.new()
	voice.wave = Wave.TRIANGLE
	voice.frequency_from = note_frequency(phrase_position)
	voice.frequency_to = voice.frequency_from
	voice.gain_from = 0.06
	voice.gain_to = 0.001
	voice.gain_seconds = 0.09
	voice.duration = 0.09
	_push(voice)


## The cat leaving one bridge for the other — the tap, not the landing.
##
## The landing melody keeps advancing whether or not the player crossed
## (AUDIO_RULES.md), so this rides on top of it rather than replacing it: the
## melody says "you survived", this says "you jumped".
func play_cross() -> void:
	if _play_cue(AudioBank.CUE_CROSS):
		return
	# Placeholder until the recording exists: a short rising chirp, sine against
	# the melody's triangle, so the two are never mistaken for each other.
	var voice := Voice.new()
	voice.wave = Wave.SINE
	voice.frequency_from = 520.0
	voice.frequency_to = 900.0
	voice.frequency_seconds = 0.05
	voice.gain_from = 0.045
	voice.gain_to = 0.001
	voice.gain_seconds = 0.13
	voice.duration = 0.14
	_push(voice)


## `fallSound()` — 780 Hz sliding down to 80 Hz while fading out.
func play_fall() -> void:
	if _play_cue(AudioBank.CUE_FALL):
		return
	var voice := Voice.new()
	voice.wave = Wave.SINE
	voice.frequency_from = 780.0
	voice.frequency_to = 80.0
	voice.frequency_seconds = 0.84
	voice.gain_from = 0.065
	voice.gain_to = 0.001
	voice.gain_seconds = 0.88
	voice.duration = 0.9
	_push(voice)


func play_cue(id: String) -> void:
	_play_cue(id)


func stop_all() -> void:
	_voices.clear()
	for player in _cue_players:
		player.stop()


## Plays a recorded cue. Returns false when there is no file for it yet, which
## is the caller's signal to fall back to synthesis.
func _play_cue(id: String) -> bool:
	var stream := AudioBank.sfx(id)
	if stream == null:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_cue.get(id, -99.0)) < CUE_GAP:
		return true
	_last_cue[id] = now
	var player := _cue_players[_next_player]
	_next_player = (_next_player + 1) % _cue_players.size()
	player.stream = stream
	player.play()
	return true


func _push(voice: Voice) -> void:
	if _voices.size() >= MAX_VOICES:
		_voices.pop_front()
	_voices.append(voice)


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var step := 1.0 / MIX_RATE
	for _i in frames:
		var sample := next_sample(step)
		_playback.push_frame(Vector2(sample, sample))
	_prune()


## One mixed frame, advanced by [param step] seconds. Split out from [method
## _process] so the synthesis can be driven directly: the headless audio driver
## never pulls frames from the generator.
func next_sample(step: float) -> float:
	var sample := 0.0
	for voice in _voices:
		sample += _advance(voice, step)
	return clampf(sample, -1.0, 1.0)


func _prune() -> void:
	var alive: Array[Voice] = []
	for voice in _voices:
		if voice.elapsed < voice.duration:
			alive.append(voice)
	_voices = alive


func _advance(voice: Voice, step: float) -> float:
	if voice.elapsed >= voice.duration:
		return 0.0
	var frequency := voice.frequency_from
	if not is_equal_approx(voice.frequency_to, voice.frequency_from):
		var ratio := minf(voice.elapsed / voice.frequency_seconds, 1.0)
		frequency = voice.frequency_from * pow(voice.frequency_to / voice.frequency_from, ratio)
	var gain_ratio := minf(voice.elapsed / voice.gain_seconds, 1.0)
	var gain: float = voice.gain_from * pow(voice.gain_to / voice.gain_from, gain_ratio)
	voice.phase = fmod(voice.phase + frequency * step, 1.0)
	voice.elapsed += step
	return _wave(voice.wave, voice.phase) * gain


static func _wave(wave: int, phase: float) -> float:
	if wave == Wave.SINE:
		return sin(phase * TAU)
	return 1.0 - 4.0 * absf(fmod(phase + 0.25, 1.0) - 0.5)
