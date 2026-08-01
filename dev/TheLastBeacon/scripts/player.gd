extends CharacterBody2D

## Drill 1 player: movement, jump, roll (i-frames), greatsword attack.
## The Last Beacon — the hero.

signal health_changed(hp: int)
signal stamina_changed(value: float)
signal died

@export var speed := 220.0
@export var jump_velocity := -420.0
@export var double_jump_velocity := -400.0
@export var gravity := 1100.0
@export var roll_speed := 430.0
@export var roll_time := 0.3
@export var max_health := 5
@export var max_stamina := 100.0
@export var attack_damage := 1
@export var attack_duration := 0.32
@export var attack_cooldown := 0.45
@export var attack_stamina_cost := 20.0
@export var roll_stamina_cost := 25.0
@export var stamina_regen := 45.0

var health: int
var stamina: float
var facing := Vector2.RIGHT
var is_rolling := false
var is_attacking := false
var can_attack := true
var i_frames := false
var dead := false
var spawn_point := Vector2.ZERO
var air_jumps_left := 1
var swing_tween: Tween
var lifesteal := 0
var _trail_world: Array[Vector2] = []

@onready var body: Node2D = $Body
@onready var sword: Node2D = $Greatsword
@onready var trail: Line2D = $Greatsword/Trail
@onready var attack_box: Area2D = $AttackBox
@onready var hit_zone: Area2D = $HitZone


func _ready() -> void:
	add_to_group("player")
	health = max_health
	stamina = max_stamina
	spawn_point = global_position
	attack_box.monitoring = false
	attack_box.area_entered.connect(_on_attack_box_area_entered)
	hit_zone.area_entered.connect(_on_hit_zone_area_entered)


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var was_airborne := not is_on_floor()

	if is_rolling:
		velocity = facing * roll_speed
	else:
		if dir != 0.0:
			facing = Vector2(dir, 0.0)
			if not is_attacking:
				body.scale = Vector2(facing.x, 1.0)
			sword.position.x = 18.0 * facing.x
			sword.scale.x = facing.x
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			air_jumps_left = 1
		if Input.is_action_just_pressed("jump") and not is_attacking:
			if is_on_floor():
				velocity.y = jump_velocity
			elif air_jumps_left > 0:
				velocity.y = double_jump_velocity
				air_jumps_left -= 1
		velocity.x = dir * speed

	move_and_slide()

	# Boots on stone: dust when landing, and a scuff while rolling.
	if was_airborne and is_on_floor():
		Fx.dust(global_position + Vector2(0, 17), 12)
	if is_rolling and Engine.get_physics_frames() % 6 == 0:
		Fx.dust(global_position + Vector2(-facing.x * 8, 17), 4)

	_update_trail()

	if not is_attacking and not is_rolling and stamina < max_stamina:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
		stamina_changed.emit(stamina)

	if Input.is_action_just_pressed("roll") and _can_roll():
		start_roll()
	if Input.is_action_just_pressed("attack") and _can_attack():
		start_attack()


## The blade's ribbon: the tip's recent path, in the sword's own space.
## Only alive during a swing — it fades out and clears itself after.
func _update_trail() -> void:
	if is_attacking:
		trail.add_point(Vector2(0, -30))
		# The whole ribbon must trail in world space, so shift the older
		# points back by the sword's motion since last frame.
		var pts := trail.points
		var xf := sword.global_transform
		for i in pts.size() - 1:
			pts[i] = xf.affine_inverse() * _trail_world[i]
		trail.points = pts
		_trail_world.append(xf * Vector2(0, -30))
		while trail.get_point_count() > 12:
			trail.remove_point(0)
			_trail_world.remove_at(0)
		trail.modulate.a = 1.0
	elif trail.get_point_count() > 0:
		trail.modulate.a = maxf(0.0, trail.modulate.a - 0.12)
		if trail.modulate.a <= 0.0:
			trail.clear_points()
			_trail_world.clear()


func _can_roll() -> bool:
	return not is_rolling and not is_attacking \
		and stamina >= roll_stamina_cost and is_on_floor()


func _can_attack() -> bool:
	return not is_rolling and not is_attacking \
		and stamina >= attack_stamina_cost and can_attack


func start_roll() -> void:
	stamina -= roll_stamina_cost
	stamina_changed.emit(stamina)
	is_rolling = true
	i_frames = true
	await get_tree().create_timer(roll_time).timeout
	is_rolling = false
	i_frames = false
	body.scale = Vector2(facing.x, 1.0)


func start_attack() -> void:
	stamina -= attack_stamina_cost
	stamina_changed.emit(stamina)
	is_attacking = true
	can_attack = false
	attack_box.position = Vector2(20.0 * facing.x, 0.0)
	attack_box.monitoring = true
	# The greatsword chops: a single outward arc — from rest, the blade
	# accelerates forward-down, away from the hero. The angle flips with
	# facing (scale.x = -1 mirrors the blade's content but NOT the rotation
	# direction — Godot applies rotation after scale).
	sword.rotation = 0.0
	swing_tween = create_tween()
	swing_tween.tween_property(sword, "rotation", 1.9 * facing.x, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(attack_duration).timeout
	attack_box.monitoring = false
	is_attacking = false
	if swing_tween and swing_tween.is_valid():
		swing_tween.kill()
	sword.rotation = 0.0
	await get_tree().create_timer(maxf(attack_cooldown - attack_duration, 0.0)).timeout
	can_attack = true


func _on_attack_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var target: Node2D = area.get_parent()
		target.take_damage(attack_damage, global_position)
		# Steel on steel: sparks thrown back along the blow.
		var contact: Vector2 = global_position.lerp(target.global_position, 0.6)
		Fx.sparks(contact, (target.global_position - global_position).normalized())
		if lifesteal > 0 and not dead:
			heal(lifesteal)


func _on_hit_zone_area_entered(area: Area2D) -> void:
	# Touch damage from enemies is delivered by the enemy's touch box.
	pass


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or i_frames or is_rolling:
		return
	health -= dmg
	health_changed.emit(health)
	i_frames = true
	var knock := (global_position - from_pos).normalized()
	velocity = knock * 260.0
	velocity.y = -180.0
	body.modulate = Color(2.0, 0.6, 0.6)
	await get_tree().create_timer(0.12).timeout
	body.modulate = Color.WHITE
	await get_tree().create_timer(0.8).timeout
	i_frames = false
	if health <= 0:
		die()


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health)


## Applied by the arena's _ready from the run state: every buff the hero
## has collected on this gauntlet. Healing to the new max is part of the pick.
func apply_buffs(buffs: Dictionary) -> void:
	max_health += buffs.get("hp", 0)
	attack_damage += buffs.get("damage", 0)
	max_stamina += buffs.get("stamina", 0.0)
	attack_stamina_cost = maxf(5.0, attack_stamina_cost - buffs.get("stamina_discount", 0.0))
	attack_cooldown = maxf(0.25, attack_cooldown - buffs.get("cooldown", 0.0))
	speed += buffs.get("speed", 0.0)
	stamina_regen *= 1.0 + buffs.get("regen", 0.0)
	lifesteal = buffs.get("lifesteal", 0)
	attack_box.scale = Vector2(1.0 + buffs.get("reach", 0.0), 1.0)
	health = max_health


func die() -> void:
	dead = true
	died.emit()
	visible = false
	set_physics_process(false)


func reset() -> void:
	dead = false
	global_position = spawn_point
	velocity = Vector2.ZERO
	health = max_health
	stamina = max_stamina
	i_frames = true
	can_attack = true
	is_attacking = false
	is_rolling = false
	attack_box.monitoring = false
	body.scale = Vector2(facing.x, 1.0)
	sword.position.x = 18.0 * facing.x
	sword.scale.x = facing.x
	if swing_tween and swing_tween.is_valid():
		swing_tween.kill()
	sword.rotation = 0.0
	body.modulate = Color.WHITE
	air_jumps_left = 1
	visible = true
	set_physics_process(true)
	health_changed.emit(health)
	stamina_changed.emit(stamina)
	await get_tree().create_timer(1.0).timeout
	i_frames = false
