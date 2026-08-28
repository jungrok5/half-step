class_name Shapes
extends RefCounted

## Vector primitives for the flat art style.
##
## Everything the game draws is built from these rather than from a pixel grid,
## so shapes stay smooth at any resolution. Silhouettes that overlap — a cloud's
## puffs, the player's body — are merged into a single polygon before drawing,
## because layering translucent circles would show every seam.
##
## Edges are smoothed by [method fill] rather than by MSAA: the Compatibility
## renderer the web and mobile builds need refuses it outright — "2D MSAA is not
## yet supported for GLES3" — so a filled polygon gets its own outline traced
## with Godot's antialiased line drawing instead.

const CIRCLE_SEGMENTS := 32
const CORNER_SEGMENTS := 5


## Polygon approximating a circle.
static func circle_polygon(center: Vector2, radius: float, segments: int = CIRCLE_SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


## Polygon approximating an axis-aligned ellipse.
static func ellipse_polygon(center: Vector2, radii: Vector2, segments: int = CIRCLE_SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


## Rounded rectangle. [param radii] holds the corner radii clockwise from the
## top-left, so a shape can be round on top and square where it meets another.
static func rounded_rect_polygon(rect: Rect2, radii: Vector4) -> PackedVector2Array:
	var limit := minf(rect.size.x, rect.size.y) * 0.5
	var corners := [
		[Vector2(rect.position.x, rect.position.y), minf(radii.x, limit), PI, PI * 1.5],
		[Vector2(rect.end.x, rect.position.y), minf(radii.y, limit), PI * 1.5, TAU],
		[Vector2(rect.end.x, rect.end.y), minf(radii.z, limit), 0.0, PI * 0.5],
		[Vector2(rect.position.x, rect.end.y), minf(radii.w, limit), PI * 0.5, PI],
	]
	var offsets := [Vector2(1.0, 1.0), Vector2(-1.0, 1.0), Vector2(-1.0, -1.0), Vector2(1.0, -1.0)]
	var points := PackedVector2Array()
	for i in corners.size():
		var corner: Array = corners[i]
		var radius: float = corner[1]
		var pivot: Vector2 = corner[0] + Vector2(offsets[i]) * radius
		if radius <= 0.0:
			points.append(corner[0])
			continue
		for step in CORNER_SEGMENTS + 1:
			var angle: float = lerpf(corner[2], corner[3], float(step) / float(CORNER_SEGMENTS))
			points.append(pivot + Vector2(cos(angle), sin(angle)) * radius)
	return points


## Fills a polygon with a smooth edge.
static func fill(canvas: CanvasItem, polygon: PackedVector2Array, color: Color) -> void:
	if polygon.size() < 3:
		return
	canvas.draw_colored_polygon(polygon, color)
	canvas.draw_polyline(closed(polygon), color, 1.0, true)


## The polygon with its first point repeated, for outlining.
static func closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var points := polygon.duplicate()
	if points.size() > 0:
		points.append(points[0])
	return points


static func rounded_rect(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	fill(canvas, rounded_rect_polygon(rect, Vector4(radius, radius, radius, radius)), color)


## A line with round caps.
static func capsule(canvas: CanvasItem, from: Vector2, to: Vector2, thickness: float, color: Color) -> void:
	canvas.draw_line(from, to, color, thickness, true)


## Every ring of the union of [param parts]. Parts that touch become one ring;
## parts that do not stay separate. Filling the rings instead of the parts is
## what lets a translucent shape be drawn without seams along every join.
static func merge_all(parts: Array) -> Array:
	if parts.is_empty():
		return []
	var merged: Array = [parts[0]]
	for i in range(1, parts.size()):
		var next: Array = []
		var absorbed := false
		for shape: PackedVector2Array in merged:
			if absorbed:
				next.append(shape)
				continue
			var union := Geometry2D.merge_polygons(shape, parts[i])
			if union.size() == 1:
				next.append(union[0])
				absorbed = true
			else:
				next.append(shape)
		if not absorbed:
			next.append(parts[i])
		merged = next
	return merged


## The largest ring of that union. Only correct where the caller knows the parts
## are connected — [method merge_all] keeps the rest.
static func merge(parts: Array) -> PackedVector2Array:
	var merged := merge_all(parts)
	if merged.is_empty():
		return PackedVector2Array()
	var largest: PackedVector2Array = merged[0]
	for shape: PackedVector2Array in merged:
		if _area(shape) > _area(largest):
			largest = shape
	return largest


## Fills every ring of a union at one opacity.
static func fill_all(canvas: CanvasItem, parts: Array, color: Color) -> void:
	for ring: PackedVector2Array in merge_all(parts):
		fill(canvas, ring, color)


static func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5


## Scales a polygon about the origin. Cheaper than rebuilding a merged
## silhouette every frame.
## The half of [param polygon] on the +X side of the origin, for a cat whose
## two sides are different colours. Returns an empty array when nothing of it
## lies there.
static func clipped_right(polygon: PackedVector2Array) -> PackedVector2Array:
	if polygon.size() < 3:
		return PackedVector2Array()
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	if bounds.end.x <= 0.0:
		return PackedVector2Array()
	var half := PackedVector2Array([
		Vector2(0.0, bounds.position.y - 1.0),
		Vector2(bounds.end.x + 1.0, bounds.position.y - 1.0),
		Vector2(bounds.end.x + 1.0, bounds.end.y + 1.0),
		Vector2(0.0, bounds.end.y + 1.0),
	])
	var pieces := Geometry2D.intersect_polygons(polygon, half)
	if pieces.is_empty():
		return PackedVector2Array()
	var best: PackedVector2Array = pieces[0]
	for piece: PackedVector2Array in pieces:
		if absf(_area(piece)) > absf(_area(best)):
			best = piece
	return best


static func scaled(polygon: PackedVector2Array, factor: Vector2, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in polygon:
		points.append(point * factor + offset)
	return points
