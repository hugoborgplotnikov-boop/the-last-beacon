extends CharacterBody2D

## The Fallen Beacon — third trial of the gauntlet. The hero who held the
## light before you, fighting with YOUR moveset — greatsword, roll, i-frames
## — one generation rustier. THE DUEL: she parries idle swings (punish her
## recovery, not her guard), she has a stamina bar like yours (whiff her
## into the ground and she gasps, wide open), and in phase 2 her chop chains
## and her counters come faster. Don't get greedy.

signal died
signal hit_taken
signal big_attack

enum State { IDLE, TELEGRAPH_SWING, SWING, ROLL, RECOVER, DEAD }

@export var max_hp := 12
@export var boss_name := "THE FALLEN BEACON"
@export var intro_line := "So. You carry the light now."
@export var death_line := "She nods. The light is yours now."
@export var walk_speed := 60.0
@export var touch_damage := 1
@export var gravity := 1100.0
@export var aggro_range := 420.0
@export var swing_range := 180.0
@export var roll_speed := 260.0
@export var max_stamina := 100.0
@export var swing_stamina_cost := 25.0
@export var stamina_regen := 15.0

var hp: int
var phase := 1
var state := State.IDLE
var busy := false
var dead := false
var facing := Vector2.LEFT
var attack_count := 0
var roll_count := 0
var parries := 0
var stamina := 100.0
var touch_cooldown := 0.0
var spawn_point := Vector2.ZERO
# A brief window after recovery where she holds her guard: IDLE, not busy,
# but not starting a new attack yet — THIS is where idle swings get
# parried. Without it the parry is unreachable with real inputs.
var guard_timer := 0.0
const GUARD_TIME := 0.25
# Cancels stale attack coroutines on death/reset (the fight-id pattern).
var fight_id := 0

@onready var body: Polygon2D = $Body
@onready var eye: Polygon2D = $Body/Eye
@onready var sword: Polygon2D = $Body/Sword
@onready var hurt_box: Area2D = $HurtBox
@onready var touch_box: Area2D = $TouchBox
@onready var swing_box: Area2D = $SwingBox


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
		if guard_timer > 0.0:
			guard_timer -= delta
			velocity.x = 0.0
		elif player and global_position.distance_to(player.global_position) < aggro_range:
			if global_position.distance_to(player.global_position) < swing_range:
				velocity.x = 0.0
				_try_attack(player)
			else:
				var dir: float = signf(player.global_position.x - global_position.x)
				velocity.x = dir * walk_speed
				_face(player)
		else:
			velocity.x = 0.0
	move_and_slide()

	# Stamina regen when she's not mid-swing — hers works like yours.
	if state != State.TELEGRAPH_SWING and state != State.SWING:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)

	# Contact damage ticks while the hero is in reach — hugging must hurt.
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
		swing_box.position.x = 60.0 * facing.x


func _try_attack(player: Node2D) -> void:
	busy = true
	attack_count += 1
	var fid := fight_id
	if phase == 1:
		# Mostly the chop; sometimes she rolls away (don't swing at it).
		if randi() % 4 == 0:
			await _roll(player, fid)
		else:
			await _swing(player, fid)
	else:
		# Phase 2: the chop comes faster and the roll feeds a counter.
		if randi() % 5 == 0:
			await _roll(player, fid)
		else:
			await _swing(player, fid)
			# Phase 2 teeth: the chop can chain into a second, faster chop.
			if fid != fight_id or dead:
				return
			if phase == 2 and stamina >= swing_stamina_cost and randf() < 0.5:
				await _swing(player, fid, true)
	if fid != fight_id or dead:
		return
	# Punish window, then she resets to idle — and holds her guard for a
	# moment: idle but not attacking, so an eager swing gets parried.
	state = State.RECOVER
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	busy = false
	state = State.IDLE
	guard_timer = GUARD_TIME


## The greatsword chop — the mirror of the hero's own swing. The telegraph
## is the blade cocking back; the hitbox is the arc in front of her.
## Costs stamina: whiff her dry and she can't swing at all.
func _swing(player: Node2D, fid: int, fast := false) -> void:
	if stamina < swing_stamina_cost:
		# Gassed: she can't lift the greatsword — she stands wide open.
		state = State.RECOVER
		body.modulate = Color(0.8, 0.75, 0.7)
		await get_tree().create_timer(1.5).timeout
		if fid != fight_id or dead:
			return
		body.modulate = Color.WHITE
		return
	stamina -= swing_stamina_cost
	_face(player)
	state = State.TELEGRAPH_SWING
	sword.rotation = -1.3
	body.modulate = Color(1.6, 1.6, 1.6)
	await get_tree().create_timer(0.32 if (fast or phase == 2) else 0.5).timeout
	if fid != fight_id or dead:
		return
	body.modulate = Color.WHITE
	state = State.SWING
	big_attack.emit()
	Fx.ring(global_position + Vector2(0, 22), Color(1.0, 0.82, 0.45))
	swing_box.monitoring = true
	swing_box.visible = true
	var victims: Array[Node] = []
	for i in 5:
		sword.rotation = lerpf(-1.3, 1.0, (i + 1) / 5.0)
		await get_tree().create_timer(0.05).timeout
		if fid != fight_id or dead:
			return
		for area in swing_box.get_overlapping_areas():
			var victim: Node = area.get_parent()
			if victim.is_in_group("player") and not victims.has(victim):
				victims.append(victim)
				victim.take_damage(touch_damage, global_position)
	swing_box.monitoring = false
	swing_box.visible = false
	sword.rotation = 0.0
	state = State.RECOVER
	await get_tree().create_timer(0.7 if phase == 1 else 0.45).timeout
	if fid != fight_id or dead:
		return


## The mirror dodge: she rolls away with i-frames, exactly like the hero.
## In phase 2 she often follows it with a fast counter-chop.
func _roll(player: Node2D, fid: int) -> void:
	roll_count += 1
	state = State.ROLL
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	var dir: float = -signf(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * roll_speed
	body.modulate = Color(1.4, 1.4, 1.5)
	await get_tree().create_timer(0.35).timeout
	if fid != fight_id or dead:
		return
	velocity.x = 0.0
	body.modulate = Color.WHITE
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	state = State.RECOVER
	if phase == 2 and randf() < 0.6:
		await _swing(player, fid)
		return
	await get_tree().create_timer(0.4).timeout
	if fid != fight_id or dead:
		return


## THE DUEL: she parries swings that land while she's idle — the deflection
## bounces the hero back and feeds a fast counter-chop. Punish her recovery,
## not her guard.
func _do_parry(player: Node2D) -> void:
	var fid := fight_id
	busy = true
	state = State.TELEGRAPH_SWING
	sword.rotation = -1.3
	body.modulate = Color(1.9, 1.9, 2.0)
	await get_tree().create_timer(0.32).timeout
	if fid != fight_id or dead:
		return
	if stamina >= swing_stamina_cost:
		await _swing(player, fid, true)
	else:
		# The deflection was her last effort — she stands wide open.
		body.modulate = Color.WHITE
		state = State.RECOVER
		await get_tree().create_timer(1.5).timeout
		if fid != fight_id or dead:
			return
	busy = false
	state = State.IDLE
	guard_timer = GUARD_TIME


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or hp <= 0:
		return
	# THE MIRROR: an idle parry. The hero must strike during her recovery.
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if state == State.IDLE and not busy and player \
			and global_position.distance_to(player.global_position) < swing_range:
		parries += 1
		_do_parry(player)
		player.take_damage(0, global_position)
		player.velocity.x = 240.0 * signf(player.global_position.x - global_position.x)
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
		# The light in her eye burns brighter as she pushes past her limit.
		eye.color = Color(1.6, 1.1, 0.4)
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
	sword.rotation = 0.0
	body.visible = false
	Fx.burst(global_position, Color(1.0, 0.82, 0.45))
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	touch_box.set_deferred("monitoring", false)
	swing_box.monitoring = false
	swing_box.visible = false
	died.emit()


## Each lap of the gauntlet makes the boss meaner. Called by the arena's
## _ready with the current lap (1 = first fight, unchanged).
func scale_for_lap(lap: int) -> void:
	if lap <= 1:
		return
	max_hp = 12 + (lap - 1) * 2
	walk_speed = 60.0 * (1.0 + 0.08 * float(lap - 1))
	hp = max_hp


func reset_state() -> void:
	fight_id += 1
	dead = false
	busy = false
	state = State.IDLE
	phase = 1
	hp = max_hp
	stamina = max_stamina
	global_position = spawn_point
	velocity = Vector2.ZERO
	body.visible = true
	body.modulate = Color.WHITE
	body.scale.x = facing.x
	eye.color = Color(1.0, 0.72, 0.3)
	sword.rotation = 0.0
	swing_box.monitoring = false
	swing_box.visible = false
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	touch_box.set_deferred("monitoring", true)
