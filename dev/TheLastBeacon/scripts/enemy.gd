extends CharacterBody2D

## Hollow Grunt — chases the hero, hurts on contact, and respawns after a
## while. One of the fallen masses.

signal died

@export var max_hp := 3
@export var speed := 55.0
@export var aggro_range := 340.0
@export var touch_damage := 1
@export var gravity := 1100.0

var hp: int
var dead := false
var knockback_time := 0.0
var touch_cooldown := 0.0
var spawn_point := Vector2.ZERO

@onready var body: Polygon2D = $Body
@onready var hurt_box: Area2D = $HurtBox
@onready var touch_box: Area2D = $TouchBox
@onready var respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	spawn_point = global_position
	hp = max_hp
	hurt_box.add_to_group("enemy_hurtbox")
	respawn_timer.timeout.connect(_respawn)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if knockback_time > 0.0:
		knockback_time -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and not player.visible:
		player = null
	if player and global_position.distance_to(player.global_position) < aggro_range:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity.x = dir.x * speed
		if dir.x != 0.0 and body.scale.x != signf(dir.x):
			body.scale.x = signf(dir.x)
	else:
		velocity.x = 0.0
	move_and_slide()

	# Contact damage ticks while the hero is in reach — hugging must hurt.
	touch_cooldown = maxf(touch_cooldown - delta, 0.0)
	if touch_cooldown <= 0.0:
		for area in touch_box.get_overlapping_areas():
			if area.get_parent().is_in_group("player"):
				area.get_parent().take_damage(touch_damage, global_position)
				touch_cooldown = 1.0
				break


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or hp <= 0:
		return
	hp -= dmg
	var dir := (global_position - from_pos).normalized()
	velocity = dir * 240.0
	velocity.y = -160.0
	knockback_time = 0.18
	body.modulate = Color(2.0, 2.0, 2.0)
	await get_tree().create_timer(0.1).timeout
	if not dead:
		body.modulate = Color.WHITE
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	body.visible = false
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	touch_box.set_deferred("monitoring", false)
	died.emit()
	respawn_timer.start()


func _respawn() -> void:
	dead = false
	hp = max_hp
	global_position = spawn_point
	velocity = Vector2.ZERO
	body.visible = true
	body.modulate = Color.WHITE
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	touch_box.set_deferred("monitoring", true)


func reset_state() -> void:
	respawn_timer.stop()
	dead = false
	hp = max_hp
	global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_time = 0.0
	body.visible = true
	body.modulate = Color.WHITE
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	touch_box.set_deferred("monitoring", true)
