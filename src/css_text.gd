class_name CssText
extends RefCounted

## Text drawing that follows CSS box rules closely enough to place the
## prototype's HUD without hand-tuned offsets.
##
## The prototype styles every label with `font-family:ui-monospace,...,monospace`
## at `font-weight:900`/`1000` plus an explicit `letter-spacing`. Godot's fallback
## font has neither a monospace design nor Hangul coverage, so the port ships
## subsets of DejaVu Sans Mono Bold and GNU Unifont (see `tools/build_fonts.py`).

const MONO_PATH := "res://assets/fonts/HalfStepMono.ttf"
const KOREAN_PATH := "res://assets/fonts/HalfStepKR.ttf"
## CSS `line-height:normal` lands near 1.17 for the fonts in use.
const NORMAL_LINE_HEIGHT := 1.17

static var _font: Font


static func font() -> Font:
	if _font != null:
		return _font
	var mono := ResourceLoader.load(MONO_PATH) as Font
	var korean := ResourceLoader.load(KOREAN_PATH) as Font
	if mono == null:
		_font = ThemeDB.fallback_font
		return _font
	if korean != null:
		mono.fallbacks = [korean]
	_font = mono
	return _font


static func line_height(size: float) -> float:
	return size * NORMAL_LINE_HEIGHT


## Distance from the top of the line box to the baseline.
static func baseline(size: float) -> float:
	var f := font()
	var ascent := f.get_ascent(int(size))
	var descent := f.get_descent(int(size))
	return (line_height(size) - (ascent + descent)) * 0.5 + ascent


## Advance width including CSS letter-spacing, which is added after every
## character — the trailing one included.
static func width(text: String, size: float, letter_spacing: float) -> float:
	var f := font()
	var total := 0.0
	for character in text:
		total += f.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size)).x + letter_spacing
	return total


## Draws [param text] with its left edge at [param origin] (top-left of the line
## box), honouring letter-spacing.
static func draw_at(canvas: CanvasItem, text: String, origin: Vector2, size: float, letter_spacing: float, color: Color) -> void:
	var f := font()
	var pen := Vector2(origin.x, origin.y + baseline(size))
	for character in text:
		canvas.draw_string(f, pen, character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size), color)
		pen.x += f.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size)).x + letter_spacing


## `text-align:center` inside a box spanning [param left] .. [param left]+[param box_width].
static func draw_centered(canvas: CanvasItem, text: String, left: float, box_width: float, top: float, size: float, letter_spacing: float, color: Color) -> void:
	var text_width := width(text, size, letter_spacing)
	draw_at(canvas, text, Vector2(left + (box_width - text_width) * 0.5, top), size, letter_spacing, color)


## Centred text with a CSS `text-shadow: 0 <offset>px 0 <shadow>` underneath.
static func draw_centered_shadowed(canvas: CanvasItem, text: String, left: float, box_width: float, top: float, size: float, letter_spacing: float, color: Color, shadow: Color, shadow_offset: float) -> void:
	draw_centered(canvas, text, left, box_width, top + shadow_offset, size, letter_spacing, shadow)
	draw_centered(canvas, text, left, box_width, top, size, letter_spacing, color)
