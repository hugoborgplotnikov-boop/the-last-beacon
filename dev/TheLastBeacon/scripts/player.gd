extends CharacterBody2D

## Drill 1 player: movement, jump, roll (i-frames), lantern light, attack.
## The Last Beacon — the keeper.

signal health_changed(hp: int)
signal stamina_changed(value: float)
signal embers_changed(count: int)
signal fuel_changed(value: float)
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
@export var attack_duration := 0.25
@export var attack_cooldown := 0.35
@export var attack_stamina_cost := 20.0
@export var roll_stamina_cost := 25.0
@export var stamina_regen := 45.0
@export var max_fuel := 100.0
@export var attack_fuel_cost := 5.0
@export var heal_fuel_cost := 15.0
@export var heal_amount := 2
@export var min_light_scale := 0.35
@export var max_light_scale := 1.0

var health: int
var stamina: float
var embers := 0
var fuel: float
var facing := Vector2.RIGHT
var is_rolling := false
var is_attacking := false
var can_attack := true
var i_frames := false
var dead := false
var spawn_point := Vector2.ZERO
var air_jumps_left := 1
var flame_boost := 0.0

@onready var body: Polygon2D = $Body
@onready var lantern: PointLight2D = $Lantern
@onready var lantern_flame: PointLight2D = $Lantern/Flame
@onready var attack_box: Area2D = $AttackBox
@onready var hit_zone: Area2D = $HitZone


func _ready() -> void:
	add_to_group("player")
	health = max_health
	stamina = max_stamina
	fuel = max_fuel
	spawn_point = global_position
	attack_box.monitoring = false
	attack_box.area_entered.connect(_on_attack_box_area_entered)
	hit_zone.area_entered.connect(_on_hit_zone_area_entered)


func _process(delta: float) -> void:
	# The lantern IS the fuel gauge: the flame dims and the radius shrinks as fuel drops.
	var fuel_ratio := clampf(fuel / max_fuel, 0.0, 1.0)
	lantern.energy = (1.35 + sin(Time.get_ticks_msec() * 0.008) * 0.08) * (0.35 + 0.65 * fuel_ratio)
	lantern.texture_scale = lerpf(min_light_scale, max_light_scale, fuel_ratio)
	if flame_boost > 0.0:
		flame_boost = maxf(flame_boost - delta, 0.0)
		lantern_flame.energy = 3.8
	else:
		lantern_flame.energy = 2.0 + sin(Time.get_ticks_msec() * 0.02) * 0.25


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if is_rolling:
		velocity = facing * roll_speed
	else:
		if dir != 0.0:
			facing = Vector2(dir, 0.0)
			if not is_attacking:
				body.scale = Vector2(facing.x, 1.0)
			lantern_flame.position.x = 12.0 * facing.x
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
				flame_boost = 0.3
		velocity.x = dir * speed

	move_and_slide()

	if not is_attacking and not is_rolling and stamina < max_stamina:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
		stamina_changed.emit(stamina)

	if Input.is_action_just_pressed("roll") and _can_roll():
		start_roll()
	if Input.is_action_just_pressed("attack") and _can_attack():
		start_attack()
	if Input.is_action_just_pressed("heal"):
		try_heal()


func _can_roll() -> bool:
	return not is_rolling and not is_attacking \
		and stamina >= roll_stamina_cost and is_on_floor()


func _can_attack() -> bool:
	return not is_rolling and not is_attacking \
		and stamina >= attack_stamina_cost and fuel >= attack_fuel_cost and can_attack


func start_roll() -> void:
	stamina -= roll_stamina_cost
	stamina_changed.emit(stamina)
	is_rolling = true
	i_frames = true
	body.scale = Vector2(facing.x * 1.2, 0.8)
	await get_tree().create_timer(roll_time).timeout
	is_rolling = false
	i_frames = false
	body.scale = Vector2(facing.x, 1.0)


func start_attack() -> void:
	stamina -= attack_stamina_cost
	stamina_changed.emit(stamina)
	fuel -= attack_fuel_cost
	fuel_changed.emit(fuel)
	is_attacking = true
	can_attack = false
	attack_box.position = Vector2(16.0 * facing.x, 2.0)
	attack_box.monitoring = true
	await get_tree().create_timer(attack_duration).timeout
	attack_box.monitoring = false
	is_attacking = false
	await get_tree().create_timer(maxf(attack_cooldown - attack_duration, 0.0)).timeout
	can_attack = true


func _on_attack_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		area.get_parent().take_damage(attack_damage, global_position)


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


func add_embers(count: int) -> void:
	embers += count
	embers_changed.emit(embers)


func refuel(amount: float) -> void:
	fuel = minf(max_fuel, fuel + amount)
	fuel_changed.emit(fuel)


func try_heal() -> void:
	if dead or health >= max_health or fuel < heal_fuel_cost:
		return
	fuel -= heal_fuel_cost
	fuel_changed.emit(fuel)
	heal(heal_amount)


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
	fuel = max_fuel
	i_frames = true
	can_attack = true
	is_attacking = false
	is_rolling = false
	attack_box.monitoring = false
	body.scale = Vector2(facing.x, 1.0)
	lantern_flame.position.x = 12.0 * facing.x
	body.modulate = Color.WHITE
	air_jumps_left = 1
	visible = true
	set_physics_process(true)
	health_changed.emit(health)
	stamina_changed.emit(stamina)
	await get_tree().create_timer(1.0).timeout
	i_frames = false
