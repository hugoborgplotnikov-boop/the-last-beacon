extends Node2D
class_name ChoirSinger

## One voice in the Hollow Choir — immobile, sings projectiles on a rhythm,
## and shares one HP pool with every other singer. The choir is the parent
## node; this singer is a child polygon that takes damage and relays it up.

signal note_fired(note: Area2D, pos: Vector2, vel: Vector2)

@export var singer_index := 0
@export var fire_interval := 1.8
@export var note_speed := 140.0
@export var note_damage := 1
@export var phase := 1

var choir: Node2D
var body: Node2D
var note_timer: float = 0
var flash_timer := 0.0

@onready var note_scene: PackedScene = preload("res://scenes/choir_note.tscn")


func _ready() -> void:
	body = $Body
	choir = get_parent()
	# Stagger the first volley so the choir doesn't fire all at once.
	note_timer = singer_index * 0.55


func _physics_process(delta: float) -> void:
	if choir.get("dead") and choir.dead:
		return
	note_timer -= delta
	var interval := fire_interval if phase == 1 else fire_interval * 0.62
	if note_timer <= 0.0:
		_fire()
		note_timer = interval * randf_range(0.85, 1.15)
	# Hit flash fades.
	if flash_timer > 0.0:
		flash_timer -= delta
		body.modulate = Color(2.0, 1.6, 2.0) if int(flash_timer * 20) % 2 == 0 else Color.WHITE


func _fire() -> void:
	# The note drifts toward where the player WILL be — slow enough to dodge.
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or choir.get("dead") and choir.dead:
		return
	Sfx.play("note", -10.0, randf_range(0.85, 1.15))
	var to_player: Vector2 = player.global_position - global_position
	var aim: Vector2 = to_player.normalized()
	# Phase 2: slight homing — we apply a slow curve in the note itself.
	var note := note_scene.instantiate() as Area2D
	note.global_position = global_position
	note.damage = note_damage
	note.speed = note_speed
	note.direction = aim
	note.phase = phase
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else choir.get_parent()
	host.add_child(note)


func hit_flash() -> void:
	flash_timer = 0.1
	body.modulate = Color(2.0, 1.6, 2.0)
