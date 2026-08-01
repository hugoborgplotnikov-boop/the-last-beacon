extends SceneTree
## test_bastion.gd — boss #2's fight contract: he fights autonomously,
## takes damage, enters phase 2 at half health, and dies into the victory
## beat (shards + cards). The positioning lesson (ground-warning eruption) is
## covered by the telegraph mechanics he shares with the Captain.
## (Deterministic: no input simulation — direct damage and state pokes.)

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var boss: Node
var arena: Node2D
var h: RefCounted
var run: Node


func _initialize() -> void:
	h = HARNESS.new("bastion")
	run = get_root().get_node("Run")
	run.init_run()
	var arena_scene: PackedScene = load("res://scenes/bastion_arena.tscn")
	arena = arena_scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	print("TEST bastion: arena loaded, boss hp=", boss.hp, " at ", boss.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			h.check(boss.hp == boss.max_hp, "bastion starts at full HP (%d)" % boss.hp)
			h.check(boss.boss_name == "THE BASTION", "boss carries its name")
			h.check(arena.boss_name_label.text == "THE BASTION", "arena shows the boss name")
			boss.take_damage(1, boss.global_position + Vector2(10, 0))
		60:
			h.check(boss.hp == boss.max_hp - 1, "bastion takes damage (hp=%d)" % boss.hp)
			# Keep the hero inside his attack range so he engages on his own.
			player.global_position = Vector2(900, 601)
			player.velocity = Vector2.ZERO
		120:
			h.check(boss.attack_count > 0, "bastion attacked autonomously (%d attacks)" % boss.attack_count)
		130:
			# Hero clear: the boss should keep fighting alone.
			player.global_position = Vector2(150, 601)
			player.velocity = Vector2.ZERO
		140:
			# Direct-damage contract: phase 2 at half health, death at zero.
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
		165:
			h.check(boss.phase == 2, "bastion entered phase 2 as he fell below half")
			h.check(boss.dead, "bastion died from the beating")
			h.check(not boss.body.visible, "bastion's body hidden after death")
			h.check(arena.victory_label.visible, "victory beat shown")
			h.check(run.shards == 3, "victory granted 3 shards (shards=%d)" % run.shards)
			h.check(arena.card_panel.visible, "upgrade cards offered")
			h.check(not arena.boss_bar_bg.visible, "boss bar hides on death")
			quit(0 if h.summary() else 1)
	return false
