extends SceneTree
## test_roll.gd — the roll dashes forward and its i-frames absorb contact
## damage. Simulates: roll on flat ground, then roll through the grunt.

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var h: RefCounted


func _initialize() -> void:
	h = HARNESS.new("roll")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	print("TEST roll: world loaded, player at ", player.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			Input.action_press("roll")
		20:
			h.check(player.is_rolling, "roll is in progress")
		30: Input.action_release("roll")
		40:
			h.check(player.global_position.x > 260.0, "roll dashed forward")
		45:
			h.check(not player.is_rolling, "roll ended after its duration")
		49:
			# Begin rolling again BEFORE teleporting, so i-frames are active
			# the moment the grunt makes contact.
			Input.action_press("roll")
		50:
			player.global_position = Vector2(540, 603)
			player.velocity = Vector2.ZERO
		69: Input.action_release("roll")
		110:
			h.check(player.health == player.max_health, "i-frames absorbed the grunt's contact damage")
			quit(0 if h.summary() else 1)
	return false
