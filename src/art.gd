class_name Art
extends RefCounted

## The game's vector art, in one place so the playfield and the share image
## never drift apart.
##
## Flat shapes, no outlines, no pixel grid: a small readable silhouette that
## survives being scaled from a 26px character on a phone to a 1080px wide share
## card. Edges are smoothed by [method Shapes.fill] because the Compatibility
## renderer has no 2D MSAA.

const BODY_COLOR := Color("ef6a5b")
const BELLY_COLOR := Color("ffd2c6")
const WING_COLOR := Color("d2554a")
const BEAK_COLOR := Color("ffc247")
const CHEEK_COLOR := Color("ff9d8e")
const PUPIL_COLOR := Color("2f2020")

## Bird geometry, relative to its own centre, sized for the 36x36 player box.
const BODY := [Vector2(-0.5, 1.5), Vector2(15.0, 15.5)]
const BELLY := [Vector2(1.5, 8.0), Vector2(10.0, 7.5)]
const WING := [Vector2(-6.0, 4.5), Vector2(7.0, 5.0)]
const BEAK := [Vector2(15.0, 2.5), Vector2(6.0, 3.4)]
const CHEEK := [Vector2(1.0, 3.5), 2.6]
const EYE := [Vector2(6.0, -4.5), 6.0]
const PUPIL := [Vector2(7.6, -4.0), 2.9]

## Cloud puffs, unioned into one silhouette inside a 124x40 box.
const CLOUD_PUFFS := [
	[Vector2(58.0, 4.0), 20.0],
	[Vector2(30.0, 10.0), 14.0],
	[Vector2(86.0, 8.0), 16.0],
	[Vector2(108.0, 14.0), 10.0],
	[Vector2(16.0, 14.0), 10.0],
]
const CLOUD_BASE := Rect2(6.0, 12.0, 112.0, 12.0)
## Centre of the cloud box, the point a cloud scales about.
const CLOUD_ORIGIN := Vector2(36.0, 12.0)

static var _cloud_polygon := PackedVector2Array()


## The cloud silhouette, centred on its origin. Built once: unioning the puffs
## every frame would be wasteful, and drawing them separately would show a seam
## through every translucent cloud.
static func cloud_polygon() -> PackedVector2Array:
	if _cloud_polygon.is_empty():
		var parts: Array = [Shapes.rounded_rect_polygon(CLOUD_BASE, Vector4(6.0, 6.0, 6.0, 6.0))]
		for puff: Array in CLOUD_PUFFS:
			parts.append(Shapes.circle_polygon(puff[0], puff[1]))
		_cloud_polygon = Shapes.scaled(Shapes.merge(parts), Vector2.ONE, -CLOUD_ORIGIN)
	return _cloud_polygon


## Draws a cloud centred on the current transform.
static func draw_cloud(canvas: CanvasItem, color: Color) -> void:
	Shapes.fill(canvas, cloud_polygon(), color)


## Draws the bird centred on the current transform. Scale it with the canvas
## transform rather than here, so the share card can draw the same shapes large.
static func draw_bird(canvas: CanvasItem, alpha: float = 1.0) -> void:
	# Beak first, so the body's edge covers the join.
	Shapes.fill(canvas, Shapes.ellipse_polygon(BEAK[0], BEAK[1]), Color(BEAK_COLOR, alpha))
	Shapes.fill(canvas, Shapes.ellipse_polygon(BODY[0], BODY[1]), Color(BODY_COLOR, alpha))
	Shapes.fill(canvas, Shapes.ellipse_polygon(BELLY[0], BELLY[1]), Color(BELLY_COLOR, alpha))
	Shapes.fill(canvas, Shapes.ellipse_polygon(WING[0], WING[1]), Color(WING_COLOR, alpha))
	canvas.draw_circle(CHEEK[0], CHEEK[1], Color(CHEEK_COLOR, alpha * 0.85), true, -1.0, true)
	canvas.draw_circle(EYE[0], EYE[1], Color(1.0, 1.0, 1.0, alpha), true, -1.0, true)
	canvas.draw_circle(PUPIL[0], PUPIL[1], Color(PUPIL_COLOR, alpha), true, -1.0, true)
