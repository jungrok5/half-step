class_name RunFeats
extends RefCounted

## What one run did, beyond its score. Fed by [Game] as the run happens and
## handed to [Progress] when it ends. See PROGRESSION.md section 4, "feat".
##
## Two of the four feats span runs rather than living inside one, so those
## counters belong to [Progress]; this class only reports what this run did.

## How deep into the crossing window a jump still counts as "the moment it
## opened". The window itself is the second half of every beat
## ([constant HalfStepState.CROSS_REACH]); this is the first tenth of that.
const EARLY_WINDOW := 0.10

## Successful lane changes — a tap that found a bridge.
var crossings := 0
## Longest run of consecutive jumps taken in the first tenth of the window.
var early_jump_streak := 0

var _early_streak := 0


func reset() -> void:
	crossings = 0
	early_jump_streak = 0
	_early_streak = 0


## Records one jump. [param depth] is how far into the crossing window it was
## made, 0 at the instant the window opens and 1 as the bridge arrives; it is
## negative when the jump could not reach, which ends the run anyway.
func record_jump(depth: float) -> void:
	if depth < 0.0:
		_early_streak = 0
		return
	crossings += 1
	if depth <= EARLY_WINDOW:
		_early_streak += 1
		early_jump_streak = maxi(early_jump_streak, _early_streak)
	else:
		_early_streak = 0
