class_name CssText
extends RefCounted

## Text drawing that follows CSS box rules closely enough to place the
## prototype's HUD without hand-tuned offsets.
##
## The prototype styles every label with `font-family:ui-monospace,...,monospace`
## at `font-weight:900`/`1000` plus an explicit `letter-spacing`. Godot's fallback
## font has neither a monospace design nor coverage of the scripts the game
## ships in, so the port bundles subsets built from the translation table (see
## `tools/build_fonts.py`).

const MONO_PATH := "res://assets/fonts/HalfStepMono.ttf"
## Per-script fallbacks. Each is a subset built from the translation table, so a
## script costs only the glyphs its languages actually use — see
## `tools/build_fonts.py`. Order does not matter: Godot walks the list until a
## glyph is found.
const FALLBACK_PATHS: PackedStringArray = [
	"res://assets/fonts/HalfStepLatin.ttf",
	"res://assets/fonts/HalfStepKR.ttf",
	"res://assets/fonts/HalfStepJP.ttf",
	"res://assets/fonts/HalfStepSC.ttf",
	"res://assets/fonts/HalfStepTC.ttf",
]
## CSS `line-height:normal` lands near 1.17 for the fonts in use.
const NORMAL_LINE_HEIGHT := 1.17

static var _font: Font

## --- playtest instrumentation ------------------------------------------------
##
## Off in a shipped build and free when off: one branch per string drawn.
## `tools/playtest.gd` turns these on to find the two defects that no gameplay
## test can see — a translation that does not fit the box it was centred in, and
## text drawn in a colour the background happens to share.
##
## [member debug_tint] overrides every colour, so the harness can render the
## same frame twice and subtract one from the other to get an exact mask of
## which pixels are text. See PROTOTYPE_HISTORY.md on white-on-white.
static var recording := false
static var debug_tint := Color(0.0, 0.0, 0.0, 0.0)
## Strings whose measured width did not fit the box they were centred in.
static var overflows: Array[Dictionary] = []


static func start_recording() -> void:
	recording = true
	overflows.clear()


static func font() -> Font:
	if _font != null:
		return _font
	var mono := ResourceLoader.load(MONO_PATH) as Font
	if mono == null:
		_font = ThemeDB.fallback_font
		return _font
	var fallbacks: Array[Font] = []
	for path in FALLBACK_PATHS:
		var face := ResourceLoader.load(path) as Font
		if face != null:
			fallbacks.append(face)
	mono.fallbacks = fallbacks
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
	if not I18n.letters_separable():
		return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size)).x
	var total := 0.0
	for character in text:
		total += f.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size)).x + letter_spacing
	return total


## The largest size at or below [param size] at which [param text] fits inside
## [param box_width], down to [param minimum].
##
## The game ships in twelve languages and its buttons are sized in pixels. "Tentar
## de novo" is 126 px of Portuguese in a 93 px button that says "Retry" in
## English, and no amount of care over one layout fixes that for the next
## language. Labels shrink instead of spilling.
static func fit_size(text: String, box_width: float, size: float, letter_spacing: float,
		minimum := 8.0) -> float:
	var chosen := size
	while chosen > minimum and width(text, chosen, letter_spacing) > box_width:
		chosen -= 1.0
	return chosen


## Draws [param text] with its left edge at [param origin] (top-left of the line
## box), honouring letter-spacing.
static func draw_at(canvas: CanvasItem, text: String, origin: Vector2, size: float, letter_spacing: float, color: Color) -> void:
	var f := font()
	if debug_tint.a > 0.0:
		color = debug_tint
	var pen := Vector2(origin.x, origin.y + baseline(size))
	if not I18n.letters_separable():
		# Arabic joins its letters and Indic scripts form clusters, so splitting
		# the string would destroy the word. Such a locale loses letter-spacing
		# rather than its text.
		canvas.draw_string(f, pen, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size), color)
		return
	for character in text:
		canvas.draw_string(f, pen, character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size), color)
		pen.x += f.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size)).x + letter_spacing


## `text-align:center` inside a box spanning [param left] .. [param left]+[param box_width].
static func draw_centered(canvas: CanvasItem, text: String, left: float, box_width: float, top: float, size: float, letter_spacing: float, color: Color) -> void:
	var text_width := width(text, size, letter_spacing)
	if recording and text_width > box_width + 0.5:
		overflows.append({
			"text": text,
			"locale": TranslationServer.get_locale(),
			"width": text_width,
			"box": box_width,
			"size": size,
		})
	draw_at(canvas, text, Vector2(left + (box_width - text_width) * 0.5, top), size, letter_spacing, color)


## Centred text with a dark rim all the way round it.
##
## A one-sided `text-shadow` is enough over a card. It is not enough over the
## playfield, where the same white number sits over a navy sky one second and a
## white cloud the next — the sky is art the text cannot negotiate with. A rim
## costs eight extra draws and works against anything.
##
## `tools/playtest_check.py` measures this: every string on the HUD is graded
## against the pixels immediately around it in a real screenshot.
static func draw_centered_rimmed(canvas: CanvasItem, text: String, left: float, box_width: float,
		top: float, size: float, letter_spacing: float, color: Color, rim: Color,
		thickness := 2.0) -> void:
	var text_width := width(text, size, letter_spacing)
	var origin := Vector2(left + (box_width - text_width) * 0.5, top)
	for step in 8:
		var angle := TAU * float(step) / 8.0
		draw_at(canvas, text, origin + Vector2(cos(angle), sin(angle)) * thickness,
			size, letter_spacing, rim)
	draw_at(canvas, text, origin, size, letter_spacing, color)


## Centred text with a CSS `text-shadow: 0 <offset>px 0 <shadow>` underneath.
static func draw_centered_shadowed(canvas: CanvasItem, text: String, left: float, box_width: float, top: float, size: float, letter_spacing: float, color: Color, shadow: Color, shadow_offset: float) -> void:
	draw_centered(canvas, text, left, box_width, top + shadow_offset, size, letter_spacing, shadow)
	draw_centered(canvas, text, left, box_width, top, size, letter_spacing, color)
