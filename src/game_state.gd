class_name HalfStepState
extends RefCounted

## Pure gameplay rules, ported 1:1 from the JavaScript in
## `reference/web-prototypes/half_step_pixel_skin.html`.
##
## The prototype resolves a landing by looking for the platform row nearest to
## the player instead of popping a queue, and it slides the whole row stack down
## by one spacing 50 ms after each success. Both are reproduced here, because
## the row layout is what decides which lane is safe.
##
## One prototype behaviour is deliberately NOT reproduced: there, a row stays
## eligible after it has been landed on, and the slide leaves it 14px from the
## player while the next row is 78px away — so the very first row is judged
## twice and the run opens with a forced repeat of `pattern[0]`. Rows are marked
## resolved here so each one decides exactly one landing.

enum Lane { LEFT, RIGHT }
enum RunState { PLAYING, DEAD }

const START_INTERVAL_MS := 560.0
const MIN_INTERVAL_MS := 24.0
const SPEED_FACTOR := 0.9964
## `makeRow` spacing and the seven rows built by `rebuildRows`.
const ROW_SPACING := 92.0
const INITIAL_ROWS := 7
## Rows are anchored by their top edge; `nearestRow` compares `r.y + 14`.
const ROW_ANCHOR := 14.0
## Rows below `clientHeight + 100` are dropped, rows are refilled above -100.
const RECYCLE_MARGIN := 100.0
const NOTE_COUNT := 24
## A tap is a jump, not a lane setting: the cat only reaches a bridge that has
## already closed to within this much of it. Half a row spacing opens the window
## exactly at the midpoint of every beat, whatever the cadence, so the timing
## demand stays proportional as the run speeds up.
##
## This is the design AGENTS.md section 3 records as rejected ("Tap = immediate
## full physical jump toward the next platform"). It was reinstated on explicit
## request on 2026-08-27; see PROTOTYPE_HISTORY.md.
const CROSS_REACH := ROW_SPACING * 0.5

const EARLY_PATTERNS: Array = [[0, 1, 0, 1], [1, 0, 1, 0], [0, 0, 1, 1], [1, 1, 0, 0]]
const MID_PATTERNS: Array = [
	[0, 0, 1, 1], [1, 1, 0, 0], [0, 1, 1, 0], [1, 0, 0, 1], [0, 0, 0, 1], [1, 1, 1, 0],
]
const LATE_PATTERNS: Array = [
	[0, 1, 1, 0, 0, 1], [1, 0, 0, 1, 1, 0], [0, 0, 1, 0, 1, 1],
	[1, 1, 0, 1, 0, 0], [0, 1, 0, 1, 1, 0], [1, 0, 1, 0, 0, 1],
]

var lane := 0
var score := 0
## `successStreak` — drives the melody and the FLOW readout.
var success_streak := 0
var run_state: RunState = RunState.PLAYING
var step_interval := START_INTERVAL_MS
var step_timer := 0.0
## Row stack, nearest-to-player first is not guaranteed; each entry is
## `{"y": float, "safe_lane": int, "squash": float}`. `squash` is owned by the
## presentation layer and never read here.
var rows: Array[Dictionary] = []
var pattern: Array = EARLY_PATTERNS[0]
var pattern_index := 0

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func is_running() -> bool:
	return run_state == RunState.PLAYING


## `reset()` — restores a fresh run and rebuilds the row stack.
func reset(base_y: float, view_height: float, seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	lane = 0
	score = 0
	success_streak = 0
	step_timer = 0.0
	step_interval = START_INTERVAL_MS
	run_state = RunState.PLAYING
	rebuild_rows(base_y, view_height)


## `tap()` — one tap always flips the lane, with no lock and no queue.
func toggle_lane() -> void:
	if is_running():
		lane = 1 - lane


## Position inside the 24-note phrase for the landing that just happened.
func note_position() -> int:
	return posmod(success_streak - 1, NOTE_COUNT)


func choose_pattern() -> void:
	var pool: Array = LATE_PATTERNS
	if score < 20:
		pool = EARLY_PATTERNS
	elif score < 50:
		pool = MID_PATTERNS
	pattern = pool[_rng.randi_range(0, pool.size() - 1)]
	pattern_index = 0


func next_safe() -> int:
	if pattern_index >= pattern.size():
		choose_pattern()
	var safe_lane: int = pattern[pattern_index]
	pattern_index += 1
	return safe_lane


func make_row(y: float, safe_lane: int) -> Dictionary:
	var row := {"y": y, "safe_lane": safe_lane, "squash": -1.0, "resolved": false}
	rows.append(row)
	return row


func rebuild_rows(base_y: float, view_height: float) -> void:
	rows.clear()
	choose_pattern()
	# The bridge the run starts standing on. It is resolved from the outset so it
	# never decides a landing; it exists so the opening frame shows a cat on a
	# bridge rather than a cat hanging in open sky.
	make_row(base_y, lane).resolved = true
	for i in INITIAL_ROWS:
		make_row(base_y - float(i + 1) * ROW_SPACING, next_safe())
	# The prototype only builds seven rows, which leaves a bare strip at the top
	# of a tall screen until the first landing refills it.
	_recycle_rows(view_height)


## `nearestRow()` — index of the row whose anchor is closest to the player,
## ignoring rows that have already decided a landing.
func nearest_row_index(base_y: float) -> int:
	var best := -1
	var best_distance := INF
	for i in rows.size():
		if bool(rows[i].resolved):
			continue
		var distance: float = absf(float(rows[i].y) + ROW_ANCHOR - base_y)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


## Whether a jump to [param target_lane] would find a bridge under it right now.
## [param scroll] is how far the stack has already slid toward the player within
## the current beat, so this judges exactly what the player can see.
func can_cross(base_y: float, scroll: float, target_lane: int) -> bool:
	var index := nearest_row_index(base_y)
	if index < 0:
		return false
	if int(rows[index].safe_lane) != target_lane:
		return false
	# How far the arriving bridge still has to travel to be under the cat.
	# Negative once it has arrived, which is still a reachable jump.
	var remaining: float = base_y - (float(rows[index].y) + scroll)
	return remaining <= CROSS_REACH


## `resolveLanding()` — returns the landed row on success, or an empty
## dictionary when the run ends. The row is left in place; the stack only moves
## in [method advance_rows].
func resolve_landing(base_y: float) -> Dictionary:
	var index := nearest_row_index(base_y)
	if index < 0 or int(rows[index].safe_lane) != lane:
		run_state = RunState.DEAD
		return {}
	rows[index].resolved = true
	success_streak += 1
	score += 1
	step_interval = maxf(MIN_INTERVAL_MS, START_INTERVAL_MS * pow(SPEED_FACTOR, score))
	return rows[index]


## The delayed half of `resolveLanding()`: slide every row down one spacing,
## drop what fell past the bottom and refill the top.
func advance_rows(base_y: float, view_height: float) -> void:
	shift_rows(ROW_SPACING, base_y, view_height)


## Moves the whole stack by [param offset] and re-establishes the recycle
## window. Used by the per-landing slide and by a viewport resize, which shifts
## the player's height without ending the run.
func shift_rows(offset: float, base_y: float, view_height: float) -> void:
	for row in rows:
		row.y = float(row.y) + offset
	_recycle_rows(view_height, base_y)


func _recycle_rows(view_height: float, base_y: float = 0.0) -> void:
	var kept: Array[Dictionary] = []
	for row in rows:
		if float(row.y) <= view_height + RECYCLE_MARGIN:
			kept.append(row)
	rows = kept
	var min_y := INF
	for row in rows:
		min_y = minf(min_y, float(row.y))
	if min_y == INF:
		min_y = base_y
	while min_y > -RECYCLE_MARGIN:
		min_y -= ROW_SPACING
		make_row(min_y, next_safe())


## Current cadence in milliseconds. Monotonically non-increasing in `score`.
func cadence_ms() -> float:
	return step_interval


func current_zone() -> Dictionary:
	return ZoneConfig.for_score(score)
