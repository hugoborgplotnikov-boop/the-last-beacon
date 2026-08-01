extends CharacterBody2D

## The Tidesworn — second boss of the descent. A coral-and-iron colossus,
## half-grown into the sea floor. Teaches POSITIONING: when the ground
## glows red, you were standing somewhere you should not be. Phase 2 at
## half health: the ground remembers twice, and the charge comes faster.

signal died
signal hit_taken
signal big_attack

enum State { IDLE, TELEGRAPH_ERUPT, ERUPT, TELEGRAPH_SWEEP, SWEEP, TELEGRAPH_CHARGE, CHARGE, RECOVER, DEAD }

@export var max_hp := 14
@export var walk_speed := 45.0
@export var charge_speed := 380.0
@export var touch_damage := 1
@export var gravity := 1100.0
@export var attack_range := 520.0

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
@onready var erupt_zone: Polygon2D = $EruptZone
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
	sweep_box.position.x = 65.0 * facing.x


func _try_attack(player: Node2D) -> void:
	busy = true
	attack_count += 1
	var fid := fight_id
	match randi() % 3:
		0:
			await _eruption(player, fid)
		1:
			await _sweep(player, fid)
		_:
			await _charge(player, fid)
	if fid != fight_id or dead:
		return
	state = State.RECOVER
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	busy = false
	state = State.IDLE


func _player_in_zone(player: Node2D, zone_x: float) -> bool:
	return absf(player.global_position.x - zone_x) < 55.0 and player.global_position.y > 520.0


func _erupt_at(player: Node2D, zone_x: float, wait: float, fid: int) -> void:
	erupt_zone.position.x = zone_x
	erupt_zone.visible = true
	await get_tree().create_timer(wait).timeout
	if fid != fight_id or dead:
		return
	erupt_zone.visible = false
	state = State.ERUPT
	big_attack.emit()
	if _player_in_zone(player, zone_x):
		player.take_damage(touch_damage, global_position)


func _eruption(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_ERUPT
	body.modulate = Color(1.6, 1.6, 1.6)
	# The ground glows where the keeper stands — move.
	await _erupt_at(player, player.global_position.x, 0.65, fid)
	if fid != fight_id or dead:
		return
	if phase == 2:
		# The sea remembers twice.
		body.modulate = Color(1.6, 1.6, 1.6)
		await _erupt_at(player, player.global_position.x, 0.45, fid)
		if fid != fight_id or dead:
			return
	body.modulate = Color.WHITE
	state = State.RECOVER
	await get_tree().create_timer(0.8 if phase == 1 else 0.6).timeout
	if fid != fight_id or dead:
		return


func _sweep(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_SWEEP
	body.modulate = Color(1.6, 1.6, 1.6)
	sweep_box.monitoring = true
	sweep_box.visible = true
	await get_tree().create_timer(0.55).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	state = State.SWEEP
	big_attack.emit()
	# The coral claws rake once per victim while out.
	var victims: Array[Node] = []
	for i in 10:
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


func _charge(player: Node2D, fid: int) -> void:
	_face(player)
	state = State.TELEGRAPH_CHARGE
	body.modulate = Color(1.6, 1.6, 1.6)
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	state = State.CHARGE
	big_attack.emit()
	var speed: float = charge_speed * (1.0 if phase == 1 else 1.2)
	velocity.x = facing.x * speed
	await get_tree().create_timer(0.75).timeout
	if fid != fight_id or dead:
		return
	velocity.x = 0.0
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
	erupt_zone.visible = false
	died.emit()


## Each lap of the descent makes the boss meaner. Called by the arena's
## _ready with the current lap (1 = first fight, unchanged).
func scale_for_lap(lap: int) -> void:
	if lap <= 1:
		return
	max_hp = 14 + (lap - 1) * 2
	walk_speed = 45.0 * (1.0 + 0.08 * float(lap - 1))
	charge_speed = 380.0 * (1.0 + 0.05 * float(lap - 1))
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
	erupt_zone.visible = false
	sweep_box.monitoring = false
	sweep_box.visible = false
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	touch_box.set_deferred("monitoring", true)
