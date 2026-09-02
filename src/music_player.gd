class_name MusicPlayer
extends Node

## Background music, crossfaded between the bands in [AudioBank].
##
## Two players and a fade between them, because the skies change mid-run and a
## hard cut would land on top of whatever the player was doing. Silent until the
## files exist, so nothing here can break a build that has no music yet.

const FADE := 2.2
const VOLUME_DB := -9.0
const SILENT_DB := -60.0

var track := ""

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _fade := 1.0


func _ready() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = SILENT_DB
		player.bus = "Master"
		add_child(player)
		_players.append(player)


## Crossfades to [param id]. Asking for the track already playing does nothing,
## so this can be called every time the zone is applied.
func play(id: String) -> void:
	if id == track:
		return
	var stream := AudioBank.music(id)
	track = id
	# A track nobody has heard is cut, not crossfaded. `_fade` is still 0 when
	# two switches land in the same frame — `reset()` picks the bed for the
	# score and then the title asks for its own — and fading out a player that
	# has not started ramping up walks it to FULL volume on its way out. That is
	# a burst of gameplay music over the title screen.
	if _fade <= 0.0:
		_players[_active].stop()
	if stream == null:
		# No file for this band yet: fade out rather than cut, so the bands that
		# do have music do not end abruptly at the boundary.
		_fade = 0.0
		_active = 1 - _active
		_players[_active].stop()
		return
	_active = 1 - _active
	_players[_active].stream = stream
	_players[_active].volume_db = SILENT_DB
	_players[_active].play()
	_fade = 0.0


func stop() -> void:
	track = ""
	for player in _players:
		player.stop()


func _process(delta: float) -> void:
	if _fade >= 1.0:
		return
	_fade = minf(_fade + delta / FADE, 1.0)
	var eased := CssAnim.curve(CssAnim.EASE, _fade)
	for i in _players.size():
		var player := _players[i]
		var target := eased if i == _active else 1.0 - eased
		player.volume_db = lerpf(SILENT_DB, VOLUME_DB, target)
		if target <= 0.001 and player.playing:
			player.stop()
