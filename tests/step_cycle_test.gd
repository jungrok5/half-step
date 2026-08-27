extends SceneTree

## Drives the real scene frame by frame to check the beat the game runs on:
## the bridge stack slides continuously toward the cat, the beat resolves the
## landing the instant a bridge arrives, a tap is a jump that only reaches a
## bridge already within range, the cadence keeps tightening, and death leads to
## the result card half a second later.

const FRAME_MS := 16.0
const RESULT_DELAY_MS := 500.0
## The prototype's hop+settle pair (125+50ms) capped its cadence at 175ms per
## step from roughly score 322 on. Nothing here may reintroduce that floor.
const PROTOTYPE_ANIMATION_FLOOR_MS := 175.0

var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


func step_frames(game: Node, count: int) -> void:
	for _i in count:
		game.call("_process", FRAME_MS / 1000.0)


## Runs the world forward in fine steps until the current beat is [param phase]
## of the way through, without letting it resolve.
func advance_to_phase(game: Node, state: HalfStepState, phase: float) -> void:
	var guard := 0
	while state.step_timer < state.step_interval * phase and guard < 4000:
		game.call("_process", 1.0 / 1000.0)
		guard += 1


## Average milliseconds between landings, measured on the real scene.
func measure_landing_period(game: Node, state: HalfStepState, landings: int) -> float:
	var dt := 2.0
	var elapsed := 0.0
	var first := -1.0
	var seen := 0
	var guard := 0
	var start_score := state.score
	while seen < landings and guard < 40000:
		hold_safe_lane(game, state)
		game.call("_process", dt / 1000.0)
		elapsed += dt
		guard += 1
		if state.score > start_score + seen:
			seen += 1
			if first < 0.0:
				first = elapsed
	if seen < landings:
		return INF
	return (elapsed - first) / float(landings - 1)


## Keeps the row the player is about to reach under the player's own lane.
func hold_safe_lane(game: Node, state: HalfStepState) -> void:
	var index: int = state.nearest_row_index(game.call("base_y"))
	if index >= 0:
		state.rows[index].safe_lane = state.lane


## Puts the bridge the cat is about to reach on [param lane].
func aim_next_row(game: Node, state: HalfStepState, lane: int) -> void:
	var index: int = state.nearest_row_index(game.call("base_y"))
	if index >= 0:
		state.rows[index].safe_lane = lane


## Runs until the leap in the air has decided the run: either the cat falls or
## the beat resolves a landing.
func settle_leap(game: Node, state: HalfStepState) -> void:
	var scored := state.score
	var guard := 0
	while state.is_running() and state.score == scored and guard < 400:
		step_frames(game, 1)
		guard += 1


func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var state: HalfStepState = game.get("state")

	# The world scrolls across the whole beat, so the player can see the next
	# bridge closing in and time a jump against it. Judging the landing while
	# the bridge is still a full row overhead and then snapping it into place
	# afterwards read as passing through a gate rather than jumping onto a deck.
	var first_row_y: float = float(state.rows[0].y)
	hold_safe_lane(game, state)
	advance_to_phase(game, state, 0.5)
	var mid_scroll: float = float(game.get("row_scroll"))
	expect(state.score == 0, "the landing has not resolved mid-beat")
	expect(absf(mid_scroll - HalfStepState.ROW_SPACING * 0.5) < 4.0,
		"half a beat in, the stack has slid half a row, got %d" % int(mid_scroll))
	expect(is_equal_approx(float(state.rows[0].y), first_row_y), "the rows themselves have not moved yet")

	# The bridge has to be under the cat at the instant the landing resolves.
	var landing_row := state.rows[state.nearest_row_index(game.call("base_y"))]
	var landing_row_y := float(landing_row.y)
	settle_leap(game, state)
	expect(state.score == 1, "the beat resolves the landing")
	expect(is_equal_approx(float(state.rows[0].y), first_row_y + HalfStepState.ROW_SPACING),
		"the row stack slides one spacing on the landing")
	expect(is_equal_approx(landing_row_y + HalfStepState.ROW_SPACING, float(game.call("base_y"))),
		"the bridge just landed on is drawn at the cat, not overhead")
	expect(float(game.get("row_scroll")) < HalfStepState.ROW_SPACING * 0.25,
		"the drawn offset restarts once the rows themselves have moved")
	expect(float(game.get("flow_time")) >= 0.0, "a successful landing shows FLOW")

	# A tap is a jump, not a lane setting. Leaving early means jumping at a
	# bridge that has not arrived, and there is nothing under the cat when it
	# comes down.
	game.call("reset")
	aim_next_row(game, state, 1 - state.lane)
	advance_to_phase(game, state, 0.2)
	expect(not state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane),
		"the far side is out of reach early in the beat")
	game.call("tap")
	expect(state.is_running(), "the cat is still in the air right after the tap")
	settle_leap(game, state)
	expect(not state.is_running(), "jumping before the bridge arrives drops the cat")

	# The same jump, made once the bridge is close, lands on it.
	game.call("reset")
	aim_next_row(game, state, 1 - state.lane)
	advance_to_phase(game, state, 0.7)
	expect(state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane),
		"the far side is in reach late in the beat")
	game.call("tap")
	settle_leap(game, state)
	expect(state.is_running(), "a jump made once the bridge is close lands on it")
	expect(state.score >= 1, "and scores")

	# The window opens exactly at the midpoint of the beat, whatever the cadence.
	for interval: float in [560.0, 240.0, 90.0]:
		game.call("reset")
		state.step_interval = interval
		aim_next_row(game, state, 1 - state.lane)
		advance_to_phase(game, state, 0.45)
		expect(not state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane),
			"at %dms the far side is still out of reach before the midpoint" % int(interval))
		advance_to_phase(game, state, 0.55)
		expect(state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane),
			"at %dms the far side is in reach past the midpoint" % int(interval))

	# Timing alone is not enough: the jump has to be toward a bridge.
	game.call("reset")
	aim_next_row(game, state, state.lane)
	advance_to_phase(game, state, 0.8)
	expect(not state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane),
		"an empty lane is never in reach")
	game.call("tap")
	settle_leap(game, state)
	expect(not state.is_running(), "jumping to a lane with no bridge drops the cat")

	# Tapping twice is two jumps, not an undo: the second one leaves the bridge.
	game.call("reset")
	aim_next_row(game, state, 1 - state.lane)
	advance_to_phase(game, state, 0.7)
	game.call("tap")
	game.call("tap")
	settle_leap(game, state)
	expect(not state.is_running(), "a second tap jumps back off the bridge rather than undoing the first")

	# Twenty landings without a tap: the score climbs and the cadence only
	# tightens. Staying in lane is a valid, deliberate way to survive.
	game.call("reset")
	var score_before_streak := state.score
	var streak_before := state.success_streak
	var previous_interval := state.step_interval
	for i in 20:
		var guard := 0
		var score_before := state.score
		while state.score == score_before and guard < 400:
			hold_safe_lane(game, state)
			step_frames(game, 1)
			guard += 1
		expect(state.score == score_before + 1, "landing %d resolves" % i)
		expect(state.step_interval <= previous_interval, "the cadence never slows at landing %d" % i)
		previous_interval = state.step_interval
	expect(state.score == score_before_streak + 20, "twenty landings scored")
	expect(state.success_streak == streak_before + 20, "the melody advanced once per landing")
	expect(state.is_running(), "the run survives a clean streak")

	# Missing the platform ends the run at the player's own position.
	var lane_before := state.lane
	var guard := 0
	while state.is_running() and guard < 400:
		aim_next_row(game, state, 1 - state.lane)
		step_frames(game, 1)
		guard += 1
	expect(not state.is_running(), "standing still while the bridge arrives on the far lane ends the run")
	expect(state.lane == lane_before, "death does not move the player to another lane")
	expect(float(game.get("death_time")) >= 0.0, "the fall animation starts")

	# The result card only appears after the prototype's 500ms delay.
	expect(float(game.get("death_time")) < RESULT_DELAY_MS, "the card is not up yet")
	step_frames(game, int(ceil(RESULT_DELAY_MS / FRAME_MS)) + 2)
	expect(float(game.get("death_time")) >= RESULT_DELAY_MS, "the card appears half a second after the fall")
	var layout: Dictionary = game.call("result_layout")
	expect(Rect2(layout.retry).size.x > 0.0 and Rect2(layout.share).size.x > 0.0, "the card exposes both buttons")

	# The cadence stays in charge all the way to the 24ms floor.
	game.call("reset")
	for score: int in [40, 600, 1200]:
		state.score = score
		state.step_interval = maxf(HalfStepState.MIN_INTERVAL_MS, 560.0 * pow(HalfStepState.SPEED_FACTOR, float(score)))
		state.step_timer = 0.0
		var target := state.step_interval
		var period := measure_landing_period(game, state, 6)
		expect(period < target * 1.35 + 8.0,
			"score %d steps near its %dms cadence, measured %dms" % [score, int(target), int(period)])
		if score >= 600:
			expect(period < PROTOTYPE_ANIMATION_FLOOR_MS,
				"score %d beats the prototype's 175ms animation ceiling (measured %dms)" % [score, int(period)])
		expect(state.is_running(), "the run survives at score %d" % score)

	root.remove_child(game)
	game.free()
	if failures == 0:
		print("PASS: HALF STEP beat and jump timing")
	quit(failures)
