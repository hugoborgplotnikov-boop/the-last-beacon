extends Node

## Music — the soundtrack layer (autoload). Two seamless loops: the menu's
## dark drone and the fight's tense pulse. One player per track, crossfaded
## on change, looped via LOOP_FORWARD. Headless-safe (no playback in tests).

var _players: Dictionary = {}   # track name -> AudioStreamPlayer
var _current := ""
var _volumes := {"menu": -16.0, "fight": -18.0}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in _volumes:
		var p := AudioStreamPlayer.new()
		p.name = name
		var stream: AudioStreamWAV = load("res://audio/%s_loop.wav" % name)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = -1
		p.stream = stream
		p.volume_db = -60.0  # start silent; fade in on play
		add_child(p)
		_players[name] = p


func play(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _players.has(name):
		return
	var target: AudioStreamPlayer = _players[name]
	if name == _current and target.playing:
		return
	_current = name
	# Fade the previous track out, fade the new one in.
	for tname in _players:
		var p: AudioStreamPlayer = _players[tname]
		var tw := create_tween()
		if tname == name:
			if not p.playing:
				p.play()
			tw.tween_property(p, "volume_db", _volumes[tname], 0.8)
		else:
			tw.tween_property(p, "volume_db", -60.0, 0.6)
			tw.tween_callback(func(): p.stop())


func stop() -> void:
	_current = ""
	for tname in _players:
		_players[tname].stop()
