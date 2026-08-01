extends Node

## Sfx — the sound layer (autoload). Loads the generated WAVs once and
## plays them through a shared pool. Headless-safe: playback is skipped
## in headless so tests stay deterministic and fast.

var _pools: Dictionary = {}
var _next_pool_index: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _pool(name: String) -> AudioStreamPlayer:
	if not _pools.has(name):
		var pool: Array[AudioStreamPlayer] = []
		var stream: AudioStream = load("res://audio/%s.wav" % name)
		for i in 3:
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.volume_db = -8.0
			add_child(p)
			pool.append(p)
		_pools[name] = pool
		_next_pool_index[name] = 0
	return _pools[name][_next_pool_index[name]]


func play(name: String, volume_db := -8.0, pitch := 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var p: AudioStreamPlayer = _pool(name)
	_next_pool_index[name] = (_next_pool_index[name] + 1) % 3
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()
