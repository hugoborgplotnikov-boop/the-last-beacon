extends Node2D

## THE BELL OF THE LAST HOUR — boss #5. The position lesson.
## A massive stationary bell rings shockwaves that expand across the
## arena. You must be above them or far enough to jump. Between rings
## the bell is vulnerable. Phase 2 rings faster and debris falls.

signal died
signal hit_taken
signal big_attack

@export var boss_name := "THE BELL OF THE LAST HOUR"
@export var max_hp := 16

var hp: int
var dead := false
var phase := 1
var ring_cooldown := 2.0
var ring_timer := 3.0  # First ring comes after a moment.
var body: Node2D
var clapper: Node2D
var shockwave_scene: PackedScene = preload("res://scenes/shockwave.tscn")


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	body = $Body
	clapper = $Clapper


func scale_for_lap(lap: int) -> void:
	if lap > 1:
		max_hp += (lap - 1) * 3
		hp = max_hp
		ring_cooldown = maxf(1.1, ring_cooldown - (lap - 1) * 0.22)


func _physics_process(delta: float) -> void:
	if dead:
		return
	ring_timer -= delta
	var cd := ring_cooldown if phase == 1 else ring_cooldown * 0.62
	if ring_timer <= 0.0:
		_ring()
		ring_timer = cd
	# Clapper sways gently.
	clapper.rotation = sin(Time.get_ticks_msec() * 0.002) * 0.15


func _ring() -> void:
	big_attack.emit()
	Fx.ring(global_position, Color(0.6, 0.5, 0.25, 1), 72.0, 4.0)
	# The shockwave expands from the bell's center.
	var wave := shockwave_scene.instantiate() as Node2D
	wave.global_position = global_position + Vector2(0, 20)
	get_tree().current_scene.add_child(wave)
	# Clapper slam visual.
	var tw := create_tween()
	tw.tween_property(clapper, "rotation", 0.3, 0.06)
	tw.tween_property(clapper, "rotation", -0.2, 0.12)
	tw.tween_property(clapper, "rotation", 0.0, 0.3)
	# Phase 2: debris.
	if phase == 2:
		for i in 3:
			_spawn_debris()


func _spawn_debris() -> void:
	var rock := Polygon2D.new()
	rock.color = Color(0.22, 0.18, 0.12, 1)
	rock.polygon = PackedVector2Array([Vector2(-4, -2), Vector2(4, -2), Vector2(3, 4), Vector2(-3, 4)])
	rock.global_position = Vector2(randf_range(200, 1200), 20)
	get_tree().current_scene.add_child(rock)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var target := player.global_position.x + randf_range(-40, 40)
	var tw := create_tween()
	tw.tween_property(rock, "global_position:x", target, 0.7)
	tw.parallel().tween_property(rock, "global_position:y", 620, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(_rock_impact.bind(rock, target))


func _rock_impact(rock: Polygon2D, x: float) -> void:
	Fx.dust(Vector2(x, 620), 6, Color(0.55, 0.48, 0.38, 0.7))
	# Hit check: if the player is near the impact point.
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and absf(player.global_position.x - x) < 48 and player.global_position.y > 580:
		player.take_damage(1, Vector2(x, player.global_position.y))
	rock.queue_free()


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or hp <= 0:
		return
	hp -= dmg
	hit_taken.emit()
	body.modulate = Color(1.5, 1.3, 0.8)
	await get_tree().create_timer(0.08).timeout
	body.modulate = Color.WHITE
	if hp <= max_hp / 2 and phase == 1:
		phase = 2
		big_attack.emit()
		body.modulate = Color(1.2, 1.05, 0.7)
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	died.emit()
	Fx.burst(global_position, Color(0.6, 0.5, 0.25, 1))
	# The bell cracks.
	body.visible = false
