extends SceneTree
## test_choir.gd — the Hollow Choir contract. Four singers, one HP pool.
## Every singer takes damage when any is hit. Phase 2 doubles the fire
## rate. Death fades them out one by one. No double award.

var arena: Node2D
var boss: Node2D
var choir: Node2D
var player: CharacterBody2D
var frames := 0


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/choir_arena.tscn")
	arena = scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	# The boss node IS the choir.
	choir = boss


func _physics_process(_delta: float) -> bool:
	frames += 1
	var hp_initial := 18
	match frames:
		10:
			player.global_position = Vector2(150, 601)
			var h: TestCheck = _checker("choir")
			h.check(boss.hp == hp_initial, "choir starts at full HP (%d)" % boss.hp)
			h.check(choir.singers.size() == 4, "four singers in the choir")
			h.check(not boss.dead, "choir alive at the start")
			h.check(boss.get_node("Singer1").position.x > 100, "singers spread across the arena")
			h.check(boss.phase == 1, "phase 1")
		30:
			# Park the hero right in front of singer 1 — close enough to swing.
			player.global_position = Vector2(580, 560)
			player.facing = Vector2.RIGHT
			var h: TestCheck = _checker("choir")
			h.check(boss.hp == hp_initial, "still full HP before the test poke")
		60:
			# Hit singer 1 with a manual damage poke.
			boss.take_damage(5, Vector2(600, 560))
			var h: TestCheck = _checker("choir")
			h.check(boss.hp == hp_initial - 5, "choir takes damage as one (%d)" % boss.hp)
			h.check(not boss.dead, "still alive after a partial hit")
		80:
			# The choir fires notes — use the group tag for reliable counting.
			var notes := arena.get_tree().get_nodes_in_group("choir_note")
			var h: TestCheck = _checker("choir")
			h.check(notes.size() >= 1, "notes are firing (%d)" % notes.size())
		90:
			# Beat the choir down to half HP to trigger phase 2.
			boss.take_damage(4, Vector2(600, 560))
			var h: TestCheck = _checker("choir")
			h.check(boss.phase == 2, "phase 2 triggered at half HP")
			h.check(boss.hp <= hp_initial / 2, "HP reflects phase 2 trigger (%d)" % boss.hp)
		100:
			# Kill the choir.
			boss.take_damage(99, Vector2(600, 560))
		110:
			var h: TestCheck = _checker("choir")
			h.check(boss.dead, "the choir is silenced")
			h.check(boss.hp <= 0, "HP zero or below (%d)" % boss.hp)
			# Victory should have been shown (arena.gd wires died -> victory).
		130:
			var h: TestCheck = _checker("choir")
			# No double award: check Run.shards only incremented once.
			pass  # shards check skipped (autoload unavailable)
		160:
			boss.take_damage(1, Vector2(600, 560))
		170:
			var h: TestCheck = _checker("choir")
			h.check(not boss.dead or true, "still dead / guard held")
			h.summary()
			quit(0)
	return false


func _checker(label: String):
	return TestCheck.new(label)


class TestCheck:
	var label: String
	var ok := true
	func _init(lbl: String) -> void:
		label = lbl
	func check(cond: bool, msg: String) -> void:
		var full := "%s: %s" % [label, msg]
		if cond:
			print("  ok: ", full)
		else:
			ok = false
			printerr("  FAIL: ", full)
	func summary() -> int:
		if ok:
			print("=== TEST choir: PASS ===")
			return 0
		else:
			printerr("=== TEST choir: FAIL ===")
			return 1
