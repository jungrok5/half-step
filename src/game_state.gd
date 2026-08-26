class_name HalfStepState
extends RefCounted

enum Lane { LEFT, RIGHT }
enum RunState { PLAYING, DEAD }

const START_INTERVAL_MS := 560.0
const MIN_INTERVAL_MS := 24.0
const SPEED_FACTOR := 0.9964
const NOTE_COUNT := 24
const PATTERNS := [
	[0, 1, 0, 1], [1, 0, 1, 0], [0, 0, 1, 1], [1, 1, 0, 0],
	[0, 1, 1, 0], [1, 0, 0, 1], [0, 0, 0, 1], [1, 1, 1, 0],
]

var lane: Lane = Lane.LEFT
var score := 0
var best_score := 0
var run_state: RunState = RunState.PLAYING
var note_index := 0
var upcoming_lanes: Array[int] = []
var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value
	_refill_upcoming()

func toggle_lane() -> void:
	if run_state == RunState.PLAYING:
		lane = Lane.RIGHT if lane == Lane.LEFT else Lane.LEFT

func resolve_landing() -> bool:
	if run_state != RunState.PLAYING:
		return false
	var safe_lane: int = int(upcoming_lanes.pop_front())
	_refill_upcoming()
	if lane != safe_lane:
		run_state = RunState.DEAD
		return false
	score += 1
	best_score = maxi(best_score, score)
	note_index = (note_index + 1) % NOTE_COUNT
	return true

func retry(seed_value: int = 1) -> void:
	lane = Lane.LEFT
	score = 0
	run_state = RunState.PLAYING
	note_index = 0
	upcoming_lanes.clear()
	_rng.seed = seed_value
	_refill_upcoming()

func cadence_ms() -> float:
	return maxf(MIN_INTERVAL_MS, START_INTERVAL_MS * pow(SPEED_FACTOR, score))

func current_zone() -> Dictionary:
	return ZoneConfig.for_score(score)

func _refill_upcoming() -> void:
	while upcoming_lanes.size() < 12:
		var pattern: Array = PATTERNS[_rng.randi_range(0, PATTERNS.size() - 1)]
		for value: int in pattern:
			upcoming_lanes.append(value)
