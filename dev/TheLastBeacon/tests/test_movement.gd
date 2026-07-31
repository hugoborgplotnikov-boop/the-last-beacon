extends SceneTree
## test_movement.gd — walking, jumping, gravity, landing.
## Simulates a player: walk right, walk left, jump, land.

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var h: RefCounted


func _initialize() -> void:
	h = HARNESS.new("movement")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	print("TEST movement: world loaded, player at ", player.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			Input.action_press("move_right")
		90:
			Input.action_release("move_right")
			h.check(player.global_position.x > 300.0, "walks right")
			Input.action_press("move_left")
		170:
			Input.action_release("move_left")
			h.check(player.global_position.x < 400.0, "walks left")
			Input.action_press("jump")
		175: Input.action_release("jump")
		200:
			h.check(player.global_position.y < 580.0, "jump leaves the ground")
		260:
			h.check(player.global_position.y > 598.0, "lands back on the floor")
			quit(0 if h.summary() else 1)
	return false
