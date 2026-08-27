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
const HEAD := [Vector2(0.0, -13.0), 10.0]
const EAR_LEFT := [Vector2(-9.6, -17.5), Vector2(-3.4, -21.5), Vector2(-8.2, -26.0)]
const EAR_RIGHT := [Vector2(9.6, -17.5), Vector2(3.4, -21.5), Vector2(8.2, -26.0)]
const INNER_EAR_LEFT := [Vector2(-8.6, -18.6), Vector2(-5.0, -21.0), Vector2(-7.9, -23.6)]
const INNER_EAR_RIGHT := [Vector2(8.6, -18.6), Vector2(5.0, -21.0), Vector2(7.9, -23.6)]
const BODY := [Vector2(0.0, 4.0), Vector2(11.5, 14.0)]
## Tail, as a chain of shrinking circles curling away behind the cat.
const TAIL := [
	[Vector2(7.0, 15.0), 4.6], [Vector2(12.0, 19.0), 3.8],
	[Vector2(16.0, 22.5), 3.0], [Vector2(19.0, 25.2), 2.2],
]
## Tabby bands across the back.
const STRIPES := [
	[Vector2(0.0, -2.0), Vector2(8.6, 1.7)],
	[Vector2(0.0, 3.5), Vector2(9.6, 1.7)],
	[Vector2(0.0, 9.0), Vector2(8.4, 1.7)],
]
## Paws poking out at the sides, as they would from above.
## Far enough out to clear the body outline, or they simply do not show.
const PAWS := [
	[Vector2(-12.4, -3.0), 3.5], [Vector2(12.4, -3.0), 3.5],
	[Vector2(-10.6, 13.0), 3.2], [Vector2(10.6, 13.0), 3.2],
]
const MUZZLE := [Vector2(0.0, -9.2), Vector2(3.6, 2.5)]
const NOSE := [Vector2(0.0, -11.6), Vector2(-1.7, -9.8), Vector2(1.7, -9.8)]
const EYE_LEFT := [Vector2(-4.2, -14.2), 1.9]
const EYE_RIGHT := [Vector2(4.2, -14.2), 1.9]

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
static var _cat_polygon := PackedVector2Array()


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


## The cat's fur silhouette — head, ears, body and tail as one outline, so a
## fading cat never shows the joins between its parts.
static func cat_polygon() -> PackedVector2Array:
	if _cat_polygon.is_empty():
		var parts: Array = [
			Shapes.ellipse_polygon(BODY[0], BODY[1]),
			Shapes.circle_polygon(HEAD[0], HEAD[1]),
			PackedVector2Array(EAR_LEFT),
			PackedVector2Array(EAR_RIGHT),
		]
		for segment: Array in TAIL:
			parts.append(Shapes.circle_polygon(segment[0], segment[1]))
		_cat_polygon = Shapes.merge(parts)
	return _cat_polygon


static func draw_cloud(canvas: CanvasItem, color: Color) -> void:
	Shapes.fill(canvas, cloud_polygon(), color)


## Draws the cat centred on the current transform, seen from above.
static func draw_cat(canvas: CanvasItem, alpha: float = 1.0) -> void:
	for paw: Array in PAWS:
		canvas.draw_circle(paw[0], paw[1], Color(PAW_COLOR, alpha), true, -1.0, true)
	Shapes.fill(canvas, cat_polygon(), Color(FUR_COLOR, alpha))
	for stripe: Array in STRIPES:
		Shapes.fill(canvas, Shapes.ellipse_polygon(stripe[0], stripe[1]), Color(FUR_DARK_COLOR, alpha * 0.8))
	Shapes.fill(canvas, PackedVector2Array(INNER_EAR_LEFT), Color(INNER_EAR_COLOR, alpha))
	Shapes.fill(canvas, PackedVector2Array(INNER_EAR_RIGHT), Color(INNER_EAR_COLOR, alpha))
	Shapes.fill(canvas, Shapes.ellipse_polygon(MUZZLE[0], MUZZLE[1]), Color(PAW_COLOR, alpha))
	Shapes.fill(canvas, PackedVector2Array(NOSE), Color(INNER_EAR_COLOR, alpha))
	canvas.draw_circle(EYE_LEFT[0], EYE_LEFT[1], Color(EYE_COLOR, alpha), true, -1.0, true)
	canvas.draw_circle(EYE_RIGHT[0], EYE_RIGHT[1], Color(EYE_COLOR, alpha), true, -1.0, true)
