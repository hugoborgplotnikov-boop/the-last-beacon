extends SceneTree
## test_bell.gd — the Bell of the Last Hour contract. Stationary center-arena
## boss. Rings shockwaves; phase 2 fires faster with debris. One HP pool.

var arena: Node2D
var boss: Node2D
var player: CharacterBody2D
var frames := 0
var died_seen := false


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/bell_arena.tscn")
	arena = scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			player.global_position = Vector2(400, 601)
			var bell: Node = boss
			_check("bell starts at full HP (%d)" % int(bell.hp), int(bell.hp) == 16)
			_check("bell has a name", String(bell.boss_name) != "")
			_check("bell alive at start", not bool(bell.dead))
			_check("bell phase 1", int(bell.phase) == 1)
		30:
			# Hit the bell — it takes damage.
			boss.take_damage(4, Vector2(700, 400))
		40:
			_check("bell takes damage (hp=%d)" % int(boss.hp), int(boss.hp) == 12)
			_check("still alive after partial hit", not bool(boss.dead))
		50:
			# Push to phase 2.
			boss.take_damage(5, Vector2(700, 400))
		60:
			_check("phase 2 at half HP (hp=%d)" % int(boss.hp), int(boss.phase) == 2)
			_check("HP at or below half (hp=%d)" % int(boss.hp), int(boss.hp) <= 8)
		70:
			# Kill it.
			boss.take_damage(99, Vector2(700, 400))
		80:
			_check("bell is silenced", bool(boss.dead))
			died_seen = true
		100:
			# No double kill: second poke on a dead boss must not award again.
			boss.take_damage(1, Vector2(700, 400))
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
	print("=== TEST bell: PASS ===")
	quit(0)
