class_name CssAnim
extends RefCounted

## CSS timing-function and keyframe helpers.
##
## The web prototype drives every piece of feedback through Web Animations
## (`element.animate([...], {duration, easing})`). Porting the numbers without
## porting the curves would change the feel, so the exact cubic-bezier curves
## used by `reference/web-prototypes/half_step_pixel_skin.html` live here.

## cubic-bezier control points, stored as (x1, y1, x2, y2).
const LINEAR := Vector4(0.0, 0.0, 1.0, 1.0)
## CSS `ease`, the default for `transition:` shorthand values.
const EASE := Vector4(0.25, 0.1, 0.25, 1.0)
## CSS `ease-out`, used by the tile squash and the impact pixels.
const EASE_OUT := Vector4(0.0, 0.0, 0.58, 1.0)
## `cubic-bezier(.2,.8,.2,1)` — lane switch and the pre-landing hop.
const SNAP := Vector4(0.2, 0.8, 0.2, 1.0)
## `cubic-bezier(.25,.2,.75,1)` — the fall-into-depth death animation.
const DEPTH := Vector4(0.25, 0.2, 0.75, 1.0)
## `cubic-bezier(.15,.75,.25,1)` — the expanding platform impact ghost.
const IMPACT := Vector4(0.15, 0.75, 0.25, 1.0)

const _NEWTON_STEPS := 6
const _EPSILON := 0.0001


static func _bezier_axis(a: float, b: float, t: float) -> float:
	var inv := 1.0 - t
	return 3.0 * inv * inv * t * a + 3.0 * inv * t * t * b + t * t * t


static func _bezier_axis_slope(a: float, b: float, t: float) -> float:
	var inv := 1.0 - t
	return 3.0 * inv * inv * a + 6.0 * inv * t * (b - a) + 3.0 * t * t * (1.0 - b)


## Evaluates a CSS cubic-bezier timing function at progress [param t] in 0..1.
static func curve(control: Vector4, t: float) -> float:
	var progress := clampf(t, 0.0, 1.0)
	if control == LINEAR:
		return progress
	var guess := progress
	for _i in _NEWTON_STEPS:
		var x := _bezier_axis(control.x, control.z, guess) - progress
		if absf(x) < _EPSILON:
			break
		var slope := _bezier_axis_slope(control.x, control.z, guess)
		if absf(slope) < _EPSILON:
			break
		guess -= x / slope
	return _bezier_axis(control.y, control.w, clampf(guess, 0.0, 1.0))


## Samples a keyframe track. [param offsets] are the CSS keyframe offsets and
## [param values] the matching values; the easing is applied per segment, which
## is how Web Animations treats a single `easing` option.
static func track(t: float, offsets: Array, values: Array, control: Vector4) -> float:
	var progress := clampf(t, 0.0, 1.0)
	if progress <= float(offsets[0]):
		return float(values[0])
	for i in range(offsets.size() - 1):
		var from := float(offsets[i])
		var to := float(offsets[i + 1])
		if progress > to:
			continue
		if to - from <= _EPSILON:
			return float(values[i + 1])
		var local := curve(control, (progress - from) / (to - from))
		return lerpf(float(values[i]), float(values[i + 1]), local)
	return float(values[values.size() - 1])
