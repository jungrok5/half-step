extends SceneTree

## Deterministic gameplay tests plus a parity check against the HTML prototype.

const PROTOTYPE := "res://reference/web-prototypes/half_step_pixel_skin.html"
const VIEW_HEIGHT := 844.0

var failures := 0
var _source := ""


func _init() -> void:
	_source = FileAccess.get_file_as_string(PROTOTYPE)
	_test_prototype_is_readable()
	_test_initial_state()
	_test_row_stack_matches_rebuild_rows()
	_test_each_row_decides_one_landing()
	_test_tap_is_immediate()
	_test_nearest_row_resolves_landing()
	_test_same_lane_success()
	_test_wrong_lane_death()
	_test_speed_matches_prototype_curve()
	_test_speed_is_monotonic()
	_test_row_recycling()
	_test_resize_keeps_the_run()
	_test_pattern_pools()
	_test_zone_table_matches_prototype()
	_test_zone_boundaries()
	_test_secret_milestones()
	_test_share_card_tags()
	_test_note_scale()
	_test_reset()
	_test_layout_constants_match_prototype()
	if failures == 0:
		print("PASS: all HALF STEP gameplay tests")
	quit(failures)


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


func expect_contains(needle: String, message: String) -> void:
	expect(_source.contains(needle), message + " (missing from prototype: %s)" % needle)


func playing_state(base_y: float = 600.0) -> HalfStepState:
	var state := HalfStepState.new(7)
	state.reset(base_y, VIEW_HEIGHT)
	return state


## Forces the row nearest the player onto [param lane] so landings are scripted.
func force_next_safe_lane(state: HalfStepState, base_y: float, lane: int) -> void:
	state.rows[state.nearest_row_index(base_y)].safe_lane = lane


func _test_prototype_is_readable() -> void:
	expect(not _source.is_empty(), "the pixel skin prototype is readable from res://")


func _test_initial_state() -> void:
	var state := playing_state()
	expect(state.score == 0, "initial score is zero")
	expect(state.lane == HalfStepState.Lane.LEFT, "initial lane is left")
	expect(is_equal_approx(state.step_interval, 560.0), "initial cadence is 560ms")
	expect(state.success_streak == 0, "initial streak is zero")


func _test_row_stack_matches_rebuild_rows() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	expect(state.rows.size() >= 8, "rebuildRows() builds the prototype's seven rows plus the starting bridge")
	expect(is_equal_approx(float(state.rows[0].y), base_y),
		"the run opens standing on a bridge instead of on open sky")
	expect(bool(state.rows[0].resolved), "the starting bridge never decides a landing")
	for i in 7:
		expect(is_equal_approx(float(state.rows[i + 1].y), base_y - float(i + 1) * 92.0),
			"row %d sits at baseY - %d*92" % [i, i + 1])
	var highest := INF
	for row in state.rows:
		highest = minf(highest, float(row.y))
	expect(highest <= -HalfStepState.RECYCLE_MARGIN,
		"the opening stack already reaches the top of the screen")


## Regression test for the prototype's double-judged first row: there, the row
## just landed on stays eligible and sits 14px from the player after the slide,
## so it wins `nearestRow()` again and `pattern[0]` is forced twice.
func _test_each_row_decides_one_landing() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	var expected := HalfStepState.ROW_SPACING - HalfStepState.ROW_ANCHOR
	for i in 6:
		var index := state.nearest_row_index(base_y)
		expect(index >= 0, "landing %d has a row to judge" % i)
		if index < 0:
			return
		expect(not bool(state.rows[index].resolved), "landing %d judges an unused row" % i)
		var distance: float = absf(float(state.rows[index].y) + HalfStepState.ROW_ANCHOR - base_y)
		expect(is_equal_approx(distance, expected),
			"landing %d judges a fresh row %dpx above the player, not the one just used" % [i, int(expected)])
		state.lane = int(state.rows[index].safe_lane)
		expect(not state.resolve_landing(base_y).is_empty(), "landing %d succeeds" % i)
		state.advance_rows(base_y, VIEW_HEIGHT)


func _test_tap_is_immediate() -> void:
	var state := playing_state()
	for i in 5:
		var before := state.lane
		state.toggle_lane()
		expect(state.lane != before, "tap %d toggles without a lock" % i)


func _test_nearest_row_resolves_landing() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	# The prototype compares `r.y + 14` against baseY, so the lowest unresolved
	# row wins. Row 0 is the starting bridge, which is resolved from the outset.
	expect(state.nearest_row_index(base_y) == 1, "nearest row is the one closest to the player")
	state.rows[1].y = base_y + 500.0
	expect(state.nearest_row_index(base_y) == 2, "a row that slid far below is no longer nearest")
	state.rows[2].resolved = true
	expect(state.nearest_row_index(base_y) == 3, "a row that already decided a landing is skipped")


func _test_same_lane_success() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	for i in 3:
		force_next_safe_lane(state, base_y, state.lane)
		expect(not state.resolve_landing(base_y).is_empty(), "same-lane landing %d succeeds" % i)
		state.advance_rows(base_y, 844.0)
	expect(state.score == 3, "three consecutive same-lane landings score three")


func _test_wrong_lane_death() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	force_next_safe_lane(state, base_y, 1 - state.lane)
	expect(state.resolve_landing(base_y).is_empty(), "wrong lane fails")
	expect(state.run_state == HalfStepState.RunState.DEAD, "wrong lane ends the run")
	expect(not state.is_running(), "death stops the run")


func _test_speed_matches_prototype_curve() -> void:
	expect_contains("stepInterval=Math.max(24,560*Math.pow(.9964,score))",
		"cadence formula is the prototype's")
	var state := playing_state()
	for score: int in [0, 1, 100, 200, 300, 400, 1000, 5000]:
		state.score = score
		state.step_interval = maxf(24.0, 560.0 * pow(0.9964, float(score)))
		var expected: float = maxf(24.0, 560.0 * pow(0.9964, float(score)))
		expect(is_equal_approx(state.cadence_ms(), expected), "cadence at %d matches" % score)
	# The intent documented in AGENTS.md section 7.
	expect(absf(560.0 * pow(0.9964, 100.0) - 390.0) < 12.0, "~390ms near score 100")
	expect(absf(560.0 * pow(0.9964, 400.0) - 130.0) < 12.0, "~130ms near score 400")


func _test_speed_is_monotonic() -> void:
	var previous := INF
	for score in range(0, 1501):
		var current := maxf(HalfStepState.MIN_INTERVAL_MS, 560.0 * pow(0.9964, float(score)))
		expect(current <= previous, "cadence never slows at score %d" % score)
		previous = current


func _test_row_recycling() -> void:
	var base_y := 600.0
	var view_height := 844.0
	var state := playing_state(base_y)
	var lowest := float(state.rows[0].y)
	state.advance_rows(base_y, view_height)
	expect(is_equal_approx(float(state.rows[0].y), lowest + 92.0), "rows slide down one spacing")
	var highest := INF
	for row in state.rows:
		highest = minf(highest, float(row.y))
		expect(float(row.y) <= view_height + 100.0, "rows past the bottom margin are dropped")
	expect(highest <= -100.0, "the stack is refilled above the top margin")
	for _i in 60:
		state.advance_rows(base_y, view_height)
	expect(state.rows.size() < 20, "the row stack stays bounded while scrolling")


## The prototype calls `reset()` on any resize, so a phone browser hiding its
## address bar ends the run. The stack is re-laid out around the new player
## height instead.
func _test_resize_keeps_the_run() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	force_next_safe_lane(state, base_y, state.lane)
	state.resolve_landing(base_y)
	state.advance_rows(base_y, VIEW_HEIGHT)
	var score_before := state.score
	var index := state.nearest_row_index(base_y)
	var gap_before: float = float(state.rows[index].y) - base_y
	var taller_base_y := 671.0
	state.shift_rows(taller_base_y - base_y, taller_base_y, 932.0)
	expect(state.score == score_before, "a resize does not end the run")
	expect(state.is_running(), "a resize does not end the run")
	var moved := state.nearest_row_index(taller_base_y)
	expect(is_equal_approx(float(state.rows[moved].y) - taller_base_y, gap_before),
		"the next row keeps its distance to the player across a resize")


func _test_pattern_pools() -> void:
	expect(HalfStepState.EARLY_PATTERNS.size() == 4, "four early patterns below score 20")
	expect(HalfStepState.MID_PATTERNS.size() == 6, "six mid patterns below score 50")
	expect(HalfStepState.LATE_PATTERNS.size() == 6, "six late patterns from score 50")
	expect(HalfStepState.MID_PATTERNS.has([0, 0, 1, 1]) and HalfStepState.MID_PATTERNS.has([1, 1, 0, 0]),
		"the mid pool keeps the two double-step patterns the prototype reuses")
	for pool: Array in [HalfStepState.EARLY_PATTERNS, HalfStepState.MID_PATTERNS, HalfStepState.LATE_PATTERNS]:
		for pattern: Array in pool:
			for lane: int in pattern:
				expect(lane == 0 or lane == 1, "patterns only contain lanes 0 and 1")
	var state := playing_state()
	state.score = 0
	state.choose_pattern()
	expect(HalfStepState.EARLY_PATTERNS.has(state.pattern), "score 0 draws from the early pool")
	state.score = 20
	state.choose_pattern()
	expect(HalfStepState.MID_PATTERNS.has(state.pattern), "score 20 draws from the mid pool")
	state.score = 50
	state.choose_pattern()
	expect(HalfStepState.LATE_PATTERNS.has(state.pattern), "score 50 draws from the late pool")


func _test_zone_table_matches_prototype() -> void:
	var head := RegEx.create_from_string("\\{score:(\\d+),name:'([^']+)',top:'#([0-9a-fA-F]{6})',bottom:'#([0-9a-fA-F]{6})'")
	var tail := RegEx.create_from_string("stars:([\\d.]+),scan:([\\d.]+),boost:([\\d.]+),shareLine:'([^']+)'")
	var heads := head.search_all(_source)
	var tails := tail.search_all(_source)
	expect(heads.size() == ZoneConfig.ZONES.size(), "the prototype still declares %d zones" % ZoneConfig.ZONES.size())
	expect(tails.size() == heads.size(), "every prototype zone has stars/scan/boost/shareLine")
	if heads.size() != ZoneConfig.ZONES.size() or tails.size() != heads.size():
		return
	for i in heads.size():
		var zone: Dictionary = ZoneConfig.ZONES[i]
		expect(int(heads[i].get_string(1)) == int(zone.score), "zone %d score matches" % i)
		expect(heads[i].get_string(2) == String(zone.name), "zone %d name matches" % i)
		expect(Color(heads[i].get_string(3)).is_equal_approx(zone.top), "zone %d sky top matches" % i)
		expect(Color(heads[i].get_string(4)).is_equal_approx(zone.bottom), "zone %d sky bottom matches" % i)
		expect(is_equal_approx(float(tails[i].get_string(1)), float(zone.stars)), "zone %d star opacity matches" % i)
		expect(is_equal_approx(float(tails[i].get_string(2)), float(zone.scan)), "zone %d scanline opacity matches" % i)
		expect(is_equal_approx(float(tails[i].get_string(3)), float(zone.boost)), "zone %d speed boost matches" % i)
		expect(tails[i].get_string(4) == String(zone.share_line), "zone %d share line matches" % i)


func _test_zone_boundaries() -> void:
	var cases := {
		0: "BLUE SKY", 29: "BLUE SKY", 30: "GOLDEN WIND", 299: "AURORA EDGE", 300: "RED STRATOS",
		399: "RED STRATOS", 400: "VOID CURRENT", 549: "VOID CURRENT", 550: "CHROMA STORM",
		749: "CHROMA STORM", 750: "WHITE HORIZON", 999: "WHITE HORIZON", 1000: "BEYOND", 99999: "BEYOND",
	}
	for score: int in cases:
		expect(String(ZoneConfig.for_score(score).name) == cases[score], "zone boundary at %d" % score)


func _test_secret_milestones() -> void:
	expect(ZoneConfig.milestone_for_score(299).is_empty(), "ordinary scores reveal no secret text")
	expect(ZoneConfig.milestone_for_score(300) == "YOU SHOULD NOT BE HERE", "300 milestone matches prototype")
	expect(ZoneConfig.milestone_for_score(400) == "THE SKY IS GONE", "400 milestone matches prototype")
	expect(ZoneConfig.milestone_for_score(550) == "KEEP GOING", "550 milestone matches prototype")
	expect(ZoneConfig.milestone_for_score(750) == "NO ONE WAS SUPPOSED TO SEE THIS", "750 milestone matches prototype")
	expect(ZoneConfig.milestone_for_score(1000) == "BEYOND", "1000 milestone matches prototype")
	for score: int in ZoneConfig.MILESTONES:
		expect_contains("%d:'%s'" % [score, ZoneConfig.MILESTONES[score]], "milestone %d is the prototype's" % score)


func _test_share_card_tags() -> void:
	expect(ZoneConfig.milestone_tag_for_score(0) == "CAN YOU REACH THIS SKY?", "default share tag")
	expect(ZoneConfig.milestone_tag_for_score(150) == "KEEP CLIMBING", "150 share tag")
	expect(ZoneConfig.milestone_tag_for_score(300) == "YOU SHOULD NOT BE HERE", "300 share tag")
	expect(ZoneConfig.milestone_tag_for_score(400) == "THE SKY IS GONE", "400 share tag")
	expect(ZoneConfig.milestone_tag_for_score(550) == "THE SKY CHANGED", "550 share tag")
	expect(ZoneConfig.milestone_tag_for_score(750) == "WHITE HORIZON REACHED", "750 share tag")
	expect(ZoneConfig.milestone_tag_for_score(1000) == "NO ONE WAS SUPPOSED TO SEE THIS", "1000 share tag")


func _test_note_scale() -> void:
	expect_contains("const scale=[0,2,4,5,7,9,11,12]", "major scale is the prototype's")
	expect_contains("const base=260", "root note is 260Hz")
	expect_contains("const phraseLen=24", "phrase is 24 notes")
	expect(is_equal_approx(TonePlayer.note_frequency(0), 260.0), "phrase starts on the root")
	expect(is_equal_approx(TonePlayer.note_frequency(8), 520.0), "the phrase climbs an octave every eight notes")
	expect(is_equal_approx(TonePlayer.note_frequency(16), 1040.0), "third octave doubles again")
	expect(is_equal_approx(TonePlayer.note_frequency(24), TonePlayer.note_frequency(0)),
		"the phrase restarts in the low register after 24 notes")
	var state := playing_state()
	state.success_streak = 1
	expect(state.note_position() == 0, "the first landing plays the root")
	state.success_streak = 25
	expect(state.note_position() == 0, "the 25th landing wraps to the root")


func _test_reset() -> void:
	var base_y := 600.0
	var state := playing_state(base_y)
	force_next_safe_lane(state, base_y, 1 - state.lane)
	state.resolve_landing(base_y)
	state.reset(base_y, VIEW_HEIGHT, 3)
	expect(state.run_state == HalfStepState.RunState.PLAYING, "retry returns to playing")
	expect(state.score == 0 and state.success_streak == 0, "retry clears the run")
	expect(is_equal_approx(state.step_interval, 560.0), "retry restores the opening cadence")
	expect(state.lane == HalfStepState.Lane.LEFT, "retry starts on the left lane")
	expect(state.rows.size() >= 8, "retry rebuilds the row stack")
	for i in range(1, state.rows.size()):
		expect(not bool(state.rows[i].resolved), "retry clears the resolved rows")


func _test_layout_constants_match_prototype() -> void:
	expect_contains("game.clientWidth/2 + (l?70:-70) - 18", "lane offset is 70px")
	expect_contains("game.clientHeight*.72", "the player rides at 72% height")
	expect_contains("makeRow(py-(i+1)*92", "row spacing is 92px")
	expect_contains("for(let i=0;i<7;i++) makeRow", "seven rows are built")
	expect_contains("Math.abs(r.y+14-py)", "landing uses the nearest row anchor")
	expect_contains("r.y>h+100", "rows recycle past the bottom margin")
	expect_contains("while(minY>-100)", "rows refill above the top margin")
	expect(is_equal_approx(HalfStepState.ROW_SPACING, 92.0), "ROW_SPACING is 92")
	expect(is_equal_approx(HalfStepState.ROW_ANCHOR, 14.0), "ROW_ANCHOR is 14")
	expect(HalfStepState.INITIAL_ROWS == 7, "INITIAL_ROWS is 7")
