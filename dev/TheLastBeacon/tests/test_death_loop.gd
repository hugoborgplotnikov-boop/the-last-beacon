extends SceneTree
## test_death_loop.gd — dying triggers the death state, then a full respawn
## at the beacon with full health. Simulates: stand next to the grunt and
## take the beating.

const HARNESS = preload("res://tests/harness.gd")
const SPAWN := Vector2(200, 603)

var frames := 0
var player: CharacterBody2D
var h: RefCounted
var min_health := 99


func _initialize() -> void:
	h = HARNESS.new("death_loop")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	# Enemy4 (on Platform3) would join the maul and skew the death timing.
	world.get_node("Enemy4").queue_free()
	print("TEST death_loop: world loaded, player at ", player.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		50:
			player.global_position = Vector2(540, 603)
			player.velocity = Vector2.ZERO
			print("  maul begins, health=", player.health)
		400:
			h.check(min_health == 0, "the hero died")
			h.check(not player.visible, "hero is hidden while dead")
		500:
			h.check(player.visible, "hero is visible after respawn")
			h.check(player.health == player.max_health, "full health after respawn")
			h.check(player.global_position.distance_to(SPAWN) < 150.0, "respawned at the beacon")
			quit(0 if h.summary() else 1)
	min_health = mini(min_health, player.health)
	return false
