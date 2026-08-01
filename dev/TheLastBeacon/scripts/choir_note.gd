extends Area2D

## A single note from the Hollow Choir — drifts slowly toward the player
## and curves in phase 2. Touching the hero deals damage and destroys it.

@export var damage := 1
@export var speed := 140.0
@export var direction := Vector2.RIGHT
@export var phase := 1

var travelled := 0.0
var max_distance := 900.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if phase == 2:
		# Phase 2 notes pulse — they grow slightly and change colour.
		var tw := create_tween().set_loops()
		tw.tween_property($Sprite, "self_modulate", Color(1.3, 0.9, 1.3), 0.4)
		tw.tween_property($Sprite, "self_modulate", Color(1, 0.6, 1), 0.4)


func _physics_process(delta: float) -> void:
	# Phase 2: gentle homing curve — the note bends toward the player.
	if phase == 2:
		var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player:
			var to_player: Vector2 = player.global_position - global_position
			var target_dir: Vector2 = to_player.normalized()
			direction = direction.lerp(target_dir, delta * 1.3).normalized()
	global_position += direction * speed * delta
	travelled += speed * delta
	if travelled > max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
