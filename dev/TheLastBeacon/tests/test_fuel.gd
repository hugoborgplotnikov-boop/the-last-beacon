extends SceneTree
## test_fuel.gd — the light contract: fuel is spent by attacks, refilled by
## embers, drunk to heal (H), scales the lantern radius, and gates attacks
## at 0 fuel.

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var enemy1: Node
var h: RefCounted


func _initialize() -> void:
	h = HARNESS.new("fuel")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	enemy1 = world.get_node("Enemy1")
	# Keep the other grunts out of the scenario.
	for name_to_free in ["Enemy2", "Enemy3", "Enemy4", "Enemy5"]:
		world.get_node(name_to_free).queue_free()
	print("TEST fuel: world loaded, keeper fuel=", player.fuel)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			h.check(player.fuel == player.max_fuel, "keeper starts with full fuel (%.0f)" % player.fuel)
			# Walk right: over the world ember at (260, 590), then to the grunt.
			Input.action_press("move_right")
		110:
			Input.action_release("move_right")
			h.check(player.global_position.x > 300.0, "reached the grunt")
			h.check(player.embers >= 1, "world ember was picked up (embers=%d)" % player.embers)
		120: Input.action_press("attack")
		130: Input.action_release("attack")
		200:
			h.check(player.fuel < player.max_fuel, "an attack spent fuel (fuel=%.1f)" % player.fuel)
			h.check(player.lantern.texture_scale < player.max_light_scale,
				"lantern radius shrank with the fuel (scale=%.2f)" % player.lantern.texture_scale)
			# Move clear of the grunt so contact ticks can't skew the heal check.
			player.global_position = Vector2(200, 601)
			player.velocity = Vector2.ZERO
			# Heal decision: H drinks fuel to restore HP.
			player.health = player.max_health - 2
			player.health_changed.emit(player.health)
			Input.action_press("heal")
		205: Input.action_release("heal")
		240:
			h.check(player.health == player.max_health, "H restored health")
			h.check(player.fuel < player.max_fuel - 10.0,
				"healing drank fuel (fuel=%.1f)" % player.fuel)
			# A dead lantern cannot fight: 0 fuel blocks the attack.
			player.fuel = 0.0
			player.fuel_changed.emit(player.fuel)
		260: Input.action_press("attack")
		270: Input.action_release("attack")
		320:
			h.check(not player.is_attacking, "no attack possible at 0 fuel")
			h.check(enemy1.hp > 0, "grunt unharmed at 0 fuel (hp=%d)" % enemy1.hp)
			quit(0 if h.summary() else 1)
	return false
