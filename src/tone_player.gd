class_name TonePlayer
extends AudioStreamPlayer

const SCALE := [0, 2, 4, 5, 7, 9, 11, 12]
const MIX_RATE := 44100.0
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _frequency := 261.63
var _remaining := 0
var _total_frames := 1

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	stream = generator
	play()
	_playback = get_stream_playback()

func play_success_note(completed_note_index: int) -> void:
	var phrase_index := posmod(completed_note_index - 1, 24)
	var octave := phrase_index / 8
	var scale_offset: int = SCALE[phrase_index % 8]
	_frequency = 261.63 * pow(2.0, (scale_offset + octave * 12) / 12.0)
	_remaining = int(MIX_RATE * 0.085)
	_total_frames = _remaining

func play_fall() -> void:
	_frequency = 180.0
	_remaining = int(MIX_RATE * 0.42)
	_total_frames = _remaining

func _process(_delta: float) -> void:
	if _playback == null or _remaining <= 0:
		return
	var frames := mini(_playback.get_frames_available(), _remaining)
	for i in frames:
		var progress := 1.0 - float(_remaining) / float(_total_frames)
		var envelope := pow(1.0 - progress, 2.0)
		var fall_factor := lerpf(1.0, 0.25, progress) if _total_frames > int(MIX_RATE * 0.2) else 1.0
		_phase = fmod(_phase + (_frequency * fall_factor) / MIX_RATE, 1.0)
		var sample := sin(_phase * TAU) * 0.16 * envelope
		_playback.push_frame(Vector2(sample, sample))
		_remaining -= 1

