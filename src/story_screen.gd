class_name StoryScreen
extends Node2D

## Plays the intro or the ending as a sequence of frames: a still, a caption,
## a fade. Not video — Godot's web export only carries Theora, and a video large
## enough to look good would dwarf the whole game. Stills stream in as textures
## and localise for free, because the caption is drawn rather than burned in.
##
## Frames whose image is missing still play, painting the sky the frame names,
## so the sequence is testable before any art exists.

signal finished

const INK := Color("f6fbff")
const SKIP := Color(1.0, 1.0, 1.0, 0.62)

var which := "intro"
var time := 0.0
var frame := 0

var _rect := Rect2()
var _skip := Rect2()
var _textures: Dictionary = {}


func play(sequence: String, rect: Rect2) -> void:
	which = sequence
	time = 0.0
	frame = 0
	visible = true
	layout(rect)
	queue_redraw()


func stop() -> void:
	visible = false
	queue_redraw()
	finished.emit()


func layout(rect: Rect2) -> void:
	_rect = rect
	var label := I18n.t("STORY_SKIP")
	var width: float = maxf(74.0, CssText.width(label, 11.0, 1.0) + 26.0)
	_skip = Rect2(rect.end.x - width - 18.0, rect.position.y + 26.0, width, 32.0)


func frames() -> Array[Dictionary]:
	return StoryConfig.frames(which)


## Returns true while the sequence is still running.
func advance(delta_ms: float) -> bool:
	if not visible:
		return false
	time += delta_ms
	var span := StoryConfig.FADE_MS + StoryConfig.FRAME_MS
	while time >= span:
		time -= span
		frame += 1
		if frame >= frames().size():
			stop()
			return false
	queue_redraw()
	return true


## A tap on SKIP ends the sequence; anywhere else steps to the next frame, so a
## player who has seen it can get through fast without hunting for the button.
func handle_press(position: Vector2) -> void:
	if _skip.has_point(position):
		stop()
		return
	frame += 1
	time = 0.0
	if frame >= frames().size():
		stop()
		return
	queue_redraw()


func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = ResourceLoader.load(path) as Texture2D
	_textures[path] = texture
	return texture


func _draw() -> void:
	var list := frames()
	if frame < 0 or frame >= list.size():
		return
	var current := list[frame]
	var size := _rect.size
	draw_set_transform(_rect.position)
	var zone: Dictionary = ZoneConfig.ZONES[clampi(int(current.get("sky", 0)), 0, ZoneConfig.ZONES.size() - 1)]
	CssPaint.linear_gradient(self, Rect2(Vector2.ZERO, size), 175.0, [[0.0, zone.top], [1.0, zone.bottom]])

	var texture := _texture(String(current.get("image", "")))
	if texture != null:
		# Cover the frame without distorting it, the way a video would.
		var source := Vector2(texture.get_size())
		var scale: float = maxf(size.x / source.x, size.y / source.y)
		var drawn := source * scale
		draw_texture_rect(texture, Rect2((size - drawn) * 0.5, drawn), false)

	# The caption fades in, holds, and is never burned into the image, so a new
	# language costs a row in the table rather than a new render.
	var fade := clampf(time / StoryConfig.FADE_MS, 0.0, 1.0)
	var eased := CssAnim.curve(CssAnim.EASE, fade)
	draw_rect(Rect2(Vector2(0.0, size.y * 0.62), Vector2(size.x, size.y * 0.38)),
		Color("06101f", 0.42 * eased))
	CssText.draw_centered(self, I18n.t(String(current.text)), 24.0, size.x - 48.0,
		size.y * 0.72, 17.0, 0.0, Color(INK, eased))

	var skip := Rect2(_skip.position - _rect.position, _skip.size)
	draw_rect(skip, Color(1.0, 1.0, 1.0, 0.14))
	CssText.draw_centered(self, I18n.t("STORY_SKIP"), skip.position.x, skip.size.x,
		skip.position.y + 9.0, 11.0, 1.0, SKIP)

	# Which frame of how many, so skipping never feels like leaving something.
	var dot_y := size.y - 34.0
	for i in list.size():
		var x := size.x * 0.5 + (float(i) - float(list.size() - 1) * 0.5) * 16.0
		draw_circle(Vector2(x, dot_y), 3.0,
			Color(1.0, 1.0, 1.0, 0.85 if i == frame else 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
