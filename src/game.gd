extends Node2D

## HALF STEP — Godot port of `reference/web-prototypes/half_step_pixel_skin.html`.
##
## The prototype lays the game out in CSS pixels inside a `#game` element that is
## `min(100%, 520px)` wide and as tall as the viewport, so this scene works in the
## same units: the project's stretch settings keep the viewport 390 units wide and
## let the height follow the device aspect, exactly like the browser does on a
## 390 CSS px phone. Every constant below is the prototype's own number.

const GAME_MAX_WIDTH := 520.0
## `html,body{background:#7fc1ff}` — visible beside the game on wide viewports.
const PAGE_BACKGROUND := Color("7fc1ff")
## `baseY()` and `laneX()`.
const BASE_Y_RATIO := 0.72
const LANE_OFFSET := 70.0
const PLAYER_BOX := 36.0
## `.tile`, `.tile-wrap` and the `gap` between them.
const TILE_SIZE := Vector2(86.0, 28.0)
const TILE_GAP := 54.0
const TILE_WRAP_HEIGHT := 36.0

## The hop resolves the landing and the settle slides the row stack, so their
## sum is a floor on how fast the game can actually step. In the prototype that
## floor (175ms) is reached around score 322 and the run stops accelerating
## there, which contradicts the monotonic speed curve in AGENTS.md section 7.
## Past that point both are compressed so the cadence stays in charge.
const HOP_MS := 125.0
const SETTLE_MS := 50.0
const STEP_CYCLE_MS := HOP_MS + SETTLE_MS
## How long the cat takes to shift its weight toward the lane it has committed
## to. It stays on its own bridge while it does.
const LANE_MS := 110.0
## How far it leans, small enough that all four paws stay on the 86px deck.
const LEAN_DISTANCE := 20.0
const PLAYER_SQUASH_MS := 130.0
const TILE_SQUASH_MS := 115.0
const GHOST_MS := 190.0
const PARTICLE_MS := 160.0
const DEATH_MS := 760.0
const RESULT_DELAY_MS := 500.0
const ZONE_BANNER_MS := 1250.0
const SECRET_BANNER_MS := 1800.0
const FLOW_MS := 380.0
const HINT_PULSE_MS := 1000.0
const SKY_TRANSITION_MS := 900.0
const ATMOSPHERE_TRANSITION_MS := 900.0
const STARS_TRANSITION_MS := 1000.0
const SCAN_TRANSITION_MS := 800.0
## `Math.min(60, now-last)` — the prototype clamps long frames.
const MAX_FRAME_MS := 60.0

const CLOUD_COLOR := Color("ffffff")
const CLOUD_ALT_COLOR := Color("dfeef8")
const PLATFORM_COLOR := Color("2b3846")
const PLATFORM_TOP_COLOR := Color("42586d")
const PLATFORM_SHADOW_COLOR := Color("151d24")
const ACCENT := Color("ef6a5b")
const ACCENT_DARK := Color("9f4b46")
const INK := Color("24313d")

## Cloud depth layers. The camera looks down from high up, so a cloud nearer the
## camera sweeps past faster; the layer above the cat is nearly transparent and
## drifts across the top of the whole playfield.
const CLOUD_LAYERS := [
	{"name": "far", "count": 10, "scale": Vector2(0.34, 0.66), "speed": Vector2(0.024, 0.05), "alpha": 0.34, "over": false},
	{"name": "mid", "count": 11, "scale": Vector2(0.72, 1.30), "speed": Vector2(0.062, 0.115), "alpha": 0.85, "over": false},
	# Kept faint on purpose: AGENTS.md requires platforms to stay instantly
	# readable at speed, and this layer sits on top of them.
	{"name": "near", "count": 4, "scale": Vector2(1.90, 3.20), "speed": Vector2(0.20, 0.30), "alpha": 0.11, "over": true},
]
const WIND_COUNT := 20
const WIND_SIZE := Vector2(4.0, 28.0)

const TILE_RADIUS := 9.0

const HINT_TEXT := "화면을 탭해서 반대편으로"
const HINT_SUBTEXT := "멀리 갈수록 다른 하늘이 열린다"
const SAVE_PATH := "user://half_step.cfg"

var state := HalfStepState.new()
var tone_player: TonePlayer
var result_overlay: ResultOverlay

var best := 0
## `wasBest` in `die()`, captured before the stored best is replaced.
var was_best := false
var tutorial_taps := 0
var last_result_zone := "BLUE SKY"
var zone_index := -1

## Presentation timers, in milliseconds. -1 means "not running".
var hop_time := -1.0
var settle_time := -1.0
var lane_time := -1.0
var player_squash_time := -1.0
var death_time := -1.0
var flow_time := -1.0
var banner_time := -1.0
var banner_duration := ZONE_BANNER_MS
var banner_secret := false
var banner_text := ""
var banner_size := 13.0
var hint_phase := 0.0

var lane_from_x := 0.0
var lane_to_x := 0.0
## How far the bridge stack has visually travelled toward the cat within the
## current step. The rows themselves only move once, at the end of the step; on
## screen they slide across the jump so the bridge arrives under the cat exactly
## as the landing resolves, instead of being judged while it is still overhead
## and then snapping into place.
var row_scroll := 0.0
## Idle tail sway, advanced every frame.
var tail_phase := 0.0
## Duration of the lane hop currently running.
var lane_length := LANE_MS
## The lane the cat is physically standing on. `state.lane` is where the tap has
## committed it to land next; the two differ between the tap and the jump, and
## the cat spends that time leaning off the edge of its own bridge rather than
## hovering over the gap beside it.
var standing_lane := 0
## Where the leap started, so a tap mid-flight re-aims it instead of teleporting.
var hop_from_x := 0.0
## Frozen at death so the fall starts from the exact screen position.
var death_x := 0.0
## Durations of the cycle currently running, captured when it starts.
var hop_length := HOP_MS
var settle_length := SETTLE_MS
## Player height the row stack was last laid out against.
var layout_base_y := 0.0

var clouds: Array[Dictionary] = []
var winds: Array[Dictionary] = []
var ghosts: Array[Dictionary] = []
var particles: Array[Dictionary] = []

## Zone cross-fades. CSS transitions the sky gradient, the atmosphere layer and
## the star/scanline opacities on their own durations.
var sky_top := Color("79beff")
var sky_bottom := Color("eaf7ff")
var sky_from := [Color("79beff"), Color("eaf7ff")]
var sky_to := [Color("79beff"), Color("eaf7ff")]
var sky_time := -1.0
var atmosphere_previous: Dictionary = ZoneConfig.NO_ATMOSPHERE
var atmosphere_current: Dictionary = ZoneConfig.NO_ATMOSPHERE
var atmosphere_time := -1.0
var stars_opacity := 0.0
var stars_from := 0.0
var stars_to := 0.0
var stars_time := -1.0
var scan_opacity := 0.0
var scan_from := 0.0
var scan_to := 0.0
var scan_time := -1.0

var share_status := ""

var _origin := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _save := ConfigFile.new()


# --- layout -----------------------------------------------------------------

## The `#game` box: `width:100%; max-width:520px; margin:auto`.
func game_rect() -> Rect2:
	var view := get_viewport_rect().size
	var width := minf(GAME_MAX_WIDTH, view.x)
	return Rect2(floorf((view.x - width) * 0.5), 0.0, width, view.y)


func game_size() -> Vector2:
	return game_rect().size


## `laneX(l)` — left edge of the 36px player box.
func lane_x(lane: int) -> float:
	return game_size().x * 0.5 + (LANE_OFFSET if lane == 1 else -LANE_OFFSET) - PLAYER_BOX * 0.5


## `env(safe-area-inset-top)`, converted from screen pixels into game units.
func safe_area_top() -> float:
	var scale := get_viewport_transform().get_scale().y
	if scale <= 0.0:
		return 0.0
	var safe_area := DisplayServer.get_display_safe_area()
	var window_position := DisplayServer.window_get_position()
	return maxf(0.0, float(safe_area.position.y - window_position.y) / scale)


func base_y() -> float:
	return game_size().y * BASE_Y_RATIO


## Left edge of a tile: the row is a centred flex line of two 86px wraps.
func tile_x(lane: int) -> float:
	return game_size().x * 0.5 - (TILE_SIZE.x + TILE_GAP * 0.5) + float(lane) * (TILE_SIZE.x + TILE_GAP)


# --- lifecycle --------------------------------------------------------------

func _ready() -> void:
	_rng.randomize()
	tone_player = TonePlayer.new()
	add_child(tone_player)
	if _save.load(SAVE_PATH) == OK:
		best = int(_save.get_value("score", "best", 0))
	result_overlay = ResultOverlay.new()
	result_overlay.visible = false
	add_child(result_overlay)
	reset()
	get_viewport().size_changed.connect(_on_viewport_resized)


## The prototype restarts the run on any resize, which on a phone browser means
## the address bar sliding away can end a good run. Re-lay the stack out around
## the new player height instead and let the run continue.
func _on_viewport_resized() -> void:
	var size := game_size()
	var new_base_y := size.y * BASE_Y_RATIO
	if state.is_running():
		state.shift_rows(new_base_y - layout_base_y, new_base_y, size.y)
	layout_base_y = new_base_y
	build_background()
	queue_redraw()


## `reset()`
func reset() -> void:
	share_status = ""
	was_best = false
	standing_lane = 0
	layout_base_y = base_y()
	state.reset(layout_base_y, game_size().y, _rng.randi())
	tutorial_taps = 0
	hop_time = -1.0
	settle_time = -1.0
	lane_time = -1.0
	player_squash_time = -1.0
	death_time = -1.0
	flow_time = -1.0
	row_scroll = 0.0
	lane_length = LANE_MS
	hop_length = HOP_MS
	settle_length = SETTLE_MS
	banner_time = -1.0
	ghosts.clear()
	particles.clear()
	if tone_player != null:
		tone_player.stop_all()
	build_background()
	zone_index = -1
	apply_zone(true)
	queue_redraw()


## `buildBackground()`
func build_background() -> void:
	var size := game_size()
	clouds.clear()
	winds.clear()
	for layer_index in CLOUD_LAYERS.size():
		var layer: Dictionary = CLOUD_LAYERS[layer_index]
		for i in int(layer.count):
			var cloud := _spawn_cloud(layer_index, size)
			cloud.y = _rng.randf() * (size.y + Art.CLOUD_BOX.y) - Art.CLOUD_BOX.y
			cloud.alt = i % 2 == 1
			clouds.append(cloud)
	for _i in WIND_COUNT:
		winds.append({
			"x": _rng.randf() * size.x,
			"y": _rng.randf() * size.y,
			"speed": 0.28 + _rng.randf() * 0.36,
		})


## A cloud placed above the screen, ready to drift down through its layer.
func _spawn_cloud(layer_index: int, size: Vector2) -> Dictionary:
	var layer: Dictionary = CLOUD_LAYERS[layer_index]
	var scale_range: Vector2 = layer.scale
	var speed_range: Vector2 = layer.speed
	var scale := randf_between(scale_range.x, scale_range.y)
	var width := Art.CLOUD_BOX.x * scale
	return {
		"layer": layer_index,
		"x": randf_between(-width * 0.35, size.x - width * 0.65),
		"y": -Art.CLOUD_BOX.y * scale,
		"speed": randf_between(speed_range.x, speed_range.y),
		"scale": scale,
		"alt": false,
	}


func randf_between(from: float, to: float) -> float:
	return from + _rng.randf() * (to - from)


# --- input ------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	var position := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Touch on mobile and web also synthesises a mouse click; handling both
		# would toggle the lane twice per tap.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		position = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		position = Vector2.ZERO
	if position == Vector2.INF:
		return
	if not state.is_running():
		# A player dies mid-rhythm, so a tap is almost always already in flight
		# when the run ends. Retrying on that tap swallows the fall and the
		# score card entirely — the run just silently starts over. Taps are
		# ignored until the card is up; from then on a tap anywhere retries, so
		# retry still costs one tap and no button hunting.
		if death_time < RESULT_DELAY_MS:
			return
		if Rect2(result_layout().share).has_point(position):
			share_score()
		else:
			reset()
		return
	tap()


## `tap()` — never locked, never queued.
func tap() -> void:
	lane_from_x = player_left()
	state.toggle_lane()
	# Mid-flight the leap simply re-aims; there is no weight to shift.
	if hop_time < 0.0:
		lane_length = LANE_MS * cycle_scale()
		lane_time = 0.0
	tutorial_taps += 1
	_vibrate(5)
	queue_redraw()


# --- frame ------------------------------------------------------------------

func _process(delta: float) -> void:
	var dt := minf(MAX_FRAME_MS, delta * 1000.0)
	_advance_timers(dt)
	if state.is_running():
		update_background(dt)
		state.step_timer += dt
		if state.step_timer >= state.step_interval and not state.stepping:
			state.step_timer -= state.step_interval
			start_step()
	queue_redraw()


func _advance_timers(dt: float) -> void:
	hint_phase = fmod(hint_phase + dt, HINT_PULSE_MS)
	# The tail keeps swaying whatever else is happening, a little faster as the
	# run speeds up.
	tail_phase = fmod(tail_phase + dt * 0.00055 * (1.0 + float(state.score) / 240.0), 1.0)
	if hop_time >= 0.0:
		hop_time += dt
		row_scroll = HalfStepState.ROW_SPACING * CssAnim.curve(
			CssAnim.SNAP, clampf(hop_time / maxf(hop_length, 0.001), 0.0, 1.0))
		if hop_time >= hop_length:
			hop_time = -1.0
			row_scroll = HalfStepState.ROW_SPACING
			resolve_landing()
	if settle_time >= 0.0:
		settle_time += dt
		if settle_time >= settle_length:
			settle_time = -1.0
			finish_step()
	if lane_time >= 0.0:
		lane_time += dt
		if lane_time >= lane_length:
			lane_time = -1.0
	if player_squash_time >= 0.0:
		player_squash_time += dt
		if player_squash_time >= PLAYER_SQUASH_MS * cycle_scale():
			player_squash_time = -1.0
	if death_time >= 0.0:
		death_time += dt
	if flow_time >= 0.0:
		flow_time += dt
		if flow_time >= FLOW_MS:
			flow_time = -1.0
	if banner_time >= 0.0:
		banner_time += dt
		if banner_time >= banner_duration:
			banner_time = -1.0
	for row in state.rows:
		if float(row.squash) >= 0.0:
			row.squash = float(row.squash) + dt
			if float(row.squash) >= TILE_SQUASH_MS:
				row.squash = -1.0
	_advance_effects(dt)
	_advance_transitions(dt)


func _advance_effects(dt: float) -> void:
	var live_ghosts: Array[Dictionary] = []
	for ghost in ghosts:
		ghost.time = float(ghost.time) + dt
		if float(ghost.time) < GHOST_MS:
			live_ghosts.append(ghost)
	ghosts = live_ghosts
	var live_particles: Array[Dictionary] = []
	for particle in particles:
		particle.time = float(particle.time) + dt
		if float(particle.time) < PARTICLE_MS:
			live_particles.append(particle)
	particles = live_particles


func _advance_transitions(dt: float) -> void:
	if sky_time >= 0.0:
		sky_time += dt
		var t := CssAnim.curve(CssAnim.EASE, sky_time / SKY_TRANSITION_MS)
		sky_top = Color(sky_from[0]).lerp(sky_to[0], t)
		sky_bottom = Color(sky_from[1]).lerp(sky_to[1], t)
		if sky_time >= SKY_TRANSITION_MS:
			sky_time = -1.0
	if atmosphere_time >= 0.0:
		atmosphere_time += dt
		if atmosphere_time >= ATMOSPHERE_TRANSITION_MS:
			atmosphere_time = -1.0
	if stars_time >= 0.0:
		stars_time += dt
		stars_opacity = lerpf(stars_from, stars_to, CssAnim.curve(CssAnim.EASE, stars_time / STARS_TRANSITION_MS))
		if stars_time >= STARS_TRANSITION_MS:
			stars_time = -1.0
	if scan_time >= 0.0:
		scan_time += dt
		scan_opacity = lerpf(scan_from, scan_to, CssAnim.curve(CssAnim.EASE, scan_time / SCAN_TRANSITION_MS))
		if scan_time >= SCAN_TRANSITION_MS:
			scan_time = -1.0


## `updateBackground(dt)` — each layer drifts at its own rate, so the sky reads
## as depth rather than one flat sheet.
func update_background(dt: float) -> void:
	var size := game_size()
	var zone := state.current_zone()
	var speed: float = minf(42.0, (1.0 + float(state.score) / 24.0) * float(zone.boost))
	for index in clouds.size():
		var cloud: Dictionary = clouds[index]
		cloud.y = float(cloud.y) + dt * float(cloud.speed) * speed
		if float(cloud.y) > size.y + Art.CLOUD_BOX.y * float(cloud.scale):
			var replacement := _spawn_cloud(int(cloud.layer), size)
			replacement.alt = cloud.alt
			clouds[index] = replacement
	for wind in winds:
		wind.y = float(wind.y) + dt * float(wind.speed) * speed
		if float(wind.y) > size.y + 50.0:
			wind.y = -70.0
			wind.x = _rng.randf() * size.x


# --- step cycle -------------------------------------------------------------

## Shrinks the hop and settle once the cadence is shorter than they are, so the
## beat keeps setting the pace instead of the animation.
func cycle_scale() -> float:
	return minf(1.0, state.step_interval / STEP_CYCLE_MS)


## `startStep()` — the hop plays first, the landing resolves when it finishes.
func start_step() -> void:
	state.stepping = true
	hop_from_x = player_left()
	lane_time = -1.0
	hop_length = HOP_MS * cycle_scale()
	hop_time = 0.0


## `resolveLanding()`
func resolve_landing() -> void:
	var row := state.resolve_landing(base_y())
	if row.is_empty():
		die()
		return
	# The cat is now standing on the bridge it just landed on.
	standing_lane = state.lane
	tone_player.play_success_note(state.note_position())
	flow_time = 0.0
	spawn_impact(row)
	row.squash = 0.0
	player_squash_time = 0.0
	_vibrate(5)
	apply_zone()
	secret_flash()
	settle_length = SETTLE_MS * cycle_scale()
	settle_time = 0.0


## The `setTimeout(..., 50)` tail of `resolveLanding()`.
func finish_step() -> void:
	if not state.is_running():
		return
	state.advance_rows(base_y(), game_size().y)
	# The stack has caught up with where it was already being drawn.
	row_scroll = 0.0
	# `player.getAnimations().forEach(a => a.cancel())` also drops an in-flight
	# lane slide, snapping the player onto its lane.
	lane_time = -1.0
	player_squash_time = -1.0
	state.stepping = false


## `platformImpact(tile)`
func spawn_impact(row: Dictionary) -> void:
	var tile := Rect2(Vector2(tile_x(state.lane), float(row.y) + row_scroll), TILE_SIZE)
	ghosts.append({"rect": tile, "time": 0.0})
	var center := tile.get_center()
	var directions := [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]
	for i in directions.size():
		particles.append({
			"position": center,
			"direction": directions[i],
			"time": 0.0,
			"spark": i % 2 == 0,
		})


## `die()`
func die() -> void:
	# AGENTS.md: the fall starts from the exact position the cat missed at.
	death_x = player_left()
	hop_time = -1.0
	settle_time = -1.0
	lane_time = -1.0
	player_squash_time = -1.0
	death_time = 0.0
	tone_player.play_fall()
	_vibrate_death()
	was_best = state.score > best
	if was_best:
		best = state.score
		_save.set_value("score", "best", best)
		_save.save(SAVE_PATH)


## `applyZone(force)`
func apply_zone(force := false) -> void:
	var index := ZoneConfig.index_for_score(state.score)
	if not force and index == zone_index:
		return
	var first := zone_index < 0 and force
	zone_index = index
	var zone := ZoneConfig.ZONES[index]
	last_result_zone = String(zone.name)
	sky_from = [sky_top, sky_bottom]
	sky_to = [zone.top, zone.bottom]
	atmosphere_previous = atmosphere_current
	atmosphere_current = zone.atmo
	stars_from = stars_opacity
	stars_to = float(zone.stars)
	scan_from = scan_opacity
	scan_to = float(zone.scan)
	if first:
		sky_top = zone.top
		sky_bottom = zone.bottom
		stars_opacity = stars_to
		scan_opacity = scan_to
		atmosphere_previous = ZoneConfig.NO_ATMOSPHERE
		sky_time = -1.0
		atmosphere_time = -1.0
		stars_time = -1.0
		scan_time = -1.0
	else:
		sky_time = 0.0
		atmosphere_time = 0.0
		stars_time = 0.0
		scan_time = 0.0
	if state.score > 0:
		banner_text = String(zone.name)
		banner_size = 13.0
		banner_secret = false
		banner_duration = ZONE_BANNER_MS
		banner_time = 0.0


## `secretFlash()`
func secret_flash() -> void:
	var text := ZoneConfig.milestone_for_score(state.score)
	if text.is_empty():
		return
	banner_text = text
	banner_size = 16.0 if state.score >= 750 else 13.0
	banner_secret = true
	banner_duration = SECRET_BANNER_MS
	banner_time = 0.0


func _vibrate(milliseconds: int) -> void:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		Input.vibrate_handheld(milliseconds)


## `navigator.vibrate([28,30,65])`
func _vibrate_death() -> void:
	if not (OS.has_feature("mobile") or OS.has_feature("web")):
		return
	Input.vibrate_handheld(28)
	await get_tree().create_timer(0.058).timeout
	Input.vibrate_handheld(65)


## `shareScore()`
func share_score() -> void:
	share_status = ""
	queue_redraw()
	var zone := ZoneConfig.ZONES[zone_index]
	var text := "HALF STEP %d점 · %s까지 도달! 이 기록 넘을 수 있어?" % [state.score, last_result_zone]
	var image: Image = await ShareCard.render(self, state.score, zone, last_result_zone)
	ShareCard.share(text, image, state.score, func(status: String) -> void:
		share_status = status
		queue_redraw())


# --- player animation -------------------------------------------------------

## Where the cat stands while it is on a bridge: on its own deck, leaning toward
## the lane it has committed to. Never out over the gap.
func grounded_x() -> float:
	var here := lane_x(standing_lane)
	var committed := lane_x(state.lane)
	if is_equal_approx(here, committed):
		return here
	return here + signf(committed - here) * LEAN_DISTANCE


func player_left() -> float:
	if death_time >= 0.0:
		return death_x
	if hop_time >= 0.0:
		# The leap itself carries the cat across, so crossing lanes is one
		# diagonal jump from bridge to bridge.
		return lerpf(hop_from_x, lane_x(state.lane),
			CssAnim.curve(CssAnim.SNAP, hop_time / maxf(hop_length, 0.001)))
	if lane_time >= 0.0:
		return lerpf(lane_from_x, grounded_x(), CssAnim.curve(CssAnim.SNAP, lane_time / maxf(lane_length, 0.001)))
	return grounded_x()


## How far off a bridge the cat is, 0 planted and 1 at the top of a jump. Both
## the forward hop and the hop across the lanes contribute, so a tap mid-beat
## still throws the legs out.
func leap_amount() -> float:
	var forward := 0.0
	if hop_time >= 0.0:
		forward = sin(PI * clampf(hop_time / maxf(hop_length, 0.001), 0.0, 1.0))
	var across := 0.0
	if lane_time >= 0.0:
		across = sin(PI * clampf(lane_time / maxf(lane_length, 0.001), 0.0, 1.0))
	return clampf(maxf(forward, across), 0.0, 1.0)


func player_transform() -> Dictionary:
	var y := base_y()
	var scale := Vector2.ONE
	var rotation := 0.0
	var alpha := 1.0
	if death_time >= 0.0:
		var t := clampf(death_time / DEATH_MS, 0.0, 1.0)
		var offsets := [0.0, 0.28, 0.63, 1.0]
		y += CssAnim.track(t, offsets, [0.0, 4.0, 7.0, 10.0], CssAnim.DEPTH)
		var uniform := CssAnim.track(t, offsets, [1.0, 0.72, 0.35, 0.04], CssAnim.DEPTH)
		scale = Vector2(uniform, uniform)
		rotation = deg_to_rad(CssAnim.track(t, offsets, [0.0, 20.0, 75.0, 160.0], CssAnim.DEPTH))
		alpha = CssAnim.track(t, offsets, [1.0, 0.94, 0.62, 0.0], CssAnim.DEPTH)
		return {"y": y, "scale": scale, "rotation": rotation, "alpha": alpha}
	if hop_time >= 0.0:
		# Straight down the camera, a jump is the cat growing as it rises toward
		# the lens, not an arc across the screen. A little travel stays so the
		# hop still points at the bridge it is heading for.
		var t := clampf(hop_time / maxf(hop_length, 0.001), 0.0, 1.0)
		var offsets := [0.0, 0.5, 1.0]
		y += CssAnim.track(t, offsets, [0.0, -11.0, 0.0], CssAnim.SNAP)
		var lift := CssAnim.track(t, offsets, [1.0, 1.16, 1.0], CssAnim.SNAP)
		scale = Vector2(lift, lift)
	var crossing := signf(lane_x(state.lane) - lane_x(standing_lane))
	if hop_time >= 0.0:
		# Leaning into a diagonal leap.
		rotation += crossing * 0.30 * sin(PI * clampf(hop_time / maxf(hop_length, 0.001), 0.0, 1.0))
	elif crossing != 0.0:
		# Weight already shifted toward the bridge it is about to jump to.
		var settled := 1.0 if lane_time < 0.0 else CssAnim.curve(CssAnim.SNAP, lane_time / maxf(lane_length, 0.001))
		rotation += crossing * 0.22 * settled
	if player_squash_time >= 0.0 and hop_time < 0.0:
		var t := clampf(player_squash_time / (PLAYER_SQUASH_MS * cycle_scale()), 0.0, 1.0)
		var offsets := [0.0, 0.45, 1.0]
		y += CssAnim.track(t, offsets, [0.0, 4.0, 0.0], CssAnim.EASE_OUT)
		scale = Vector2(
			CssAnim.track(t, offsets, [1.0, 1.08, 1.0], CssAnim.EASE_OUT),
			CssAnim.track(t, offsets, [1.0, 0.88, 1.0], CssAnim.EASE_OUT)
		)
	return {"y": y, "scale": scale, "rotation": rotation, "alpha": alpha}


# --- drawing ----------------------------------------------------------------

func _transform(position: Vector2, rotation := 0.0, scale := Vector2.ONE) -> void:
	draw_set_transform(_origin + position, rotation, scale)


func _draw() -> void:
	var rect := game_rect()
	_origin = rect.position
	var size := rect.size
	var local := Rect2(Vector2.ZERO, size)
	draw_set_transform(_origin)
	_draw_sky(local)
	_draw_atmosphere(local)
	_draw_stars(local)
	_draw_scan(local)
	_draw_clouds(false)
	_draw_wind()
	_draw_rows(size)
	_draw_ghosts()
	_draw_particles()
	_draw_player()
	# The layer between the camera and the cat, drifting over everything.
	_draw_clouds(true)
	_draw_hud(size)
	draw_set_transform(Vector2.ZERO)
	_draw_letterbox(rect)
	if result_overlay != null:
		result_overlay.visible = death_time >= RESULT_DELAY_MS
		if result_overlay.visible:
			result_overlay.refresh(rect)


## `#game{background:linear-gradient(to bottom,var(--sky-top),var(--sky-bottom))}`
func _draw_sky(rect: Rect2) -> void:
	CssPaint.linear_gradient(self, rect, 180.0, [[0.0, sky_top], [1.0, sky_bottom]])


func _draw_atmosphere(rect: Rect2) -> void:
	if atmosphere_time >= 0.0:
		var t := CssAnim.curve(CssAnim.EASE, atmosphere_time / ATMOSPHERE_TRANSITION_MS)
		CssPaint.atmosphere(self, rect, atmosphere_previous, 1.0 - t)
		CssPaint.atmosphere(self, rect, atmosphere_current, t)
	else:
		CssPaint.atmosphere(self, rect, atmosphere_current, 1.0)


## `#stars` — two offset dot grids from repeating radial gradients.
func _draw_stars(rect: Rect2) -> void:
	if stars_opacity <= 0.0:
		return
	var color := Color(1.0, 1.0, 1.0, stars_opacity)
	for grid in [[Vector2(74.0, 83.0), Vector2(10.0, 12.0)], [Vector2(117.0, 131.0), Vector2(44.0, 61.0)]]:
		var tile: Vector2 = grid[0]
		var offset: Vector2 = grid[1] + tile * 0.5
		var y := fmod(offset.y, tile.y)
		while y < rect.size.y:
			var x := fmod(offset.x, tile.x)
			while x < rect.size.x:
				draw_circle(Vector2(x, y), 1.3, color, true, -1.0, true)
				x += tile.x
			y += tile.y


## `#scan` — 2px lines every 6px at 3% white.
func _draw_scan(rect: Rect2) -> void:
	if scan_opacity <= 0.0:
		return
	var color := Color(1.0, 1.0, 1.0, 0.03 * scan_opacity)
	var y := 0.0
	while y < rect.size.y:
		draw_rect(Rect2(0.0, y, rect.size.x, 2.0), color)
		y += 6.0


func _draw_clouds(overhead: bool) -> void:
	for cloud in clouds:
		var layer: Dictionary = CLOUD_LAYERS[int(cloud.layer)]
		if bool(layer.over) != overhead:
			continue
		var color := CLOUD_ALT_COLOR if bool(cloud.alt) else CLOUD_COLOR
		color.a = float(layer.alpha) * (0.82 if bool(cloud.alt) else 1.0)
		var scale := float(cloud.scale)
		_transform(Vector2(float(cloud.x), float(cloud.y)) + Art.CLOUD_ORIGIN * scale, 0.0, Vector2(scale, scale))
		Art.draw_cloud(self, color)
	draw_set_transform(_origin)


func _draw_wind() -> void:
	var opacity := clampf((float(state.score) - 10.0) / 45.0, 0.0, 0.95)
	if opacity <= 0.0:
		return
	var stretch := 1.0 + minf(4.0, float(state.score) / 45.0)
	# Thinner and fainter than the pixel skin's hard 4px bars: with round caps and
	# a smooth edge, the old weight read as solid poles rather than moving air.
	var color := Color(1.0, 1.0, 1.0, 0.5 * opacity)
	var thickness := 3.0
	var half := WIND_SIZE.y * 0.5 * stretch
	for wind in winds:
		var center := Vector2(float(wind.x), float(wind.y)) + WIND_SIZE * 0.5
		Shapes.capsule(self, center - Vector2(0.0, half - thickness * 0.5),
			center + Vector2(0.0, half - thickness * 0.5), thickness, color)


func _draw_rows(size: Vector2) -> void:
	for row in state.rows:
		var y := float(row.y) + row_scroll
		if y > size.y + 60.0 or y < -80.0 - HalfStepState.ROW_SPACING:
			continue
		for lane in 2:
			var left := tile_x(lane)
			var safe: bool = lane == int(row.safe_lane)
			if safe:
				_draw_tile(Vector2(left, y), float(row.squash))
			else:
				_draw_empty_tile(Vector2(left, y))


## A bridge section seen from above: a deck with plank seams and a rail down
## each side. Nothing here suggests thickness, because from straight overhead
## there is none to see — height is carried by the shadow on the clouds below.
func _draw_tile(top_left: Vector2, squash: float) -> void:
	var center := top_left + TILE_SIZE * 0.5
	var offset := 0.0
	var scale := Vector2.ONE
	if squash >= 0.0:
		var t := clampf(squash / TILE_SQUASH_MS, 0.0, 1.0)
		var offsets := [0.0, 0.38, 1.0]
		offset = CssAnim.track(t, offsets, [0.0, 3.0, 0.0], CssAnim.EASE_OUT)
		scale = Vector2(
			CssAnim.track(t, offsets, [1.0, 1.03, 1.0], CssAnim.EASE_OUT),
			CssAnim.track(t, offsets, [1.0, 0.94, 1.0], CssAnim.EASE_OUT)
		)
	var half := TILE_SIZE * 0.5
	# Cast far below onto the cloud deck, which is what sells the height. Stacked
	# rings stand in for a blur: one hard rectangle reads as a second bridge.
	# Concentric rings at one offset, not a staircase of offsets, so the falloff
	# reads as blur rather than as several stacked bridges.
	for step in 4:
		var spread := 1.0 + float(step) * 0.055
		_transform(center + Vector2(2.0, 10.0))
		Shapes.rounded_rect(self, Rect2(-half * spread, TILE_SIZE * spread), TILE_RADIUS,
			Color(0.05, 0.09, 0.15, 0.045))
	_transform(center + Vector2(0.0, offset), 0.0, scale)
	Shapes.rounded_rect(self, Rect2(-half, TILE_SIZE), TILE_RADIUS, PLATFORM_COLOR)
	for i in 2:
		var seam := -half.y + TILE_SIZE.y * (float(i) + 1.0) / 3.0
		draw_line(Vector2(-half.x + 7.0, seam), Vector2(half.x - 7.0, seam), Color(0.0, 0.0, 0.0, 0.20), 1.6, true)
	# A rail down each edge, running the way the cat travels.
	for left: float in [-half.x, half.x - 5.0]:
		Shapes.rounded_rect(self, Rect2(Vector2(left, -half.y), Vector2(5.0, TILE_SIZE.y)),
			2.5, PLATFORM_TOP_COLOR)
	draw_set_transform(_origin)


## The lane without a platform: a hint of where one would be.
func _draw_empty_tile(top_left: Vector2) -> void:
	var rect := Rect2(top_left + Vector2(3.0, 3.0), TILE_SIZE - Vector2(6.0, 6.0))
	Shapes.rounded_rect(self, rect, TILE_RADIUS - 2.0, Color(1.0, 1.0, 1.0, 0.07))
	draw_polyline(Shapes.closed(Shapes.rounded_rect_polygon(rect, Vector4(TILE_RADIUS - 2.0, TILE_RADIUS - 2.0, TILE_RADIUS - 2.0, TILE_RADIUS - 2.0))),
		Color(1.0, 1.0, 1.0, 0.28), 2.0, true)


## Shock ring that expands off the platform on a landing.
func _draw_ghosts() -> void:
	for ghost in ghosts:
		var t := clampf(float(ghost.time) / GHOST_MS, 0.0, 1.0)
		var offsets := [0.0, 0.42, 1.0]
		var scale := Vector2(
			CssAnim.track(t, offsets, [1.0, 1.16, 1.28], CssAnim.IMPACT),
			CssAnim.track(t, offsets, [1.0, 1.28, 1.38], CssAnim.IMPACT)
		)
		var alpha := CssAnim.track(t, offsets, [0.58, 0.26, 0.0], CssAnim.IMPACT)
		if alpha <= 0.0:
			continue
		var rect: Rect2 = ghost.rect
		var half := rect.size * 0.5
		_transform(rect.get_center(), 0.0, scale)
		draw_polyline(Shapes.closed(Shapes.rounded_rect_polygon(Rect2(-half, rect.size),
			Vector4(TILE_RADIUS, TILE_RADIUS, TILE_RADIUS, TILE_RADIUS))),
			Color(1.0, 1.0, 1.0, alpha), 3.0, true)
	draw_set_transform(_origin)


## Round sparks thrown out of the landing.
func _draw_particles() -> void:
	for particle in particles:
		var t := clampf(float(particle.time) / PARTICLE_MS, 0.0, 1.0)
		var eased := CssAnim.curve(CssAnim.EASE_OUT, t)
		var spark := bool(particle.spark)
		var radius := (3.4 if spark else 2.8) * lerpf(1.0, 0.35, eased)
		var color := Color("ffe9a8") if spark else Color(1.0, 1.0, 1.0)
		color.a = lerpf(0.9, 0.0, eased)
		var direction: Vector2 = particle.direction
		var offset := Vector2(direction.x * 18.0, direction.y * 11.0) * eased
		draw_circle(Vector2(particle.position) + offset, radius, color, true, -1.0, true)


func _draw_player() -> void:
	var animation := player_transform()
	var alpha: float = animation.alpha
	if alpha <= 0.0:
		return
	var box := Vector2(player_left(), float(animation.y))
	var center := box + Vector2(PLAYER_BOX, PLAYER_BOX) * 0.5
	_transform(center, float(animation.rotation), animation.scale)
	# Beak first so the body's edge covers where it joins.
	Art.draw_cat(self, alpha, tail_phase, leap_amount())
	draw_set_transform(_origin)


func _draw_hud(size: Vector2) -> void:
	var inset := safe_area_top()
	# #score{top:max(26px, env(safe-area-inset-top))}
	CssText.draw_centered_shadowed(self, str(state.score), 0.0, size.x, maxf(26.0, inset), 46.0, -3.0,
		Color(1.0, 1.0, 1.0), Color(0.0, 0.0, 0.0, 0.16), 4.0)
	# #best{top:max(80px, calc(env(safe-area-inset-top) + 54px))}
	CssText.draw_centered(self, "BEST %d" % best, 0.0, size.x, maxf(80.0, inset + 54.0), 11.0, 1.3,
		Color(1.0, 1.0, 1.0, 0.84))
	_draw_banner(size)
	_draw_flow(size)
	if tutorial_taps < 2 and state.is_running():
		_draw_hint(size)


## #zone, shared by the zone reveal and the secret milestone flash.
func _draw_banner(size: Vector2) -> void:
	if banner_time < 0.0:
		return
	var t := clampf(banner_time / banner_duration, 0.0, 1.0)
	var offsets := [0.0, 0.3, 0.72, 1.0] if banner_secret else [0.0, 0.35, 0.68, 1.0]
	var scales := [0.55, 1.12, 1.0, 0.98] if banner_secret else [0.75, 1.08, 1.0, 0.98]
	var alpha := CssAnim.track(t, offsets, [0.0, 1.0, 1.0, 0.0], CssAnim.EASE_OUT)
	if alpha <= 0.0:
		return
	var scale := CssAnim.track(t, offsets, scales, CssAnim.EASE_OUT)
	var top := size.y * 0.20
	var center := Vector2(size.x * 0.5, top + CssText.line_height(banner_size) * 0.5)
	_transform(center, 0.0, Vector2(scale, scale))
	CssText.draw_centered_shadowed(self, banner_text, -size.x * 0.5, size.x, -CssText.line_height(banner_size) * 0.5,
		banner_size, 3.0, Color(1.0, 1.0, 1.0, alpha), Color(0.0, 0.0, 0.0, 0.18 * alpha), 3.0)
	draw_set_transform(_origin)


## #flow
func _draw_flow(size: Vector2) -> void:
	if flow_time < 0.0:
		return
	var alpha := CssAnim.track(clampf(flow_time / FLOW_MS, 0.0, 1.0), [0.0, 0.3, 1.0], [0.0, 0.82, 0.0], CssAnim.LINEAR)
	if alpha <= 0.0:
		return
	CssText.draw_centered(self, "FLOW %d" % state.success_streak, 0.0, size.x, size.y * 0.33, 11.0, 1.5,
		Color(1.0, 1.0, 1.0, alpha))


## #hint, with the `pulse` keyframe animation.
func _draw_hint(size: Vector2) -> void:
	var height := CssText.line_height(16.0) + 6.0 + CssText.line_height(10.0)
	var top := size.y * 0.91 - height
	var half := clampf(hint_phase / HINT_PULSE_MS, 0.0, 1.0)
	var progress := half * 2.0 if half <= 0.5 else (1.0 - half) * 2.0
	var eased := CssAnim.curve(CssAnim.EASE, progress)
	var scale := lerpf(1.0, 1.04, eased)
	var alpha := lerpf(1.0, 0.62, eased)
	var center := Vector2(size.x * 0.5, top + height * 0.5)
	_transform(center, 0.0, Vector2(scale, scale))
	var left := -size.x * 0.5
	CssText.draw_centered_shadowed(self, HINT_TEXT, left, size.x, -height * 0.5, 16.0, 0.0,
		Color(1.0, 1.0, 1.0, alpha), Color(0.0, 0.0, 0.0, 0.13 * alpha), 3.0)
	CssText.draw_centered_shadowed(self, HINT_SUBTEXT, left, size.x, -height * 0.5 + CssText.line_height(16.0) + 6.0,
		10.0, 0.0, Color(1.0, 1.0, 1.0, alpha * 0.82), Color(0.0, 0.0, 0.0, 0.13 * alpha * 0.82), 3.0)
	draw_set_transform(_origin)


## Layout of `#overlay` > `#card` > `.card-inner`, in viewport coordinates.
## Kept separate from drawing so hit testing never depends on a frame having
## been rendered.
func result_layout() -> Dictionary:
	var rect := game_rect()
	var size := rect.size
	var card_width := minf(size.x * 0.86, 360.0)
	var content_width := card_width - 88.0
	var blocks := [
		CssText.line_height(12.0),
		70.0 * 1.05,
		7.0 + CssText.line_height(11.0),
		4.0 + 18.0,
		16.0 + 50.0,
		8.0 + 13.0,
		10.0 + CssText.line_height(10.0),
	]
	var content_height := 0.0
	for value: float in blocks:
		content_height += value
	# .card-inner padding 18/16/14 + 4px border, #card padding 18 + 6px border.
	var card_height := content_height + 18.0 + 14.0 + 8.0 + 36.0 + 12.0
	var card := Rect2(
		rect.position + Vector2((size.x - card_width) * 0.5, (size.y - card_height) * 0.5),
		Vector2(card_width, card_height)
	)
	var inner := Rect2(card.position + Vector2(24.0, 24.0), card.size - Vector2(48.0, 48.0))
	var content_left := inner.position.x + 4.0 + 16.0
	var button_top: float = inner.position.y + 4.0 + 18.0 + float(blocks[0]) + float(blocks[1]) + float(blocks[2]) + float(blocks[3]) + 16.0
	var button_width := (content_width - 9.0) * 0.5
	return {
		"card": card,
		"inner": inner,
		"content_left": content_left,
		"content_width": content_width,
		"content_top": inner.position.y + 4.0 + 18.0,
		"blocks": blocks,
		"retry": Rect2(content_left, button_top, button_width, 50.0),
		"share": Rect2(content_left + button_width + 9.0, button_top, button_width, 50.0),
	}


## `#overlay` and `#card`, painted onto [param canvas] so the blurred backdrop
## from [ResultOverlay] stays underneath.
func draw_result(canvas: CanvasItem) -> void:
	var rect := game_rect()
	var size := rect.size
	_origin = rect.position
	canvas.draw_set_transform(_origin)
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("223f5c", 0.38))
	var layout := result_layout()
	var blocks: Array = layout.blocks
	var content_width: float = layout.content_width
	var card := Rect2(Rect2(layout.card).position - _origin, Rect2(layout.card).size)
	var inner := Rect2(Rect2(layout.inner).position - _origin, Rect2(layout.inner).size)
	var left: float = float(layout.content_left) - _origin.x
	canvas.draw_rect(Rect2(card.position + Vector2(0.0, 8.0), card.size), Color("14384f", 0.18))
	canvas.draw_rect(card, Color(1.0, 1.0, 1.0))
	canvas.draw_rect(Rect2(card.position + Vector2(6.0, 6.0), card.size - Vector2(12.0, 12.0)), Color(1.0, 1.0, 1.0, 0.96))
	canvas.draw_rect(inner, Color("d6e7f1"))
	canvas.draw_rect(Rect2(inner.position + Vector2(4.0, 4.0), inner.size - Vector2(8.0, 8.0)), Color("f6fbff", 0.98))
	var y: float = float(layout.content_top) - _origin.y
	CssText.draw_centered(canvas, "RUN ENDED", left, content_width, y, 12.0, 2.0, Color(0.0, 0.0, 0.0, 0.44))
	y += float(blocks[0])
	CssText.draw_centered(canvas, str(state.score), left, content_width,
		y + (70.0 * 1.05 - CssText.line_height(70.0)) * 0.5, 70.0, -4.0, Color("263644"))
	y += float(blocks[1]) + 7.0
	CssText.draw_centered(canvas, "REACHED · %s" % last_result_zone, left, content_width, y, 11.0, 1.5, Color("6d8293"))
	y += CssText.line_height(11.0) + 4.0
	var best_line := "NEW BEST!" if was_best else "BEST %d" % best
	CssText.draw_centered(canvas, best_line, left, content_width, y, 12.0, 0.0, ACCENT)
	var retry := Rect2(Rect2(layout.retry).position - _origin, Rect2(layout.retry).size)
	var share := Rect2(Rect2(layout.share).position - _origin, Rect2(layout.share).size)
	canvas.draw_rect(Rect2(retry.position + Vector2(0.0, 5.0), retry.size), Color("111a21"))
	canvas.draw_rect(retry, INK)
	canvas.draw_rect(Rect2(share.position + Vector2(0.0, 5.0), share.size), Color("c7dce9"))
	canvas.draw_rect(share, Color("e7f2f9"))
	var label_offset := (50.0 - CssText.line_height(14.0)) * 0.5
	CssText.draw_centered(canvas, "다시하기", retry.position.x, retry.size.x, retry.position.y + label_offset, 14.0, 0.0, Color(1.0, 1.0, 1.0))
	CssText.draw_centered(canvas, "공유하기", share.position.x, share.size.x, share.position.y + label_offset, 14.0, 0.0, INK)
	y = retry.position.y + 50.0 + 8.0
	if not share_status.is_empty():
		CssText.draw_centered(canvas, share_status, left, content_width, y, 10.0, 0.0, Color("607585"))
	y += 13.0 + 10.0
	CssText.draw_centered(canvas, "PLAY · FAIL · SHARE · REPEAT", left, content_width, y, 10.0, 0.0, Color(0.0, 0.0, 0.0, 0.45))
	canvas.draw_set_transform(Vector2.ZERO)


func _draw_letterbox(rect: Rect2) -> void:
	var view := get_viewport_rect().size
	if rect.position.x <= 0.0:
		return
	draw_rect(Rect2(0.0, 0.0, rect.position.x, view.y), PAGE_BACKGROUND)
	draw_rect(Rect2(rect.end.x, 0.0, view.x - rect.end.x, view.y), PAGE_BACKGROUND)
