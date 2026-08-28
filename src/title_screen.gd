class_name TitleScreen
extends Node2D

## The first screen on a cold launch. A tap starts the run — and on a first ever
## launch, the intro plays between the two.
##
## It is drawn over the live playfield rather than replacing it, so the clouds
## behind the wordmark are the game's own parallax, still drifting. A static
## background image here would be a worse version of what the game already does.
##
## The wordmark is `assets/story/wordmark.png` when that file exists, so it can
## be replaced with real lettering; without it the title is drawn from the
## translation table, which is what keeps twelve languages honest.

signal started

const WORDMARK := "res://assets/story/wordmark.png"
const INK := Color("f6fbff")
const PULSE_MS := 1600.0

var progress: Progress
var time := 0.0

var _rect := Rect2()
var _texture: Texture2D = null
var _looked := false


func open(from: Progress, rect: Rect2) -> void:
	progress = from
	visible = true
	time = 0.0
	layout(rect)
	queue_redraw()


func close() -> void:
	visible = false
	queue_redraw()
	started.emit()


func layout(rect: Rect2) -> void:
	_rect = rect


func advance(delta_ms: float) -> void:
	time = fmod(time + delta_ms, PULSE_MS)
	queue_redraw()


func handle_press(_position: Vector2) -> void:
	close()


func _wordmark() -> Texture2D:
	if not _looked:
		_looked = true
		if ResourceLoader.exists(WORDMARK):
			_texture = ResourceLoader.load(WORDMARK) as Texture2D
	return _texture


func _draw() -> void:
	var size := _rect.size
	draw_set_transform(_rect.position)
	# A wash so the wordmark holds against whatever sky is behind it, without
	# hiding the motion that makes the screen feel alive.
	CssPaint.linear_gradient(self, Rect2(Vector2.ZERO, size), 180.0, [
		[0.0, Color("0b1526", 0.52)], [0.55, Color("0b1526", 0.16)], [1.0, Color("0b1526", 0.62)],
	])

	var centre := size * Vector2(0.5, 0.34)
	var mark := _wordmark()
	if mark != null:
		var source := Vector2(mark.get_size())
		var width: float = minf(size.x * 0.72, source.x)
		var drawn := source * (width / source.x)
		draw_texture_rect(mark, Rect2(centre - drawn * 0.5, drawn), false)
	else:
		CssText.draw_centered(self, I18n.t("TITLE"), 0.0, size.x,
			centre.y - CssText.line_height(56.0) * 0.5, 56.0, 6.0, INK)
	CssText.draw_centered(self, I18n.t("SUBTITLE"), 0.0, size.x,
		centre.y + 44.0, 15.0, 2.4, Color(INK, 0.82))

	# Tori waiting on a bridge, breathing. The tail sway is the game's own.
	var deck := Rect2(Vector2(size.x * 0.5 - 43.0, size.y * 0.60), Vector2(86.0, 28.0))
	Shapes.rounded_rect(self, Rect2(deck.position + Vector2(0.0, 7.0), deck.size), 9.0,
		Color("151d24", 0.5))
	Shapes.rounded_rect(self, deck, 9.0, Color("2b3846"))
	draw_set_transform(_rect.position + deck.get_center() + Vector2(0.0, -6.0), 0.0, Vector2(1.2, 1.2))
	Art.draw_cat(self, 1.0, fmod(time / PULSE_MS, 1.0), 0.0,
		CatConfig.by_id(progress.equipped if progress != null else CatConfig.STARTER))
	draw_set_transform(_rect.position)

	var half := clampf(time / PULSE_MS, 0.0, 1.0)
	var pulse := half * 2.0 if half <= 0.5 else (1.0 - half) * 2.0
	CssText.draw_centered(self, I18n.t("TAP_TO_START"), 0.0, size.x, size.y * 0.80, 13.0, 3.0,
		Color(INK, lerpf(0.45, 0.95, CssAnim.curve(CssAnim.EASE, pulse))))
	draw_set_transform(Vector2.ZERO)
