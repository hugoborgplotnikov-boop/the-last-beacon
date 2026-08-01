extends SceneTree
## test_soak.gd — a scripted end-to-end playthrough. Exercises the REAL
## runtime paths the player uses: scene changes via change_scene_to_file,
## victory -> cards -> pick (signal) -> advance, lap scaling, shards
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
	# Clean slate: wipe the save so the test is deterministic.
	var cfg := ConfigFile.new()
	cfg.save("user://beacon_save.cfg")
	run.load_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.save_game()
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
				h.check(run.shards == 3, "soak: shards granted (3)")
				# Pick the FIRST card through its real signal path.
				arena.card_buttons[0].pressed.emit()
				phase = 3
		3:
			# The advance should carry us to the Bastion's arena.
			_wait_for_arena("res://scenes/bastion_arena.tscn")
			phase = 4
		4:
			h.check(not run.buffs.is_empty(), "soak: card buff carried into the next arena")
			h.check(run.lap == 1 and run.boss_index == 1, "soak: rotation at bastion, lap 1")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 5
		5:
			if frames >= 25:
				h.check(run.shards == 6, "soak: second victory sharded (6)")
				# Deterministic pick: call the handler with a fixed card id
				# (the random-draw signal path is covered by pick 1 above).
				arena._on_card_pressed("tempered_steel")
				phase = 6
		6:
			_wait_for_arena("res://scenes/fallen_beacon_arena.tscn")
			phase = 7
		7:
			h.check(run.lap == 1 and run.boss_index == 2, "soak: rotation at the Fallen Beacon, lap 1")
			h.check(run.buffs.get("damage", 0) >= 1, "soak: Tempered Steel carried into the mirror fight")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 8
		8:
			if frames >= 25:
				h.check(run.shards == 9, "soak: third victory sharded (9)")
				arena.card_buttons[0].pressed.emit()
				phase = 9
		9:
			# Boss #4: the Hollow Choir.
			_wait_for_arena("res://scenes/choir_arena.tscn")
			phase = 10
		10:
			h.check(run.lap == 1 and run.boss_index == 3, "soak: rotation at the Choir, lap 1")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 11
		11:
			if frames >= 25:
				h.check(run.shards == 12, "soak: fourth victory sharded (12)")
				arena.card_buttons[0].pressed.emit()
				phase = 12
		12:
			# Boss #5: the Bell of the Last Hour.
			_wait_for_arena("res://scenes/bell_arena.tscn")
			phase = 13
		13:
			h.check(run.lap == 1 and run.boss_index == 4, "soak: rotation at the Bell, lap 1")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 14
		14:
			if frames >= 25:
				h.check(run.shards == 15, "soak: fifth victory sharded (15)")
				arena.card_buttons[0].pressed.emit()
				phase = 15
		15:
			# Boss #6: the Night.
			_wait_for_arena("res://scenes/night_arena.tscn")
			phase = 16
		16:
			h.check(run.lap == 1 and run.boss_index == 5, "soak: rotation at the Night, lap 1")
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 17
		17:
			if frames >= 25:
				h.check(run.shards == 18, "soak: sixth victory sharded (18)")
				arena.card_buttons[0].pressed.emit()
				phase = 18
		18:
			# A full lap of six: next is lap-2 Captain.
			_wait_for_arena("res://scenes/captain_arena.tscn")
			phase = 19
		19:
			h.check(run.lap == 2, "soak: lap advanced to 2")
			h.check(boss.max_hp == 12, "soak: lap-2 captain scaled (hp=%d)" % boss.max_hp)
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
			phase = 20
		20:
			if frames >= 25:
				h.check(run.shards == 21, "soak: lap-2 shards (21)")
				player.take_damage(99, player.global_position + Vector2(10, 0))
				phase = 21
		21:
			if frames >= 260:
				phase = 22
		22:
			h.check(run.run_active, "soak: fresh run after death")
			h.check(run.lap == 1, "soak: restart resets the lap")
			h.check(run.buffs.is_empty(), "soak: restart clears buffs")
			h.check(run.shards == 21, "soak: shards survived the death (21)")
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
