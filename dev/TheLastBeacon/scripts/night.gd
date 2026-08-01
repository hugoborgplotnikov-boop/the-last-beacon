extends Node2D

## THE NIGHT — boss #6. The final trial. Everything you've learned.
## Fast, teleporting, splits into two shadows in phase 2. Small hitbox, big
## damage. When she falls, the gauntlet is won.

signal died
signal hit_taken
signal big_attack

enum State { IDLE, TELEGRAPH, STRIKE, RECOVER, SHADOW }

@export var boss_name := "THE NIGHT"
@export var max_hp := 22

var hp: int
var dead := false
var phase := 1
var state := State.IDLE
var busy := false
var fight_id := 0
var player: CharacterBody2D
var body: Node2D
var attack_timer := 0.9

@onready var hurt_box: Area2D = $HurtBox


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	body = $Body
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func scale_for_lap(lap: int) -> void:
	if lap > 1:
		max_hp += (lap - 1) * 3
		hp = max_hp


func _physics_process(delta: float) -> void:
	if dead:
		return
	# The Night drifts toward the player, always.
	if state == State.IDLE and not busy and is_instance_valid(player):
		var dx := player.global_position.x - global_position.x
		global_position.x += clampf(dx, -60, 60) * delta
		body.scale.x = signf(dx) if dx != 0 else body.scale.x
	attack_timer -= delta
	if attack_timer <= 0.0 and state == State.IDLE and not busy:
		_attack()


func _attack() -> void:
	busy = true
	var fid := fight_id
	# Teleport behind or in front of the player.
	var dir := 1 if randi() % 2 == 0 else -1
	global_position.x = player.global_position.x + dir * randf_range(80, 160)
	global_position.y = player.global_position.y + randf_range(-40, 20)
	state = State.TELEGRAPH
	body.modulate = Color(0.3, 0.2, 0.3)
	await get_tree().create_timer(0.3).timeout
	if fid != fight_id or dead:
		return
	state = State.STRIKE
	body.modulate = Color(1.8, 1.4, 1.8)
	big_attack.emit()
	Fx.ring(global_position + Vector2(0, 20), Color(0.3, 0.1, 0.4), 36.0, 3.0)
	# Check the player is close — if so, hit.
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 72:
		player.take_damage(1, global_position)
	# Phase 2: a shadow copy strikes immediately after.
	if phase == 2 and randi() % 3 == 0:
		var shadow_pt := player.global_position + Vector2(randf_range(-100, 100), randf_range(-30, 30))
		Fx.sparks(shadow_pt, Vector2.DOWN, 8)
		if is_instance_valid(player) and shadow_pt.distance_to(player.global_position) < 48:
			player.take_damage(1, shadow_pt)
	await get_tree().create_timer(0.25).timeout
	if fid != fight_id or dead:
		return
	state = State.RECOVER
	body.modulate = Color.WHITE
	await get_tree().create_timer(0.5).timeout
	if fid != fight_id or dead:
		return
	state = State.IDLE
	busy = false
	attack_timer = 0.9 if phase == 1 else 0.48


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or hp <= 0:
		return
	hp -= dmg
	hit_taken.emit()
	body.modulate = Color(2.0, 1.4, 2.0)
	await get_tree().create_timer(0.08).timeout
	body.modulate = Color.WHITE
	if hp <= max_hp / 2 and phase == 1:
		phase = 2
		big_attack.emit()
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	died.emit()
	Fx.burst(global_position, Color(0.25, 0.1, 0.35, 1))
	body.visible = false
