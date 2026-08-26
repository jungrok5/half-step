extends SceneTree

var failures := 0

func _init() -> void:
	_test_initial_state()
	_test_tap_is_immediate()
	_test_same_lane_success()
	_test_wrong_lane_death()
	_test_speed_is_monotonic()
	_test_zone_boundaries()
	_test_note_loop()
	_test_retry()
	if failures == 0:
		print("PASS: all HALF STEP gameplay tests")
	quit(failures)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func state_with_lanes(lanes: Array[int]) -> HalfStepState:
	var state := HalfStepState.new(42)
	state.upcoming_lanes.assign(lanes)
	while state.upcoming_lanes.size() < 12:
		state.upcoming_lanes.append(0)
	return state

func _test_initial_state() -> void:
	var state := HalfStepState.new(1)
	expect(state.score == 0, "initial score is zero")
	expect(state.lane == HalfStepState.Lane.LEFT, "initial lane is left")

func _test_tap_is_immediate() -> void:
	var state := HalfStepState.new(1)
	state.toggle_lane()
	state.toggle_lane()
	state.toggle_lane()
	expect(state.lane == HalfStepState.Lane.RIGHT, "every tap toggles without a lock")

func _test_same_lane_success() -> void:
	var state := state_with_lanes([0, 0, 1])
	expect(state.resolve_landing(), "first left landing succeeds")
	expect(state.resolve_landing(), "consecutive left landing succeeds without input")
	expect(state.score == 2, "same-lane rows score independently")

func _test_wrong_lane_death() -> void:
	var state := state_with_lanes([1])
	expect(not state.resolve_landing(), "wrong lane fails")
	expect(state.run_state == HalfStepState.RunState.DEAD, "wrong lane enters dead state")

func _test_speed_is_monotonic() -> void:
	var previous := INF
	for score in range(0, 1201):
		var state := HalfStepState.new(1)
		state.score = score
		var current := state.cadence_ms()
		expect(current <= previous, "cadence never slows at score %d" % score)
		previous = current

func _test_zone_boundaries() -> void:
	var cases := {299: "AURORA EDGE", 300: "RED STRATOS", 399: "RED STRATOS", 400: "VOID CURRENT", 549: "VOID CURRENT", 550: "CHROMA STORM", 749: "CHROMA STORM", 750: "WHITE HORIZON", 999: "WHITE HORIZON", 1000: "BEYOND"}
	for score: int in cases:
		expect(ZoneConfig.for_score(score).name == cases[score], "zone boundary at %d" % score)

func _test_note_loop() -> void:
	var state := state_with_lanes([])
	for i in 24:
		state.upcoming_lanes[0] = state.lane
		expect(state.resolve_landing(), "note landing %d succeeds" % i)
	expect(state.note_index == 0, "24-note phrase loops")

func _test_retry() -> void:
	var state := state_with_lanes([1])
	state.resolve_landing()
	state.retry(2)
	expect(state.run_state == HalfStepState.RunState.PLAYING, "retry returns to playing")
	expect(state.score == 0 and state.note_index == 0, "retry resets transient run state")

