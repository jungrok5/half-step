extends Node2D

const VIEW := Vector2(720.0, 1280.0)
const LANE_X := [245.0, 475.0]
const PLAYER_Y := 922.0
const ROW_SPACING := 184.0
const PLATFORM_SIZE := Vector2(172.0, 56.0)
const PLAYER_PIXEL := 8.0
const RETRY_RECT := Rect2(112, 742, 236, 94)
const SHARE_RECT := Rect2(372, 742, 236, 94)

const PLAYER_CELLS := [
	["dark",2,0],["dark",3,0],
	["body",1,1],["body",2,1],["body",3,1],["body",4,1],
	["body",0,2],["body",1,2],["body",2,2],["body",3,2],["body",4,2],["body",5,2],
	["body",0,3],["eye",1,3],["body",2,3],["body",3,3],["eye",4,3],["body",5,3],
	["body",0,4],["body",1,4],["cheek",2,4],["cheek",3,4],["body",4,4],["body",5,4],
	["body",1,5],["body",2,5],["body",3,5],["body",4,5],
	["dark",2,6],["belt",3,6],
	["body",1,7],["body",2,7],["body",3,7],["body",4,7],
	["body",1,8],["body",2,8],["body",3,8],["body",4,8],
	["boot",1,9],["body",2,9],["body",3,9],["boot",4,9],
]

var state := HalfStepState.new(Time.get_ticks_usec())
var tone_player: TonePlayer
var cadence_elapsed_ms := 0.0
var impact_time := 0.0
var death_time := 0.0
var lane_anim_time := 0.0
var lane_from_x := LANE_X[0]
var player_x := LANE_X[0]
var zone_reveal_time := 0.0
var milestone_time := 0.0
var previous_zone := ""
var best_score := 0
var tutorial_taps := 0
var cloud_phase := 0.0
var shake_time := 0.0
var particles: Array[Dictionary] = []
var save_file := ConfigFile.new()

func _ready() -> void:
	tone_player = TonePlayer.new()
	add_child(tone_player)
	if save_file.load("user://half_step.cfg") == OK:
		best_score = int(save_file.get_value("score", "best", 0))
	state.best_score = best_score
	previous_zone = str(state.current_zone().name)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		position = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	if not pressed:
		return
	if state.run_state == HalfStepState.RunState.DEAD and death_time >= 0.45:
		if SHARE_RECT.has_point(position):
			_share_score()
		else:
			_restart()
	else:
		_handle_tap()

func _handle_tap() -> void:
	lane_from_x = player_x
	state.toggle_lane()
	lane_anim_time = 0.088
	tutorial_taps += 1
	queue_redraw()

func _process(delta: float) -> void:
	if state.run_state == HalfStepState.RunState.PLAYING:
		cadence_elapsed_ms += delta * 1000.0
		while cadence_elapsed_ms >= state.cadence_ms() and state.run_state == HalfStepState.RunState.PLAYING:
			cadence_elapsed_ms -= state.cadence_ms()
			_resolve_step()
	else:
		death_time += delta
	cloud_phase += delta * (1.0 + state.score / 24.0) * float(state.current_zone().boost)
	impact_time = maxf(0.0, impact_time - delta)
	lane_anim_time = maxf(0.0, lane_anim_time - delta)
	zone_reveal_time = maxf(0.0, zone_reveal_time - delta)
	milestone_time = maxf(0.0, milestone_time - delta)
	shake_time = maxf(0.0, shake_time - delta)
	if lane_anim_time > 0.0:
		var t := 1.0 - lane_anim_time / 0.088
		player_x = lerpf(lane_from_x, LANE_X[state.lane], 1.0 - pow(1.0 - t, 3.0))
	else:
		player_x = LANE_X[state.lane]
	for particle: Dictionary in particles:
		particle.life = float(particle.life) - delta
		particle.position = Vector2(particle.position) + Vector2(particle.velocity) * delta
	particles = particles.filter(func(p: Dictionary) -> bool: return float(p.life) > 0.0)
	queue_redraw()

func _resolve_step() -> void:
	var success := state.resolve_landing()
	if success:
		impact_time = 0.19
		shake_time = 0.08
		_spawn_impact_particles(Vector2(LANE_X[state.lane], PLAYER_Y + 30.0))
		tone_player.play_success_note(state.note_index if state.note_index > 0 else 24)
		if state.best_score > best_score:
			best_score = state.best_score
			save_file.set_value("score", "best", best_score)
			save_file.save("user://half_step.cfg")
		var zone_name := str(state.current_zone().name)
		if zone_name != previous_zone:
			previous_zone = zone_name
			zone_reveal_time = 1.25
		if not ZoneConfig.milestone_for_score(state.score).is_empty():
			milestone_time = 1.8
	else:
		death_time = 0.0
		tone_player.play_fall()

func _spawn_impact_particles(center: Vector2) -> void:
	var directions := [Vector2(-1,-0.65),Vector2(1,-0.65),Vector2(-1,0.55),Vector2(1,0.55)]
	for i in directions.size():
		particles.append({"position":center,"velocity":directions[i]*130.0,"life":0.16,"gold":i%2==1})

func _restart() -> void:
	state.retry(Time.get_ticks_usec())
	state.best_score = best_score
	cadence_elapsed_ms = 0.0
	impact_time = 0.0
	death_time = 0.0
	tutorial_taps = 0
	particles.clear()
	player_x = LANE_X[0]
	previous_zone = str(state.current_zone().name)
	queue_redraw()

func _share_score() -> void:
	if OS.has_feature("web"):
		var text := "HALF STEP %d · Reached %s. Can you beat this?" % [state.score,state.current_zone().name]
		JavaScriptBridge.eval("navigator.share?navigator.share({title:'HALF STEP',text:%s,url:location.href}):navigator.clipboard.writeText(%s)" % [JSON.stringify(text),JSON.stringify(text)])

func _draw() -> void:
	var shake := Vector2.ZERO
	if shake_time > 0.0:
		shake = Vector2(sin(shake_time*190.0)*3.0,cos(shake_time*170.0)*2.0)
	draw_set_transform(shake)
	_draw_sky()
	_draw_atmosphere()
	_draw_clouds()
	_draw_wind()
	_draw_platform_rows()
	_draw_player()
	_draw_particles()
	draw_set_transform(Vector2.ZERO)
	_draw_hud()
	if state.run_state == HalfStepState.RunState.DEAD:
		_draw_result()

func _draw_sky() -> void:
	var zone := state.current_zone()
	for band in 40:
		var t := float(band)/39.0
		draw_rect(Rect2(0,band*VIEW.y/40.0,VIEW.x,VIEW.y/40.0+1),Color(zone.top).lerp(Color(zone.bottom),t))

func _draw_atmosphere() -> void:
	var zone := state.current_zone()
	var star_alpha := float(zone.stars)
	if star_alpha > 0:
		for i in 68:
			var x := fmod(31.0+i*109.0,VIEW.x)
			var y := fmod(17.0+i*157.0,VIEW.y*0.72)
			var size := 2.0 if i%5 else 4.0
			draw_rect(Rect2(x,y,size,size),Color(1,1,1,star_alpha*(0.42+(i%4)*0.13)))
	if state.score >= 210:
		var accent := Color(zone.accent)
		for i in 5:
			var pts := PackedVector2Array([Vector2(-120,250+i*32),Vector2(180,160+i*22),Vector2(480,260+i*28),Vector2(840,120+i*18)])
			draw_polyline(pts,Color(accent,0.10+i*0.015),28,true)
	var scan_alpha := float(zone.scan)
	if scan_alpha > 0:
		for y in range(0,int(VIEW.y),8):
			draw_line(Vector2(0,y),Vector2(VIEW.x,y),Color(1,1,1,scan_alpha*0.12),2)

func _draw_clouds() -> void:
	var speed := 95.0*float(state.current_zone().boost)
	for i in 18:
		var depth := 0.52+(i%7)*0.11
		var y := fmod(i*137.0+cloud_phase*speed*depth,VIEW.y+260)-150
		var x := 30.0+fmod(i*211.0,VIEW.x-180)
		var scale := depth+maxf(0,y/VIEW.y)*0.28
		_draw_pixel_cloud(Vector2(x,y),scale,0.58+(i%2)*0.25)

func _draw_pixel_cloud(position: Vector2, scale: float, alpha: float) -> void:
	var unit := 8.0*scale
	var blocks := [Vector2(0,2),Vector2(1,1),Vector2(2,0),Vector2(3,0),Vector2(4,1),Vector2(5,1),Vector2(6,2),Vector2(1,2),Vector2(2,2),Vector2(3,2),Vector2(4,2),Vector2(5,2)]
	for block: Vector2 in blocks:
		draw_rect(Rect2(position+block*unit,Vector2(unit+1,unit+1)),Color(1,1,1,alpha))

func _draw_wind() -> void:
	var alpha := clampf((state.score-10.0)/45.0,0,0.95)
	if alpha <= 0:
		return
	for i in 20:
		var y := fmod(i*83.0+cloud_phase*(250+state.score*2),VIEW.y+120)-60
		var x := fmod(19.0+i*127.0,VIEW.x)
		var length := 28.0*(1.0+minf(4.0,state.score/45.0))
		draw_rect(Rect2(x,y,4,length),Color(1,1,1,alpha))

func _draw_platform_rows() -> void:
	var progress := cadence_elapsed_ms/state.cadence_ms()
	for row_index in 7:
		var safe_lane: int = state.upcoming_lanes[row_index]
		var y := PLAYER_Y-ROW_SPACING-row_index*ROW_SPACING+progress*ROW_SPACING
		for lane_index in 2:
			var center := Vector2(LANE_X[lane_index],y)
			if lane_index == safe_lane:
				_draw_platform(center,1,false)
			else:
				_draw_empty_platform(center)
	if impact_time > 0:
		var t := 1.0-impact_time/0.19
		_draw_platform(Vector2(LANE_X[state.lane],PLAYER_Y+25),1.0+t*0.28,true,(1-t)*0.58)

func _draw_platform(center: Vector2, scale: float, ghost: bool, alpha: float=1.0) -> void:
	var size := PLATFORM_SIZE*scale
	var rect := Rect2(center-size*0.5,size)
	draw_rect(Rect2(rect.position+Vector2(0,12*scale),rect.size),Color(0.08,0.12,0.15,alpha*0.85))
	var platform_color := Color("2b3846")
	platform_color.a = alpha
	draw_rect(rect,platform_color,not ghost,5.0 if ghost else -1.0)
	if not ghost:
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,9*scale)),Color("42586d",alpha))
		draw_rect(Rect2(rect.position+Vector2(16*scale,24*scale),Vector2(rect.size.x-32*scale,4*scale)),Color(1,1,1,alpha*0.12))

func _draw_empty_platform(center: Vector2) -> void:
	var rect := Rect2(center-PLATFORM_SIZE*0.5,PLATFORM_SIZE)
	var c := Color(1,1,1,0.22)
	for x in range(int(rect.position.x),int(rect.end.x),28):
		draw_line(Vector2(x,rect.position.y),Vector2(minf(x+14,rect.end.x),rect.position.y),c,5)
		draw_line(Vector2(x,rect.end.y),Vector2(minf(x+14,rect.end.x),rect.end.y),c,5)
	for y in range(int(rect.position.y),int(rect.end.y),28):
		draw_line(Vector2(rect.position.x,y),Vector2(rect.position.x,minf(y+14,rect.end.y)),c,5)
		draw_line(Vector2(rect.end.x,y),Vector2(rect.end.x,minf(y+14,rect.end.y)),c,5)

func _draw_player() -> void:
	var y := PLAYER_Y
	var scale_factor := 1.0
	var alpha := 1.0
	var rotation := 0.0
	if state.run_state == HalfStepState.RunState.PLAYING:
		var p := cadence_elapsed_ms/state.cadence_ms()
		if p > 0.72:
			var hop := sin((p-0.72)/0.28*PI)
			y -= hop*38
			scale_factor = 1.0+hop*0.05
	else:
		var t := clampf(death_time/0.76,0,1)
		y += t*10
		scale_factor = lerpf(1,0.04,t)
		alpha = 1-t
		rotation = t*2.8
	for cell: Array in PLAYER_CELLS:
		var local := (Vector2(float(cell[1]),float(cell[2]))-Vector2(2.5,5))*PLAYER_PIXEL*scale_factor
		var center := Vector2(player_x,y)+local.rotated(rotation)
		draw_set_transform(center,rotation)
		draw_rect(Rect2(-PLAYER_PIXEL*scale_factor*0.5,-PLAYER_PIXEL*scale_factor*0.5,PLAYER_PIXEL*scale_factor+0.5,PLAYER_PIXEL*scale_factor+0.5),_player_color(str(cell[0]),alpha))
	draw_set_transform(Vector2.ZERO)

func _player_color(kind: String, alpha: float) -> Color:
	match kind:
		"dark": return Color(0.62,0.29,0.27,alpha)
		"eye": return Color(1,1,1,alpha)
		"boot": return Color(0.35,0.19,0.19,alpha)
		"belt": return Color(1,0.89,0.56,alpha)
		"cheek": return Color(1,0.71,0.67,alpha)
	return Color(0.94,0.42,0.36,alpha)

func _draw_particles() -> void:
	for particle: Dictionary in particles:
		var alpha := clampf(float(particle.life)/0.16,0,1)
		var color := Color("ffe9a8") if bool(particle.gold) else Color.WHITE
		color.a = alpha
		draw_rect(Rect2(Vector2(particle.position)-Vector2(5,5),Vector2(10,10)),color)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(0,112),str(state.score),HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,92,Color.WHITE)
	draw_string(font,Vector2(0,160),"BEST %d"%best_score,HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,24,Color(1,1,1,0.84))
	if tutorial_taps < 2 and state.run_state == HalfStepState.RunState.PLAYING:
		var pulse := 0.72+sin(Time.get_ticks_msec()*0.006)*0.20
		draw_string(font,Vector2(0,1110),"TAP TO SWITCH SIDES",HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,30,Color(1,1,1,pulse))
		draw_string(font,Vector2(0,1148),"A NEW SKY OPENS THE FARTHER YOU GO",HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,17,Color(1,1,1,pulse*0.8))
	if impact_time > 0:
		draw_string(font,Vector2(0,405),"FLOW %d"%state.score,HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,20,Color(1,1,1,impact_time/0.19*0.82))
	if zone_reveal_time > 0:
		draw_string(font,Vector2(0,330),str(state.current_zone().name),HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,32,Color.WHITE)
	if milestone_time > 0:
		draw_string(font,Vector2(0,330),ZoneConfig.milestone_for_score(state.score),HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,32,Color.WHITE)

func _draw_result() -> void:
	if death_time < 0.45:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0,0,VIEW.x,VIEW.y),Color(0.13,0.25,0.36,0.38))
	draw_rect(Rect2(66,330,588,570),Color.WHITE)
	draw_rect(Rect2(78,342,564,546),Color("f6fbff"))
	draw_rect(Rect2(92,356,536,518),Color("d6e7f1"),false,5)
	draw_string(font,Vector2(0,425),"RUN ENDED",HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,24,Color(0.15,0.21,0.27,0.44))
	draw_string(font,Vector2(0,570),str(state.score),HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,112,Color("263644"))
	draw_string(font,Vector2(0,625),"REACHED · %s"%state.current_zone().name,HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,24,Color("6d8293"))
	var best_line := "NEW BEST!" if state.score>0 and state.score==best_score else "BEST %d"%best_score
	draw_string(font,Vector2(0,675),best_line,HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,25,Color("ef6a5b"))
	draw_rect(Rect2(RETRY_RECT.position+Vector2(0,10),RETRY_RECT.size),Color("111a21"))
	draw_rect(RETRY_RECT,Color("24313d"))
	draw_rect(Rect2(SHARE_RECT.position+Vector2(0,10),SHARE_RECT.size),Color("c7dce9"))
	draw_rect(SHARE_RECT,Color("e7f2f9"))
	draw_string(font,Vector2(RETRY_RECT.position.x,805),"RETRY",HORIZONTAL_ALIGNMENT_CENTER,RETRY_RECT.size.x,28,Color.WHITE)
	draw_string(font,Vector2(SHARE_RECT.position.x,805),"SHARE",HORIZONTAL_ALIGNMENT_CENTER,SHARE_RECT.size.x,28,Color("24313d"))
	draw_string(font,Vector2(0,860),"PLAY · FAIL · SHARE · REPEAT",HORIZONTAL_ALIGNMENT_CENTER,VIEW.x,18,Color(0.15,0.21,0.27,0.45))
