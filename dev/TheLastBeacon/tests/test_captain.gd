extends SceneTree
## test_captain.gd — the first boss contract: he fights autonomously, takes
## damage, enters phase 2 at half health, dies into the victory beat, and the
## whole fight resets when the keeper falls. (Deterministic: no input
## simulation — direct damage and state pokes.)

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var captain: Node
var arena: Node2D
var h: RefCounted


func _initialize() -> void:
	h = HARNESS.new("captain")
	var arena_scene: PackedScene = load("res://scenes/captain_arena.tscn")
	arena = arena_scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	captain = arena.get_node("Captain")
	print("TEST captain: arena loaded, captain hp=", captain.hp, " at ", captain.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			h.check(captain.hp == captain.max_hp, "captain starts at full HP (%d)" % captain.hp)
			# An anchor hit lands (the same hurtbox contract as the grunts).
			captain.take_damage(1, captain.global_position + Vector2(10, 0))
		60:
			h.check(captain.hp == captain.max_hp - 1, "captain takes damage (hp=%d)" % captain.hp)
			# Keep the keeper inside his attack range so he engages on his own.
			player.global_position = Vector2(900, 601)
			player.velocity = Vector2.ZERO
		120:
			h.check(captain.attack_count > 0, "captain attacked autonomously (%d attacks)" % captain.attack_count)
		130:
			# Keeper clear: the boss should keep fighting alone.
			player.global_position = Vector2(150, 601)
			player.velocity = Vector2.ZERO
		140:
			# Direct-damage contract: phase 2 at half health, death at zero.
			captain.take_damage(99, captain.global_position + Vector2(10, 0))
		160:
			h.check(captain.phase == 2, "captain entered phase 2 as he fell below half")
			h.check(captain.dead, "captain died from the beating")
			h.check(not captain.body.visible, "captain's body hidden after death")
			h.check(arena.victory_label.visible, "victory beat shown")
		200:
			# The keeper's death restarts the fight (i-frames long expired).
			player.take_damage(99, player.global_position + Vector2(10, 0))
		400:
			h.check(captain.visible and captain.hp == captain.max_hp and captain.phase == 1,
				"fight reset after the keeper's death (hp=%d phase=%d)" % [captain.hp, captain.phase])
			h.check(player.visible and player.health == player.max_health, "keeper respawned")
			quit(0 if h.summary() else 1)
	return false
