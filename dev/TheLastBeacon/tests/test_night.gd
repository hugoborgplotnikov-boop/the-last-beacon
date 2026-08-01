extends SceneTree
## test_night.gd — the Night contract. Fast, teleporting, small-hitbox boss.
## Phase 2 adds shadow-copy strikes.

var arena: Node2D
var boss: Node2D
var player: CharacterBody2D
var frames := 0
var initial_pos: Vector2


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/night_arena.tscn")
	arena = scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	initial_pos = boss.global_position


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			player.global_position = Vector2(700, 601)
			var n: Node = boss
			_check("night starts at full HP (%d)" % int(n.hp), int(n.hp) == 22)
			_check("night has a name", String(n.boss_name) != "")
			_check("night alive at start", not bool(n.dead))
			_check("night phase 1", int(n.phase) == 1)
			_check("night positioned in arena", n.global_position.x > 100)
		30:
			# The night drifts toward the player.
			boss.take_damage(6, Vector2(700, 601))
		40:
			_check("night takes damage (hp=%d)" % int(boss.hp), int(boss.hp) == 16)
			_check("still alive after partial hit", not bool(boss.dead))
		50:
			# Push to phase 2.
			boss.take_damage(6, Vector2(700, 601))
		60:
			_check("phase 2 at half HP", int(boss.phase) == 2)
			_check("HP at or below half (hp=%d)" % int(boss.hp), int(boss.hp) <= 11)
		70:
			# Kill her.
			boss.take_damage(99, Vector2(700, 601))
		80:
			_check("the night falls", bool(boss.dead))
			_check("body hidden on death", not boss.body.visible)
		100:
			# No double kill.
			boss.take_damage(1, Vector2(700, 601))
		110:
			_check("still dead after second hit", bool(boss.dead))
			_finish()
	return false


func _check(label: String, cond: bool) -> void:
	if cond:
		print("  ok: ", label)
	else:
		printerr("  FAIL: ", label)


func _finish() -> void:
	print("=== TEST night: PASS ===")
	quit(0)
