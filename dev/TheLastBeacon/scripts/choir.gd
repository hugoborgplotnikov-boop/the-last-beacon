extends Node2D

## THE HOLLOW CHOIR — boss #4. The patience lesson.
## Four stationary singers fire slow, weaving notes from their platforms.
## They share one HP pool: hit any singer, the whole choir bleeds.
## Phase 2 fires faster and the notes curve toward you.

signal died
signal hit_taken
signal big_attack

@export var boss_name := "THE HOLLOW CHOIR"
@export var max_hp := 18
@export var phase1_interval := 2.0
@export var phase2_interval := 1.25

var hp: int
var dead := false
var phase := 1
var singers: Array = []


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	for child in get_children():
		if child.has_method("hit_flash"):
			singers.append(child)


func scale_for_lap(lap: int) -> void:
	if lap > 1:
		max_hp += (lap - 1) * 3
		hp = max_hp
		for sn in singers:
			var s: Node = sn
			s.note_speed += (lap - 1) * 12.0
			s.fire_interval = maxf(0.7, s.fire_interval - (lap - 1) * 0.12)


func take_damage(dmg: int, from_pos: Vector2) -> void:
	if dead or hp <= 0:
		return
	hp -= dmg
	hit_taken.emit()
	for sn in singers:
		var s: Node = sn
		s.hit_flash()
	if hp <= max_hp / 2 and phase == 1:
		phase = 2
		big_attack.emit()
		for sn in singers:
			var s: Node = sn
			s.phase = 2
	if hp <= 0:
		die()


func die() -> void:
	dead = true
	died.emit()
	for i in singers.size():
		var s: Node = singers[i]
		Fx.burst(s.global_position, Color(0.75, 0.5, 0.95, 1))
		var tw := create_tween()
		tw.tween_property(s.body, "modulate:a", 0.0, 0.6).set_delay(i * 0.15)
		tw.tween_callback(s.queue_free)
