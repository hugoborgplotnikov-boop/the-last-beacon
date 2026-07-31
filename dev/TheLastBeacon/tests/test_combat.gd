extends SceneTree
## test_combat.gd — melee attacks damage and kill the grunt; its ember drops
## and is picked up. Simulates a player walking in and swinging five times.

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var enemy1: Node
var h: RefCounted
var embers_before := 0


func _initialize() -> void:
	h = HARNESS.new("combat")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	enemy1 = world.get_node("Enemy1")
	print("TEST combat: world loaded, player at ", player.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			Input.action_press("move_right")
		110:
			Input.action_release("move_right")
			h.check(player.global_position.x > 300.0, "reached the grunt")
			h.check(enemy1.hp == enemy1.max_hp, "grunt starts at full HP")
			embers_before = player.embers
		120: Input.action_press("attack")
		130: Input.action_release("attack")
		150: Input.action_press("attack")
		160: Input.action_release("attack")
		180: Input.action_press("attack")
		190: Input.action_release("attack")
		210: Input.action_press("attack")
		220: Input.action_release("attack")
		240: Input.action_press("attack")
		250: Input.action_release("attack")
		300:
			h.check(enemy1.dead, "grunt died within the attack windows")
		320:
			h.check(player.embers >= embers_before + 1, "grunt's ember dropped and was picked up")
		400:
			h.check(player.health > 0, "keeper survived the fight")
			quit(0 if h.summary() else 1)
	return false
