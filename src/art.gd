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
const EAR_LEFT := [Vector2(-9.6, -17.5), Vector2(-3.4, -21.5), Vector2(-8.2, -26.0)]
const EAR_RIGHT := [Vector2(9.6, -17.5), Vector2(3.4, -21.5), Vector2(8.2, -26.0)]
const INNER_EAR_LEFT := [Vector2(-8.6, -18.6), Vector2(-5.0, -21.0), Vector2(-7.9, -23.6)]
const INNER_EAR_RIGHT := [Vector2(8.6, -18.6), Vector2(5.0, -21.0), Vector2(7.9, -23.6)]
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
## Tail root, inside the body. The rest is grown from here each frame.
const TAIL_ROOT := Vector2(4.0, 11.0)
const TAIL_SEGMENTS := 5
## Tabby bands across the back.
const STRIPES := [
	[Vector2(0.0, -2.0), Vector2(8.6, 1.7)],
	[Vector2(0.0, 3.5), Vector2(9.6, 1.7)],
	[Vector2(0.0, 9.0), Vector2(8.4, 1.7)],
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


## Positions of the tail segments for a given sway phase and leap amount. The
## tail curls beside the cat at rest and streams out behind it in the air.
static func tail_segments(tail_phase: float, leap: float) -> Array:
	var curl: float = lerpf(0.40, 0.10, leap)
	var reach: float = lerpf(1.0, 1.45, leap)
	var sway: float = sin(tail_phase * TAU) * lerpf(0.30, 0.09, leap)
	var point := TAIL_ROOT
	var heading := PI * 0.5
	var segments: Array = []
	for i in TAIL_SEGMENTS:
		heading += curl + sway
		point += Vector2(cos(heading), sin(heading)) * 5.4 * reach
		segments.append([point, 4.6 - float(i) * 0.62])
	return segments


## The cat's fur silhouette — head, ears, body and tail as one outline, so a
## fading cat never shows the joins between its parts.
static func cat_polygon(tail_phase: float, leap: float) -> PackedVector2Array:
	var phase_step := posmod(int(round(tail_phase * TAIL_PHASE_STEPS)), TAIL_PHASE_STEPS)
	var leap_step := clampi(int(round(leap * LEAP_STEPS)), 0, LEAP_STEPS)
	var key := phase_step * (LEAP_STEPS + 1) + leap_step
	if _cat_poses.has(key):
		return _cat_poses[key]
	var quantised_phase := float(phase_step) / float(TAIL_PHASE_STEPS)
	var quantised_leap := float(leap_step) / float(LEAP_STEPS)
	var body: Array = BODY_LEAPING if quantised_leap > 0.999 else [
		Vector2(BODY[0]).lerp(BODY_LEAPING[0], quantised_leap),
		Vector2(BODY[1]).lerp(BODY_LEAPING[1], quantised_leap),
	]
	var parts: Array = [
		Shapes.ellipse_polygon(body[0], body[1]),
		Shapes.circle_polygon(HEAD[0], HEAD[1]),
		PackedVector2Array(EAR_LEFT),
		PackedVector2Array(EAR_RIGHT),
	]
	for segment: Array in tail_segments(quantised_phase, quantised_leap):
		parts.append(Shapes.circle_polygon(segment[0], segment[1], 16))
	var pose := Shapes.merge(parts)
	_cat_poses[key] = pose
	return pose


static func draw_cloud(canvas: CanvasItem, color: Color) -> void:
	Shapes.fill(canvas, cloud_polygon(), color)


## Draws the cat centred on the current transform, seen from above.
## [param tail_phase] drives the idle sway; [param leap] is 0 on a bridge and 1
## at the top of a jump, which throws the legs out and streams the tail.
static func draw_cat(canvas: CanvasItem, alpha: float = 1.0, tail_phase: float = 0.0, leap: float = 0.0) -> void:
	for i in PAWS_PLANTED.size():
		var planted: Array = PAWS_PLANTED[i]
		var leaping: Array = PAWS_LEAPING[i]
		canvas.draw_circle(Vector2(planted[0]).lerp(leaping[0], leap),
			lerpf(planted[1], leaping[1], leap), Color(PAW_COLOR, alpha), true, -1.0, true)
	for whisker: Array in WHISKERS:
		canvas.draw_line(whisker[0], whisker[1], Color(PAW_COLOR, alpha * 0.8), 1.4, true)
	Shapes.fill(canvas, cat_polygon(tail_phase, leap), Color(FUR_COLOR, alpha))
	for stripe: Array in STRIPES:
		Shapes.fill(canvas, Shapes.ellipse_polygon(stripe[0], stripe[1]), Color(FUR_DARK_COLOR, alpha * 0.8))
	for mark: Array in HEAD_MARKS:
		Shapes.fill(canvas, Shapes.ellipse_polygon(mark[0], mark[1]), Color(FUR_DARK_COLOR, alpha * 0.7))
	Shapes.fill(canvas, PackedVector2Array(INNER_EAR_LEFT), Color(INNER_EAR_COLOR, alpha))
	Shapes.fill(canvas, PackedVector2Array(INNER_EAR_RIGHT), Color(INNER_EAR_COLOR, alpha))
