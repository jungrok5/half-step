extends SceneTree

## Drives the real scene frame by frame to check the prototype's step cycle:
## the hop resolves the landing, the row stack slides 50ms later, the cadence
## keeps tightening, and death leads to the result card half a second later.

const FRAME_MS := 16.0
const HOP_MS := 125.0
const SETTLE_MS := 50.0
const RESULT_DELAY_MS := 500.0

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


func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var state: HalfStepState = game.get("state")

	# One full cycle: the beat starts a hop, the hop resolves the landing.
	var first_row_y: float = float(state.rows[0].y)
	hold_safe_lane(game, state)
	var frames := int(ceil(state.step_interval / FRAME_MS)) + 1
	step_frames(game, frames)
	expect(state.stepping, "reaching the beat starts the hop")
	expect(state.score == 0, "the landing has not resolved while the player is airborne")
	expect(float(game.get("hop_time")) >= 0.0, "the hop animation is running")

	# The bridge has to be under the cat at the instant the landing resolves.
	# Judging it while it is still a full row overhead, then snapping it into
	# place afterwards, reads as passing through a gate rather than jumping onto
	# a bridge.
	var landing_row := state.rows[state.nearest_row_index(game.call("base_y"))]
	var landing_row_y := float(landing_row.y)
	step_frames(game, int(ceil(HOP_MS / FRAME_MS)) + 1)
	expect(state.score == 1, "the landing resolves when the hop finishes")
	var scroll: float = float(game.get("row_scroll"))
	expect(is_equal_approx(scroll, HalfStepState.ROW_SPACING),
		"the stack has slid a full row by the time the cat lands, got %d" % int(scroll))
	expect(is_equal_approx(landing_row_y + scroll, float(game.call("base_y"))),
		"the bridge just landed on is drawn at the cat, not overhead")
	expect(float(game.get("flow_time")) >= 0.0, "a successful landing shows FLOW")
	expect(is_equal_approx(float(state.rows[0].y), first_row_y), "the row stack has not moved yet")

	step_frames(game, int(ceil(SETTLE_MS / FRAME_MS)) + 1)
	expect(is_equal_approx(float(state.rows[0].y), first_row_y + HalfStepState.ROW_SPACING),
		"the row stack slides one spacing after the settle delay")
	expect(is_zero_approx(float(game.get("row_scroll"))),
		"the drawn offset resets once the rows themselves have moved")
	expect(is_equal_approx(float(state.rows[0].y), float(game.call("base_y"))),
		"nothing jumps on screen: the row lands exactly where it was already drawn")
	expect(not state.stepping, "the settle delay clears the stepping flag")

	# The cat must be on a bridge or in the air, never hovering over the gap
	# beside one. A tap commits the lane straight away, but the cat only crosses
	# when it jumps.
	var deck_half := 86.0 * 0.5
	var cat_half := 36.0 * 0.5
	var standing: int = int(game.get("standing_lane"))
	var deck_centre: float = float(game.call("tile_x", standing)) + deck_half
	expect(is_equal_approx(float(game.call("player_left")) + cat_half, deck_centre),
		"after landing the cat stands on the middle of its bridge")
	game.call("tap")
	expect(state.lane != standing, "the tap commits the other lane immediately")
	step_frames(game, 20)
	var leaning: float = float(game.call("player_left")) + cat_half
	expect(absf(leaning - deck_centre) <= deck_half - cat_half,
		"while grounded the cat leans but stays on its own deck, off by %d" % int(absf(leaning - deck_centre)))
	expect(not is_equal_approx(leaning, float(game.call("tile_x", state.lane)) + deck_half),
		"the cat has not moved across to hover over the empty lane")
	# Ride the next landing out and it should be centred on the other bridge.
	var before := state.score
	var guard_cross := 0
	while state.score == before and guard_cross < 400:
		hold_safe_lane(game, state)
		step_frames(game, 1)
		guard_cross += 1
	step_frames(game, int(ceil(SETTLE_MS / FRAME_MS)) + 1)
	expect(int(game.get("standing_lane")) == state.lane, "the leap leaves the cat standing on the new lane")
	expect(is_equal_approx(float(game.call("player_left")) + cat_half,
		float(game.call("tile_x", state.lane)) + deck_half),
		"and centred on that bridge")

	# Twenty more landings: the score climbs and the cadence only tightens.
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
	expect(state.score == score_before_streak + 20, "twenty more landings scored")
	expect(state.success_streak == streak_before + 20, "the melody advanced once per landing")
	expect(state.is_running(), "the run survives a clean streak")

	# Missing the platform ends the run at the player's own position.
	var lane_before := state.lane
	var guard := 0
	while state.is_running() and guard < 400:
		var index: int = state.nearest_row_index(game.call("base_y"))
		if index >= 0:
			state.rows[index].safe_lane = 1 - state.lane
		step_frames(game, 1)
		guard += 1
	expect(not state.is_running(), "landing on the wrong lane ends the run")
	expect(state.lane == lane_before, "death does not move the player to another lane")
	expect(float(game.get("death_time")) >= 0.0, "the fall animation starts")

	# The result card only appears after the prototype's 500ms delay.
	expect(float(game.get("death_time")) < RESULT_DELAY_MS, "the card is not up yet")
	step_frames(game, int(ceil(RESULT_DELAY_MS / FRAME_MS)) + 2)
	expect(float(game.get("death_time")) >= RESULT_DELAY_MS, "the card appears half a second after the fall")
	var layout: Dictionary = game.call("result_layout")
	expect(Rect2(layout.retry).size.x > 0.0 and Rect2(layout.share).size.x > 0.0, "the card exposes both buttons")

	# The hop plus the settle is 175ms in the prototype, which becomes a hard
	# speed ceiling from roughly score 322 onward. The cycle now compresses so
	# the cadence stays in charge all the way to the 24ms floor.
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
			expect(period < HOP_MS + SETTLE_MS,
				"score %d beats the prototype's 175ms animation ceiling (measured %dms)" % [score, int(period)])
		expect(state.is_running(), "the run survives at score %d" % score)

	root.remove_child(game)
	game.free()
	if failures == 0:
		print("PASS: HALF STEP step cycle matches the prototype")
	quit(failures)
