extends SceneTree
## test_soak.gd — a scripted end-to-end playthrough. Exercises the REAL
## runtime paths the player uses: scene changes via change_scene_to_file,
## victory -> cards -> pick (signal) -> advance, lap scaling, salt
## accumulation, and death -> run restart. Direct damage stands in for
## fighting (the fight feel itself is covered by test_captain/combat).

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var h: RefCounted
var run: Node
var arena: Node2D
var player: CharacterBody2D
var boss: Node
var phase := 0
var polling := false
var expected_arena := ""


func _initialize() -> void:
	h = HARNESS.new("soak")
	run = get_root().get_node("Run")
	# Kick off like the real game: the main scene is the captain's arena.
	change_scene_to_file("res://scenes/captain_arena.tscn")


func _physics_process(_delta: float) -> bool:
	frames += 1
	if polling:
		if current_scene != null and current_scene.scene_file_path == expected_arena:
			_on_arena_arrived()
		return false
	match phase:
		0:
			if frames >= 5:
				_grab()
				phase = 1
		1:
			# Beat the captain: victory -> cards.
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 2
		2:
			if frames >= 25:
				h.check(arena.card_panel.visible, "soak: cards offered after victory")
				h.check(run.salt == 3, "soak: salt granted (3)")
				# Pick the FIRST card through its real signal path.
				arena.card_buttons[0].pressed.emit()
				phase = 3
		3:
			# The advance should carry us to the Tidesworn's arena.
			_wait_for_arena("res://scenes/tidesworn_arena.tscn")
			phase = 4
		4:
			h.check(run.buffs.size() == 1, "soak: card buff carried into the next arena")
			h.check(run.lap == 1 and run.boss_index == 1, "soak: rotation at tidesworn, lap 1")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 5
		5:
			if frames >= 25:
				h.check(run.salt == 6, "soak: second victory salted (6)")
				arena.card_buttons[0].pressed.emit()
				phase = 6
		6:
			_wait_for_arena("res://scenes/captain_arena.tscn")
			phase = 7
		7:
			h.check(run.lap == 2, "soak: lap advanced to 2")
			h.check(boss.max_hp == 12, "soak: lap-2 captain scaled (hp=%d)" % boss.max_hp)
			h.check(run.buffs.size() == 2, "soak: two cards carried")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 8
		8:
			if frames >= 25:
				h.check(run.salt == 9, "soak: third victory salted (9)")
				# The keeper dies: the descent restarts fresh.
				player.take_damage(99, player.global_position + Vector2(10, 0))
				phase = 9
		9:
			# Death timing is deterministic: die() is deferred ~55 frames
			# (flash + i-frames), then 2.5s of run-over -> restart ~frame 230.
			# A fixed wait beats polling here (run_active is still true until
			# the deferred die() lands, so state-polling matches early).
			if frames >= 260:
				phase = 10
		10:
			h.check(run.run_active, "soak: fresh run after death")
			h.check(run.lap == 1, "soak: restart resets the lap")
			h.check(run.buffs.is_empty(), "soak: restart clears buffs")
			h.check(run.salt == 9, "soak: salt survived the death (9)")
			quit(0 if h.summary() else 1)
	return false


func _grab() -> void:
	arena = current_scene
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")


func _wait_for_arena(path: String) -> void:
	polling = true
	expected_arena = path


func _on_arena_arrived() -> void:
	polling = false
	_grab()
	frames = 0
