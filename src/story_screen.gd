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
const SKIP := Color(1.0, 1.0, 1.0, 0.92)

var which := "intro"
var time := 0.0
var frame := 0
## Read by the memorial frame. Left null in tests that only drive the fades.
var progress: Progress

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


## What the corner button says. "Skip" is right for a frame that is on its way
## somewhere; the memorial is not on its way anywhere, so there it closes.
func corner_key() -> String:
	return "TAP_TO_CLOSE" if showing_memorial() else "STORY_SKIP"


func layout(rect: Rect2) -> void:
	_rect = rect
	var width: float = maxf(74.0, maxf(CssText.width(I18n.t("STORY_SKIP"), 11.0, 1.0),
		CssText.width(I18n.t("TAP_TO_CLOSE"), 11.0, 1.0)) + 26.0)
	_skip = Rect2(rect.end.x - width - 18.0, rect.position.y + 26.0, width, 32.0)


func frames() -> Array[Dictionary]:
	return StoryConfig.frames(which)


## True when the frame on screen is the memorial, which needs its own music:
## the ending's track is a one-shot and this card holds indefinitely.
func showing_memorial() -> bool:
	var list := frames()
	return visible and frame >= 0 and frame < list.size() \
		and bool(list[frame].get("memorial", false))


## True when frame [param index] waits for the player instead of timing out.
func holds(index: int) -> bool:
	var list := frames()
	return index >= 0 and index < list.size() and bool(list[index].get("hold", false))


## Returns true while the sequence is still running.
func advance(delta_ms: float) -> bool:
	if not visible:
		return false
	time += delta_ms
	# A held frame fades in and then waits. The memorial is the last thing the
	# player sees of this cat, and taking it away on a timer would be the one
	# unkind thing in the game.
	if holds(frame):
		time = minf(time, StoryConfig.FADE_MS)
		queue_redraw()
		return true
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
	if bool(current.get("memorial", false)):
		_draw_memorial(size, eased)
	else:
		draw_rect(Rect2(Vector2(0.0, size.y * 0.62), Vector2(size.x, size.y * 0.38)),
			Color("06101f", 0.42 * eased))
		CssText.draw_centered(self, I18n.t(String(current.text)), 24.0, size.x - 48.0,
			size.y * 0.72, 17.0, 0.0, Color(INK, eased))

	# A dark plate, not a translucent white one. Two of the ending frames are
	# nearly white, and a white button on them is a button nobody can see.
	var skip := Rect2(_skip.position - _rect.position, _skip.size)
	var label := I18n.t(corner_key())
	Shapes.rounded_rect(self, skip, 7.0, Color("0b1526", 0.55))
	CssText.draw_centered(self, label, skip.position.x, skip.size.x, skip.position.y + 9.0,
		CssText.fit_size(label, skip.size.x - 12.0, 11.0, 1.0, 8.0), 1.0, SKIP)

	# Which frame of how many, so skipping never feels like leaving something.
	var dot_y := size.y - 34.0
	for i in list.size():
		var x := size.x * 0.5 + (float(i) - float(list.size() - 1) * 0.5) * 16.0
		draw_circle(Vector2(x, dot_y), 3.0,
			Color(1.0, 1.0, 1.0, 0.85 if i == frame else 0.3), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


## The memorial: a real cat, a real date, and what this player did with her.
##
## Everything on it comes from the save file, so it is a different card for
## every person who reaches it — which is the only way a number like "the times
## she came back" means anything.
func _draw_memorial(size: Vector2, eased: float) -> void:
	var ink := Color("2b3a49")
	var muted := Color("5f7789")
	var width: float = minf(size.x * 0.84, 352.0)
	var radius: float = minf(width * 0.30, 104.0)

	# Laid out top down first, so the card is exactly as tall as what is on it.
	# A fixed height leaves a slab of empty paper under the last number, which
	# is the one thing on this screen that would look careless.
	var portrait_top := 34.0
	var name_top := portrait_top + radius * 2.0 + 24.0
	var date_top := name_top + CssText.line_height(22.0) + 4.0
	var rule_top := date_top + CssText.line_height(12.0) + 18.0
	var lines_top := rule_top + 18.0
	var line_step := CssText.line_height(13.0) + 6.0
	var stats_top := lines_top + line_step * 2.0 + 14.0
	var stat_step := CssText.line_height(9.0) + 4.0 + CssText.line_height(17.0) + 14.0
	var note_top := stats_top + stat_step * 2.0 + 6.0
	var height := note_top + CssText.line_height(10.0) + 30.0

	var card := Rect2(Vector2((size.x - width) * 0.5, maxf(18.0, (size.y - height) * 0.44)),
		Vector2(width, height))
	# A lamp behind the card, so the last sky of the ending warms toward the
	# room the story started in instead of staying out in the cold.
	CssPaint.radial_gradient_at(self, card.get_center() - Vector2(0.0, card.size.y * 0.22),
		card.size.y * 0.86, [[0.0, Color("ffd9a8", 0.42 * eased)],
		[1.0, Color("ffd9a8", 0.0)]])
	Shapes.rounded_rect(self, Rect2(card.position + Vector2(0.0, 8.0), card.size), 22.0,
		Color(0.04, 0.08, 0.14, 0.16 * eased))
	Shapes.rounded_rect(self, card, 22.0, Color("fbf7f0", 0.97 * eased))

	var portrait := card.position + Vector2(width * 0.5, portrait_top + radius)
	Shapes.fill(self, Shapes.circle_polygon(portrait, radius + 6.0), Color("e8ddce", eased))
	draw_set_transform(_rect.position + portrait, 0.0,
		Vector2.ONE * (radius / StoryArt.PORTRAIT_RADIUS))
	if not StoryArt.draw_tori_photo(self):
		StoryArt.draw_tori_portrait(self)
	draw_set_transform(_rect.position)

	CssText.draw_centered(self, I18n.t("MEMORIAL_NAME"), card.position.x, width,
		card.position.y + name_top, 22.0, 1.0, Color(ink, eased))
	CssText.draw_centered(self, StoryConfig.MEMORIAL_DATE, card.position.x, width,
		card.position.y + date_top, 12.0, 2.4, Color(muted, eased))
	draw_rect(Rect2(card.get_center().x - 26.0, card.position.y + rule_top, 52.0, 1.0),
		Color("d8ccbd", eased))
	for i in 2:
		CssText.draw_centered(self, I18n.t("MEMORIAL_LINE_%d" % (i + 1)), card.position.x + 18.0,
			width - 36.0, card.position.y + lines_top + line_step * float(i), 13.0, 0.0,
			Color(ink, eased))

	# Four numbers, two by two. They are hers, not the game's, so they carry no
	# level, no rank and nothing to beat.
	var stats := _memorial_stats()
	var column := (width - 36.0) * 0.5
	for i in stats.size():
		var left := card.position.x + 18.0 + float(i % 2) * column
		var top := card.position.y + stats_top + float(i / 2) * stat_step
		var label := String(stats[i][0])
		CssText.draw_centered(self, label, left, column, top,
			CssText.fit_size(label, column - 6.0, 9.0, 1.2, 7.0), 1.2, Color(muted, eased))
		CssText.draw_centered(self, String(stats[i][1]), left, column,
			top + CssText.line_height(9.0) + 4.0, 17.0, 0.0, Color(ink, eased))

	# The codex opens here. Saying so on this card is the whole handover: the
	# walk is finished, and now there are other cats to walk it with.
	CssText.draw_centered(self, I18n.t("CODEX_OPENED"), card.position.x + 18.0, width - 36.0,
		card.position.y + note_top, 10.0, 1.4, Color(muted, eased))


## Label and value for each memorial number. Falls (the runs that ended) and the
## number of runs are the same count in this game — a run only ever ends one way
## — so the card shows it once and spends the fourth slot on the calendar
## instead, which is the number that grows when nothing else does.
func _memorial_stats() -> Array:
	var steps := 0
	var falls := 0
	var days := 0
	var best := 0
	if progress != null:
		steps = progress.total_steps
		falls = progress.total_falls
		days = maxi(1, progress.days_played)
		best = int(progress.bests.get(CatConfig.STARTER, 0))
	return [
		[I18n.t("MEMORIAL_STEPS"), str(steps)],
		[I18n.t("MEMORIAL_FALLS"), str(falls)],
		[I18n.t("MEMORIAL_DAYS"), str(days)],
		[I18n.t("MEMORIAL_BEST"), str(best)],
	]
