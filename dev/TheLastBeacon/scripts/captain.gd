extends CharacterBody2D

## The Captain — first boss of the descent. A drowned shipmaster who refuses
## to abandon his wreck. Teaches the core lesson: watch the telegraph, dodge,
## punish. At half health he enters phase 2: faster recoveries and a new move
## (the broadside sweep).

signal died
signal hit_taken
signal big_attack

enum State { IDLE, TELEGRAPH_LUNGE, LUNGE, TELEGRAPH_SLAM, SLAM, TELEGRAPH_SWEEP, SWEEP, RECOVER, DEAD }

@export var max_hp := 10
@export var boss_name := "THE CAPTAIN"
@export var walk_speed := 70.0
@export var lunge_speed := 430.0
@export var touch_damage := 1
@export var gravity := 1100.0
@export var attack_range := 480.0
@export var slam_range := 170.0

var hp: int
var phase := 1
var state := State.IDLE
var busy := false
var dead := false
var facing := Vector2.LEFT
var attack_count := 0
var touch_cooldown := 0.0
var spawn_point := Vector2.ZERO
# Cancels stale attack coroutines on death/reset (the fight-id pattern).
var fight_id := 0

@onready var body: Polygon2D = $Body
@onready var hurt_box: Area2D = $HurtBox
@onready var touch_box: Area2D = $TouchBox
@onready var slam_zone: Polygon2D = $SlamZone
@onready var sweep_box: Area2D = $SweepBox


func _ready() -> void:
	spawn_point = global_position
	hp = max_hp
	hurt_box.add_to_group("enemy_hurtbox")
	body.scale.x = facing.x


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and not player.visible:
		player = null
	if state == State.IDLE and not busy:
		if player and global_position.distance_to(player.global_position) < attack_range:
			velocity.x = 0.0
			_try_attack(player)
		elif player:
			var dir: float = signf(player.global_position.x - global_position.x)
			velocity.x = dir * walk_speed
			_face(player)
		else:
			velocity.x = 0.0
	move_and_slide()

	# Contact damage ticks while the keeper is in reach — hugging must hurt.
	touch_cooldown = maxf(touch_cooldown - delta, 0.0)
	if touch_cooldown <= 0.0:
		for area in touch_box.get_overlapping_areas():
			if area.get_parent().is_in_group("player"):
				area.get_parent().take_damage(touch_damage, global_position)
				touch_cooldown = 1.0
				break


func _face(player: Node2D) -> void:
	if player.global_position.x != global_position.x:
		facing = Vector2(signf(player.global_position.x - global_position.x), 0.0)
	body.scale.x = facing.x
	slam_zone.position.x = 80.0 * facing.x
	sweep_box.position.x = 80.0 * facing.x


func _try_attack(player: Node2D) -> void:
	busy = true
	attack_count += 1
	var fid := fight_id
	var pick: int
	if phase == 1:
		pick = randi() % 2   # lunge or slam
	else:
		pick = randi() % 3   # lunge, slam, or broadside sweep
	match pick:
		0:
			await _lunge(player, fid)
		1:
			await _slam(player, fid)
		_:
			await _sweep(player, fid)
	if fid != fight_id or dead:
		return
	# Punish window, then he resets to idle.
	state = State.RECOVER
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	busy = false
	state = State.IDLE


func _lunge(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_LUNGE
	body.modulate = Color(1.6, 1.6, 1.6)
	await get_tree().create_timer(0.45).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	state = State.LUNGE
	velocity.x = facing.x * lunge_speed
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	velocity.x = 0.0
	state = State.RECOVER
	await get_tree().create_timer(0.7 if phase == 1 else 0.5).timeout
	if fid != fight_id or dead:
		return


func _slam(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_SLAM
	body.modulate = Color(1.6, 1.6, 1.6)
	slam_zone.visible = true
	await get_tree().create_timer(0.55).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	slam_zone.visible = false
	state = State.SLAM
	# The red zone marks exactly where the slam lands.
	big_attack.emit()
	var offset: Vector2 = player.global_position - global_position
	if absf(offset.y) < 70.0 and offset.x * facing.x > -30.0 and offset.x * facing.x < slam_range:
		player.take_damage(touch_damage, global_position)
	await get_tree().create_timer(0.3).timeout
	if fid != fight_id or dead:
		return
	state = State.RECOVER
	await get_tree().create_timer(0.9 if phase == 1 else 0.65).timeout
	if fid != fight_id or dead:
		return


func _sweep(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_SWEEP
	body.modulate = Color(1.6, 1.6, 1.6)
	sweep_box.monitoring = true
	sweep_box.visible = true
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	state = State.SWEEP
	# The sweep damages once per victim while the blade is out.
	big_attack.emit()
	var victims: Array[Node] = []
	for i in 8:
		await get_tree().create_timer(0.05).timeout
		if fid != fight_id or dead:
			return
		for area in sweep_box.get_overlapping_areas():
			var victim: Node = area.get_parent()
			if victim.is_in_group("player") and not victims.has(victim):
				victims.append(victim)
				victim.take_damage(touch_damage, global_position)
	sweep_box.monitoring = false
	sweep_box.visible = false
	state = State.RECOVER
	await get_tree().create_timer(0.9 if phase == 1 else 0.7).timeout
	if fid != fight_id or dead:
		return


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead:
		return
	hp -= dmg
	# Bosses barely flinch.
	var dir := (global_position - from_pos).normalized()
	velocity = dir * 120.0
	velocity.y = -60.0
	body.modulate = Color(2.0, 2.0, 2.0)
	hit_taken.emit()
	# Hit-stop: a tiny time-scale dip makes every landed hit land HARD.
	# Skipped in headless so the test suite stays frame-deterministic.
	if DisplayServer.get_name() != "headless":
		Engine.time_scale = 0.2
		await get_tree().create_timer(0.04).timeout
		Engine.time_scale = 1.0
	if hp <= max_hp / 2 and phase == 1:
		phase = 2
	await get_tree().create_timer(0.08).timeout
	if not dead:
		body.modulate = Color.WHITE
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	state = State.DEAD
	fight_id += 1
	velocity = Vector2.ZERO
	body.visible = false
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	touch_box.set_deferred("monitoring", false)
	sweep_box.monitoring = false
	sweep_box.visible = false
	slam_zone.visible = false
	died.emit()


## Each lap of the descent makes the boss meaner. Called by the arena's
## _ready with the current lap (1 = first fight, unchanged).
func scale_for_lap(lap: int) -> void:
	if lap <= 1:
		return
	max_hp = 10 + (lap - 1) * 2
	walk_speed = 70.0 * (1.0 + 0.08 * float(lap - 1))
	hp = max_hp


func reset_state() -> void:
	fight_id += 1
	dead = false
	busy = false
	state = State.IDLE
	phase = 1
	hp = max_hp
	global_position = spawn_point
	velocity = Vector2.ZERO
	body.visible = true
	body.modulate = Color.WHITE
	body.scale.x = facing.x
	slam_zone.visible = false
	sweep_box.monitoring = false
	sweep_box.visible = false
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	touch_box.set_deferred("monitoring", true)
