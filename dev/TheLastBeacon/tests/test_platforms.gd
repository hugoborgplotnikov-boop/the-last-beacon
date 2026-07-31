extends SceneTree
## test_platforms.gd — level geometry sanity (deterministic, no input
## simulation): platforms don't overlap, are inside the arena, their collision
## matches their visuals, and Platform3 is floor-reachable within the keeper's
## double-jump arc. (The jump arc itself is exercised in test_movement.)

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var h: RefCounted
var world: Node2D
var player: CharacterBody2D
var p1: Node2D
var p3: Node2D


func _initialize() -> void:
	h = HARNESS.new("platforms")
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	world = world_scene.instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	p1 = world.get_node("Platform1")
	p3 = world.get_node("Platform3")
	print("TEST platforms: Platform1 at ", p1.position, "  Platform3 at ", p3.position)


func platform_top(p: Node2D) -> float:
	var shape_node: CollisionShape2D = p.get_node("CollisionShape2D")
	var rect := shape_node.shape as RectangleShape2D
	return p.position.y + shape_node.position.y - rect.size.y / 2.0


func _physics_process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		# Geometry: no overlap, inside the arena.
		var p3_rect := Rect2(p3.position - Vector2(110, 13), Vector2(220, 26))
		var p1_rect := Rect2(p1.position - Vector2(110, 13), Vector2(220, 26))
		h.check(not p3_rect.intersects(p1_rect), "Platform3 does not overlap Platform1")
		h.check(p3.position.x > 110.0 and p3.position.x < 1170.0, "Platform3 inside the arena")

		# Recipe: collision must match the visual (regression for the offset bug).
		var visual: Polygon2D = p3.get_node("Visual")
		var collision_top := platform_top(p3)
		var visual_top := p3.position.y + visual.polygon[0].y
		h.check(absf(collision_top - visual_top) < 0.5,
			"collision top matches the visual top (%.1f vs %.1f)" % [collision_top, visual_top])

		# Reachability: the floor-to-platform rise must fit the double-jump
		# arc with at least 10px of margin.
		var floor_shape: CollisionShape2D = world.get_node("Floor/CollisionShape2D")
		var floor_rect := floor_shape.shape as RectangleShape2D
		var floor_top := floor_shape.global_position.y - floor_rect.size.y / 2.0
		var player_shape: CollisionShape2D = player.get_node("CollisionShape2D")
		var player_rect := player_shape.shape as RectangleShape2D
		var feet_offset := player_shape.position.y + player_rect.size.y / 2.0
		var rest_origin := floor_top - feet_offset
		var land_origin := collision_top - feet_offset
		var rise_needed := rest_origin - land_origin
		var max_rise: float = (player.jump_velocity * player.jump_velocity \
			+ player.double_jump_velocity * player.double_jump_velocity) \
			/ (2.0 * player.gravity)
		h.check(rise_needed <= max_rise - 10.0,
			"Platform3 floor-reachable with margin (needs %.0fpx, arc %.0fpx)"
			% [rise_needed, max_rise])
		quit(0 if h.summary() else 1)
	return false
