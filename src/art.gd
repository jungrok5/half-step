class_name Art
extends RefCounted

## The game's vector art, in one place so the playfield and the share image
## never drift apart.
##
## The camera sits high in the sky and looks straight down, the way a vertical
## scrolling flight game does. Everything is drawn from that viewpoint:
##
## - the cat is seen from above, so what shows is its back, its ears and its
##   tail — never a side profile
## - a cloud is a flat mass seen from above, an irregular blob. It must NOT have
##   the flat bottom and billowing top of a cloud seen from the side
## - depth comes from parallax layers, including clouds between the camera and
##   the cat, which drift across the top of everything
##
## Flat fills, no outlines, no pixel grid. Edges are smoothed by [method
## Shapes.fill] because the Compatibility renderer has no 2D MSAA.

const FUR_COLOR := Color("ef6a5b")
const FUR_DARK_COLOR := Color("cf5347")
const PAW_COLOR := Color("ffeee7")
const INNER_EAR_COLOR := Color("ff9d8e")
const EYE_COLOR := Color("2f2020")

## The cat travels up the screen, so it faces -Y. Coordinates are relative to
## its centre, sized to sit on an 86px wide bridge.
##
## There is no face. Straight down from above you see the back of a cat's head,
## not its eyes — what tells you which end is the front is the ears, the
## forehead markings and the whiskers poking out to the sides.
const HEAD := [Vector2(0.0, -13.0), 10.0]
## Ear shapes, left side only — the right is mirrored in [method ears]. Shape
## is the strongest silhouette cue between cats, readable further away than any
## colour.
const EARS := {
	"pricked": [
		[Vector2(-9.6, -17.5), Vector2(-3.4, -21.5), Vector2(-8.2, -26.0)],
		[Vector2(-8.6, -18.6), Vector2(-5.0, -21.0), Vector2(-7.9, -23.6)],
	],
	"folded": [
		[Vector2(-9.6, -17.5), Vector2(-3.8, -20.2), Vector2(-9.0, -22.2)],
		[Vector2(-8.6, -18.4), Vector2(-5.4, -20.0), Vector2(-8.4, -21.2)],
	],
	"curl": [
		[Vector2(-9.6, -17.5), Vector2(-3.4, -21.5), Vector2(-12.6, -24.4)],
		[Vector2(-8.7, -18.5), Vector2(-5.2, -21.0), Vector2(-10.6, -22.6)],
	],
	"tufted": [
		[Vector2(-9.8, -17.5), Vector2(-3.4, -21.5), Vector2(-9.6, -29.2)],
		[Vector2(-8.6, -18.6), Vector2(-5.0, -21.2), Vector2(-8.4, -24.6)],
	],
}
## The tabby "M" every cat wears on its forehead, which from above is the
## clearest sign of which way the head is pointing.
const HEAD_MARKS := [
	[Vector2(0.0, -17.6), Vector2(1.3, 3.0)],
	[Vector2(-3.8, -16.8), Vector2(1.1, 2.6)],
	[Vector2(3.8, -16.8), Vector2(1.1, 2.6)],
]
const WHISKERS := [
	[Vector2(-7.5, -12.0), Vector2(-17.0, -14.5)],
	[Vector2(-7.5, -10.0), Vector2(-16.5, -9.5)],
	[Vector2(7.5, -12.0), Vector2(17.0, -14.5)],
	[Vector2(7.5, -10.0), Vector2(16.5, -9.5)],
]
const BODY := [Vector2(0.0, 4.0), Vector2(11.5, 14.0)]
## Stretched along the direction of travel while airborne.
const BODY_LEAPING := [Vector2(0.0, 4.0), Vector2(10.2, 16.6)]
## Body width and paw spread per build, relative to `BODY`.
const BUILDS := {
	"slim": 0.87,
	"standard": 1.0,
	"chonk": 1.16,
}
## Tail root, inside the body. The rest is grown from here each frame.
const TAIL_ROOT := Vector2(4.0, 11.0)
const TAIL_SEGMENTS := 5
## Segment count, step length, base thickness and the kink each tail carries.
const TAILS := {
	"long": {"count": 5, "step": 5.4, "base": 4.6, "kink": 0.0},
	"plume": {"count": 5, "step": 5.2, "base": 6.4, "kink": 0.0},
	"bob": {"count": 2, "step": 4.4, "base": 5.0, "kink": 0.0},
	"kinked": {"count": 5, "step": 5.4, "base": 4.6, "kink": -1.55},
}
## Tabby bands across the back.
const STRIPES := [
	[Vector2(0.0, -2.0), Vector2(8.6, 1.7)],
	[Vector2(0.0, 3.5), Vector2(9.6, 1.7)],
	[Vector2(0.0, 9.0), Vector2(8.4, 1.7)],
]
## `spotted` — scattered dots instead of bands.
const SPOTS := [
	[Vector2(-5.0, -3.0), 2.1], [Vector2(4.6, -1.2), 1.9], [Vector2(-2.4, 4.4), 2.3],
	[Vector2(5.6, 6.4), 2.0], [Vector2(-6.2, 9.2), 1.8], [Vector2(1.4, 11.4), 2.1],
	[Vector2(-1.0, -6.6), 1.6], [Vector2(7.2, 12.2), 1.5],
]
## `calico` — asymmetric patches, the one pattern where the two sides differ.
const PATCHES := [
	[Vector2(-5.4, -1.2), Vector2(6.0, 6.6), 0],
	[Vector2(5.2, 8.4), Vector2(5.6, 6.2), 1],
	[Vector2(4.2, -15.6), Vector2(4.4, 4.6), 0],
]

## Paws, planted when grounded and thrown out fore and aft in the air — the
## shape a cat makes at the top of a leap.
const PAWS_PLANTED := [
	[Vector2(-12.4, -3.0), 3.5], [Vector2(12.4, -3.0), 3.5],
	[Vector2(-10.6, 13.0), 3.2], [Vector2(10.6, 13.0), 3.2],
]
const PAWS_LEAPING := [
	[Vector2(-14.6, -11.0), 3.3], [Vector2(14.6, -11.0), 3.3],
	[Vector2(-12.8, 19.5), 3.0], [Vector2(12.8, 19.5), 3.0],
]

## Quantisation of the cat's pose. Merging the silhouette is too much work to
## repeat every frame, so poses are built once and reused.
const TAIL_PHASE_STEPS := 16
const LEAP_STEPS := 6
## Poses held at once. One equipped cat needs about ten; the codex screen asks
## for two dozen silhouettes on each redraw, which is why this is a cap and not
## a per-cat cache.
const POSE_CACHE_LIMIT := 256

## A cloud seen from above: an irregular mass with no up or down, inside a
## 140x120 box centred on its origin.
const CLOUD_LOBES := [
	[Vector2(70.0, 58.0), 34.0],
	[Vector2(40.0, 46.0), 24.0],
	[Vector2(100.0, 44.0), 26.0],
	[Vector2(52.0, 82.0), 24.0],
	[Vector2(96.0, 84.0), 22.0],
	[Vector2(26.0, 68.0), 16.0],
	[Vector2(116.0, 70.0), 16.0],
]
const CLOUD_BOX := Vector2(140.0, 120.0)
const CLOUD_ORIGIN := Vector2(70.0, 60.0)

static var _cloud_polygon := PackedVector2Array()
static var _cat_poses := {}


## The cloud mass, centred on its origin. Built once: unioning the lobes every
## frame would be wasteful, and drawing them separately would show a seam
## through every translucent cloud.
static func cloud_polygon() -> PackedVector2Array:
	if _cloud_polygon.is_empty():
		var parts: Array = []
		for lobe: Array in CLOUD_LOBES:
			parts.append(Shapes.circle_polygon(lobe[0], lobe[1]))
		_cloud_polygon = Shapes.scaled(Shapes.merge(parts), Vector2.ONE, -CLOUD_ORIGIN)
	return _cloud_polygon


## Mirrors a left-side outline to the right.
static func mirrored(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(-point.x, point.y))
	return out


## Outer and inner outline for both ears of one shape.
static func ears(shape: String) -> Dictionary:
	var pair: Array = EARS.get(shape, EARS.pricked)
	return {
		"outer": [PackedVector2Array(pair[0]), mirrored(pair[0])],
		"inner": [PackedVector2Array(pair[1]), mirrored(pair[1])],
	}


## Positions of the tail segments for a given sway phase and leap amount. The
## tail curls beside the cat at rest and streams out behind it in the air.
static func tail_segments(tail_phase: float, leap: float, shape := "long") -> Array:
	var form: Dictionary = TAILS.get(shape, TAILS.long)
	var count := int(form.count)
	var step := float(form.step)
	var base := float(form.base)
	var curl: float = lerpf(0.40, 0.10, leap)
	var reach: float = lerpf(1.0, 1.45, leap)
	var sway := sin(tail_phase * TAU) * lerpf(0.30, 0.09, leap)
	var point := TAIL_ROOT
	var heading := PI * 0.5
	var segments: Array = []
	for i in count:
		heading += curl + sway
		# A kinked tail turns once, part way along, so the silhouette folds.
		if i == 2:
			heading += float(form.kink)
		point += Vector2(cos(heading), sin(heading)) * step * reach
		segments.append([point, maxf(1.4, base - float(i) * base * 0.135)])
	return segments


## The cat's fur silhouette — head, ears, body and tail as one outline, so a
## fading cat never shows the joins between its parts.
##
## Ears, tail and build change the outline, so the cache is keyed on those too.
## A whole run needs about ten poses of one cat; the codex draws two dozen cats
## but only when it redraws, so the cache is capped rather than per-cat, and
## cleared wholesale when it overflows.
static func cat_polygon(tail_phase: float, leap: float, cat: Dictionary = {}) -> PackedVector2Array:
	var ear_shape := String(cat.get("ears", "pricked"))
	var tail_shape := String(cat.get("tail", "long"))
	var build := String(cat.get("build", "standard"))
	var phase_step := posmod(int(round(tail_phase * TAIL_PHASE_STEPS)), TAIL_PHASE_STEPS)
	var leap_step := clampi(int(round(leap * LEAP_STEPS)), 0, LEAP_STEPS)
	var key := "%s|%s|%s|%d|%d" % [ear_shape, tail_shape, build, phase_step, leap_step]
	if _cat_poses.has(key):
		return _cat_poses[key]
	var quantised_phase := float(phase_step) / float(TAIL_PHASE_STEPS)
	var quantised_leap := float(leap_step) / float(LEAP_STEPS)
	var width := float(BUILDS.get(build, 1.0))
	var body: Array = BODY_LEAPING if quantised_leap > 0.999 else [
		Vector2(BODY[0]).lerp(BODY_LEAPING[0], quantised_leap),
		Vector2(BODY[1]).lerp(BODY_LEAPING[1], quantised_leap),
	]
	var parts: Array = [
		Shapes.ellipse_polygon(body[0], Vector2(body[1]) * Vector2(width, 1.0)),
		Shapes.circle_polygon(HEAD[0], HEAD[1]),
	]
	for outline: PackedVector2Array in ears(ear_shape).outer:
		parts.append(outline)
	for segment: Array in tail_segments(quantised_phase, quantised_leap, tail_shape):
		parts.append(Shapes.circle_polygon(segment[0], segment[1], 16))
	var pose := Shapes.merge(parts)
	if _cat_poses.size() >= POSE_CACHE_LIMIT:
		_cat_poses.clear()
	_cat_poses[key] = pose
	return pose


static func draw_cloud(canvas: CanvasItem, color: Color) -> void:
	Shapes.fill(canvas, cloud_polygon(), color)


## Draws the cat centred on the current transform, seen from above.
##
## [param tail_phase] drives the idle sway; [param leap] is 0 on a bridge and 1
## at the top of a jump, which throws the legs out and streams the tail.
## [param cat] is a [CatConfig] entry — omit it and the starting cat is drawn,
## so every existing call keeps working.
static func draw_cat(canvas: CanvasItem, alpha: float = 1.0, tail_phase: float = 0.0,
		leap: float = 0.0, cat: Dictionary = {}) -> void:
	var fur := Color(cat.get("fur", FUR_COLOR))
	var dark := Color(cat.get("fur_dark", FUR_DARK_COLOR))
	var paw := Color(cat.get("paw", PAW_COLOR))
	var inner := Color(cat.get("inner_ear", INNER_EAR_COLOR))
	var pattern := String(cat.get("pattern", "tabby"))
	var width := float(BUILDS.get(String(cat.get("build", "standard")), 1.0))
	var ear := ears(String(cat.get("ears", "pricked")))
	alpha *= float(cat.get("alpha", 1.0))
	if alpha <= 0.0:
		return

	var glow := Color(cat.get("aura", Color(0.0, 0.0, 0.0, 0.0)))
	if glow.a > 0.0:
		# A soft halo, drawn under everything so it never washes the cat out.
		for ring in 5:
			var radius := 20.0 + float(ring) * 4.4
			canvas.draw_circle(Vector2(0.0, -2.0), radius,
				Color(glow, alpha * 0.055 * (1.0 - float(ring) / 5.0)), true, -1.0, true)

	# Paws and whiskers sit under the silhouette so they poke out from beneath.
	if bool(cat.get("paws", true)):
		for i in PAWS_PLANTED.size():
			var planted: Array = PAWS_PLANTED[i]
			var leaping: Array = PAWS_LEAPING[i]
			var centre: Vector2 = Vector2(planted[0]).lerp(leaping[0], leap) * Vector2(width, 1.0)
			canvas.draw_circle(centre, lerpf(planted[1], leaping[1], leap),
				Color(paw, alpha), true, -1.0, true)
	if bool(cat.get("whiskers", true)):
		for whisker: Array in WHISKERS:
			canvas.draw_line(whisker[0], whisker[1], Color(paw, alpha * 0.8), 1.4, true)

	var silhouette := cat_polygon(tail_phase, leap, cat)
	match pattern:
		"hole":
			# A cat-shaped hole: the far sky shows through, and only the outer
			# rim is drawn. The parts are stroked first and covered by the fill,
			# so the seams between head, body and tail never show.
			Shapes.fill(canvas, silhouette, Color(0.0, 0.0, 0.0, alpha * 0.86))
			canvas.draw_polyline(Shapes.closed(silhouette), Color(1.0, 1.0, 1.0, alpha * 0.5), 1.6, true)
		"point", "van":
			# Light body, coloured extremities.
			_fill_body(canvas, tail_phase, leap, cat, fur, alpha)
			_fill_extremities(canvas, tail_phase, leap, cat, ear, dark, alpha, pattern)
		"window":
			# The silhouette is a window onto the sky the cat is crossing, so it
			# is filled with that gradient rather than a colour of its own.
			_fill_gradient(canvas, silhouette,
				Color(cat.get("window_top", Color("79beff")), alpha),
				Color(cat.get("window_bottom", Color("eaf7ff")), alpha))
		"bicolor":
			Shapes.fill(canvas, silhouette, Color(fur, alpha))
			Shapes.fill(canvas, Shapes.clipped_right(silhouette), Color(dark, alpha))
		_:
			Shapes.fill(canvas, silhouette, Color(fur, alpha))

	match pattern:
		"tabby":
			for stripe: Array in STRIPES:
				Shapes.fill(canvas, Shapes.ellipse_polygon(stripe[0],
					Vector2(stripe[1]) * Vector2(width, 1.0)), Color(dark, alpha * 0.8))
		"spotted":
			for spot: Array in SPOTS:
				canvas.draw_circle(Vector2(spot[0]) * Vector2(width, 1.0), spot[1],
					Color(dark, alpha * 0.82), true, -1.0, true)
		"tuxedo":
			Shapes.fill(canvas, Shapes.ellipse_polygon(Vector2(0.0, 6.5),
				Vector2(11.5 * width * 0.46, 8.4)), Color(paw, alpha))
			Shapes.fill(canvas, Shapes.ellipse_polygon(Vector2(0.0, -16.4),
				Vector2(2.1, 5.4)), Color(paw, alpha))
		"calico":
			var patches := [Color(cat.get("patch_a", fur)), Color(cat.get("patch_b", dark))]
			for patch: Array in PATCHES:
				Shapes.fill(canvas, Shapes.ellipse_polygon(Vector2(patch[0]) * Vector2(width, 1.0),
					patch[1]), Color(patches[int(patch[2])], alpha * 0.95))

	if bool(cat.get("marks", true)):
		for mark: Array in HEAD_MARKS:
			Shapes.fill(canvas, Shapes.ellipse_polygon(mark[0], mark[1]), Color(dark, alpha * 0.7))
	if bool(cat.get("inner", true)):
		for outline: PackedVector2Array in ear.inner:
			Shapes.fill(canvas, outline, Color(inner, alpha))


## Fills a silhouette with a vertical gradient by colouring its vertices, which
## is the only way to get a gradient inside an arbitrary outline in 2D.
static func _fill_gradient(canvas: CanvasItem, polygon: PackedVector2Array,
		top: Color, bottom: Color) -> void:
	if polygon.size() < 3:
		return
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var span := maxf(bounds.size.y, 0.001)
	var colors := PackedColorArray()
	for point in polygon:
		colors.append(top.lerp(bottom, clampf((point.y - bounds.position.y) / span, 0.0, 1.0)))
	canvas.draw_polygon(polygon, colors)
	canvas.draw_polyline(Shapes.closed(polygon), top.lerp(bottom, 0.5), 1.0, true)


## The cat as a codex or share-card portrait: the same drawing, plus a rim that
## keeps a black cat off a black sky and a white cat off a white one. The rim is
## presentation only and never appears in the playfield.
static func draw_cat_portrait(canvas: CanvasItem, cat: Dictionary, behind: Color,
		tail_phase := 0.62, leap := 0.0, alpha := 1.0) -> void:
	var subject := Color(cat.get("fur", FUR_COLOR))
	if String(cat.get("pattern", "tabby")) == "hole":
		subject = Color(0.0, 0.0, 0.0)
	# Rim only when the cat would otherwise disappear into what is behind it.
	if absf(subject.get_luminance() - behind.get_luminance()) < 0.22:
		var rim := Color(1.0, 1.0, 1.0, alpha * 0.55)
		if subject.get_luminance() > 0.5:
			rim = Color("24313d", alpha * 0.42)
		canvas.draw_polyline(Shapes.closed(cat_polygon(tail_phase, leap, cat)), rim, 2.0, true)
	draw_cat(canvas, alpha, tail_phase, leap, cat)


## Body and head only, for the two patterns whose extremities differ.
static func _fill_body(canvas: CanvasItem, tail_phase: float, leap: float,
		cat: Dictionary, color: Color, alpha: float) -> void:
	var width := float(BUILDS.get(String(cat.get("build", "standard")), 1.0))
	var body: Array = [
		Vector2(BODY[0]).lerp(BODY_LEAPING[0], leap),
		Vector2(BODY[1]).lerp(BODY_LEAPING[1], leap),
	]
	Shapes.fill_all(canvas, [
		Shapes.ellipse_polygon(body[0], Vector2(body[1]) * Vector2(width, 1.0)),
		Shapes.circle_polygon(HEAD[0], HEAD[1]),
	], Color(color, alpha))


## Ears and tail, plus the mask over the head that separates a Siamese point
## from a van's cap.
static func _fill_extremities(canvas: CanvasItem, tail_phase: float, leap: float,
		cat: Dictionary, ear: Dictionary, color: Color, alpha: float, pattern: String) -> void:
	var parts: Array = []
	for outline: PackedVector2Array in ear.outer:
		parts.append(outline)
	for segment: Array in tail_segments(tail_phase, leap, String(cat.get("tail", "long"))):
		parts.append(Shapes.circle_polygon(segment[0], segment[1], 16))
	if pattern == "point":
		parts.append(Shapes.ellipse_polygon(Vector2(0.0, -15.5), Vector2(8.2, 6.6)))
	else:
		# A van wears its colour as a cap over the top of the head only.
		parts.append(Shapes.ellipse_polygon(Vector2(0.0, -19.4), Vector2(9.4, 5.4)))
	# Ears, tail and the head patch do not all touch, so every ring is filled —
	# merging to the largest would silently drop the cap or the tail.
	Shapes.fill_all(canvas, parts, Color(color, alpha))
