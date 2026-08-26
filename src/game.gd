extends Node2D

const VIEW := Vector2(720.0, 1280.0)
const LANE_X := [245.0, 475.0]
const PLAYER_Y := 950.0
const ROW_SPACING := 190.0
const PLATFORM_SIZE := Vector2(150.0, 38.0)

var state := HalfStepState.new(Time.get_ticks_usec())
var tone_player: TonePlayer
var cadence_elapsed_ms := 0.0
var impact_time := 0.0
var death_time := 0.0
var zone_reveal_time := 0.0
var previous_zone := ""
var best_score := 0

func _ready() -> void:
	tone_player = TonePlayer.new()
	add_child(tone_player)
	best_score = int(ProjectSettings.get_setting("half_step/best_score", 0))
	state.best_score = best_score
	previous_zone = str(state.current_zone().name)
	set_process(true)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap()
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_tap()

func _handle_tap() -> void:
	if state.run_state == HalfStepState.RunState.DEAD:
		_restart()
	else:
		state.toggle_lane()
	queue_redraw()

func _process(delta: float) -> void:
	if state.run_state == HalfStepState.RunState.PLAYING:
		cadence_elapsed_ms += delta * 1000.0
		while cadence_elapsed_ms >= state.cadence_ms() and state.run_state == HalfStepState.RunState.PLAYING:
			cadence_elapsed_ms -= state.cadence_ms()
			_resolve_step()
	else:
		death_time += delta
	impact_time = maxf(0.0, impact_time - delta)
	zone_reveal_time = maxf(0.0, zone_reveal_time - delta)
	queue_redraw()

func _resolve_step() -> void:
	var success := state.resolve_landing()
	if success:
		impact_time = 0.15
		tone_player.play_success_note(state.note_index if state.note_index > 0 else 24)
		if state.best_score > best_score:
			best_score = state.best_score
			ProjectSettings.set_setting("half_step/best_score", best_score)
		var zone_name := str(state.current_zone().name)
		if zone_name != previous_zone:
			previous_zone = zone_name
			zone_reveal_time = 2.0
	else:
		death_time = 0.0
		tone_player.play_fall()

func _restart() -> void:
	state.retry(Time.get_ticks_usec())
	state.best_score = best_score
	cadence_elapsed_ms = 0.0
	impact_time = 0.0
	death_time = 0.0
	previous_zone = str(state.current_zone().name)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_clouds()
	_draw_platform_rows()
	_draw_player()
	_draw_hud()
	if state.run_state == HalfStepState.RunState.DEAD:
		_draw_result()

func _draw_sky() -> void:
	var zone := state.current_zone()
	for band in 32:
		var t := float(band) / 31.0
		var color: Color = zone.top.lerp(zone.bottom, t)
		draw_rect(Rect2(0, band * VIEW.y / 32.0, VIEW.x, VIEW.y / 32.0 + 1.0), color)

func _draw_clouds() -> void:
	var progress := cadence_elapsed_ms / state.cadence_ms()
	var speed := 35.0 + state.score * 0.7
	for i in 14:
		var y := fmod(i * 113.0 + progress * speed * 4.0, VIEW.y + 180.0) - 90.0
		var x: float = 70.0 + fmod(i * 173.0, 590.0)
		var radius := 18.0 + (i % 4) * 9.0
		var alpha := 0.10 + (i % 3) * 0.04
		draw_circle(Vector2(x, y), radius, Color(1, 1, 1, alpha))
		draw_circle(Vector2(x + radius, y + 4), radius * 0.72, Color(1, 1, 1, alpha))
	if state.score >= 30:
		for i in mini(28, state.score / 8):
			var x: float = fmod(i * 97.0, VIEW.x)
			var y: float = fmod(i * 151.0 + progress * speed * 9.0, VIEW.y)
			draw_line(Vector2(x, y), Vector2(x, y + 25.0 + state.score * 0.08), Color(1, 1, 1, 0.24), 3.0)

func _draw_platform_rows() -> void:
	var progress := cadence_elapsed_ms / state.cadence_ms()
	for row_index in 6:
		var safe_lane: int = state.upcoming_lanes[row_index]
		var y := PLAYER_Y - ROW_SPACING + row_index * -ROW_SPACING + progress * ROW_SPACING
		for lane_index in 2:
			if lane_index != safe_lane:
				continue
			var rect := Rect2(LANE_X[lane_index] - PLATFORM_SIZE.x * 0.5, y, PLATFORM_SIZE.x, PLATFORM_SIZE.y)
			draw_rect(rect, Color("273142"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), Color("9bc7d3"))
			draw_rect(Rect2(rect.position + Vector2(12, 15), Vector2(rect.size.x - 24, 6)), Color("3f5064"))
	if impact_time > 0.0:
		var t := 1.0 - impact_time / 0.15
		var grow := 1.0 + t * 0.18
		var size := PLATFORM_SIZE * grow
		var rect := Rect2(Vector2(LANE_X[state.lane], PLAYER_Y + 35.0) - size * 0.5, size)
		draw_rect(rect, Color(0.65, 0.9, 1.0, (1.0 - t) * 0.45), false, 4.0)

func _draw_player() -> void:
	var x: float = LANE_X[state.lane]
	var y: float = PLAYER_Y
	var scale_factor := 1.0
	var alpha := 1.0
	if state.run_state == HalfStepState.RunState.DEAD:
		var t := clampf(death_time / 0.65, 0.0, 1.0)
		scale_factor = lerpf(1.0, 0.08, t)
		alpha = 1.0 - t
	var body := Color(1.0, 0.35, 0.30, alpha)
	draw_rect(Rect2(Vector2(x - 28 * scale_factor, y - 62 * scale_factor), Vector2(56, 58) * scale_factor), body)
	draw_rect(Rect2(Vector2(x - 19 * scale_factor, y - 52 * scale_factor), Vector2(10, 14) * scale_factor), Color(1, 1, 1, alpha))
	draw_rect(Rect2(Vector2(x + 9 * scale_factor, y - 52 * scale_factor), Vector2(10, 14) * scale_factor), Color(1, 1, 1, alpha))

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 105), str(state.score), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 72, Color.WHITE)
	draw_string(font, Vector2(0, 150), "BEST %d" % best_score, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 24, Color(1, 1, 1, 0.72))
	if zone_reveal_time > 0.0:
		draw_string(font, Vector2(0, 300), str(state.current_zone().name), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 30, Color.WHITE)

func _draw_result() -> void:
	if death_time < 0.45:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(70, 360, 580, 430), Color(0.02, 0.04, 0.09, 0.88))
	draw_string(font, Vector2(0, 445), "HALF STEP", HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 34, Color.WHITE)
	draw_string(font, Vector2(0, 565), str(state.score), HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 96, Color.WHITE)
	draw_string(font, Vector2(0, 625), "REACHED · %s" % state.current_zone().name, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 24, Color("9bc7d3"))
	draw_string(font, Vector2(0, 720), "TAP TO RETRY", HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, 30, Color.WHITE)
