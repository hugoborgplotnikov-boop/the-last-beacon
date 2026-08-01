extends Node2D

## Fx — the impact layer (autoload). One-shot visual effects any script can
## fire without owning particle nodes: sparks, dust, rings, bursts.
## Everything is procedural CPUParticles2D or tweened polygons, freed on
## completion, and skipped entirely in headless so tests stay deterministic.

var headless := false


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The transition overlay — a full-screen ColorRect for fades.
	_setup_transition()


## Where effects get parented: the current scene, so they inherit its camera.
func _host() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else self


func _emit(p: CPUParticles2D, at: Vector2, lifetime: float) -> void:
	p.global_position = at
	p.emitting = true
	p.one_shot = true
	_host().add_child(p)
	await get_tree().create_timer(lifetime + 0.4).timeout
	if is_instance_valid(p):
		p.queue_free()


## A sword connecting: bright sparks thrown back along the blow.
func sparks(at: Vector2, dir: Vector2, amount := 14) -> void:
	if headless:
		return
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = -dir
	p.spread = 42.0
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 620)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.2
	p.color = Color(1.0, 0.86, 0.5)
	_emit(p, at, p.lifetime)


## Feet hitting stone: a low puff that spreads sideways.
func dust(at: Vector2, amount := 10, tint := Color(0.72, 0.7, 0.66, 0.75)) -> void:
	if headless:
		return
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.55
	p.explosiveness = 0.85
	p.direction = Vector2.UP
	p.spread = 78.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 95.0
	p.gravity = Vector2(0, 90)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.color = tint
	_emit(p, at, p.lifetime)


## An expanding ring — the shockwave of something heavy landing.
func ring(at: Vector2, colour := Color(1.0, 0.85, 0.55), max_r := 46.0, width := 3.0) -> void:
	if headless:
		return
	var line := Line2D.new()
	line.width = width
	line.default_color = colour
	line.global_position = at
	line.z_index = 40
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a) * 0.55))
	line.points = pts
	_host().add_child(line)
	line.scale = Vector2(4, 4)
	var tw := create_tween().set_parallel()
	tw.tween_property(line, "scale", Vector2(max_r, max_r), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(line, "modulate:a", 0.0, 0.32)
	await tw.finished
	if is_instance_valid(line):
		line.queue_free()


## A death: light thrown outward, then a slow settling drift.
func burst(at: Vector2, colour := Color(1.0, 0.8, 0.45)) -> void:
	if headless:
		return
	ring(at, colour, 70.0, 4.0)
	var p := CPUParticles2D.new()
	p.amount = 34
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 280.0
	p.gravity = Vector2(0, 240)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.color = colour
	_emit(p, at, p.lifetime)


## ── TRANSITIONS ──────────────────────────────────

var _transition_overlay: ColorRect
var _transition_tween: Tween


func _setup_transition() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "TransitionLayer"
	canvas.layer = 100
	add_child(canvas)
	_transition_overlay = ColorRect.new()
	_transition_overlay.name = "TransitionOverlay"
	_transition_overlay.size = Vector2(1920, 1080)
	_transition_overlay.color = Color(0, 0, 0, 0)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_transition_overlay)


## Fade to black, switch scenes, fade back in.
func transition_to(scene_path: String, duration := 0.35) -> void:
	if headless:
		get_tree().change_scene_to_file(scene_path)
		return
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_overlay.color = Color(0, 0, 0, 0)
	_transition_tween = create_tween()
	_transition_tween.tween_property(_transition_overlay, "color", Color(0, 0, 0, 1), duration)
	await _transition_tween.finished
	get_tree().change_scene_to_file(scene_path)
	# After the new scene loads, the overlay is still live (Fx is autoload).
	# One frame to let the new scene set up, then fade out.
	await get_tree().process_frame
	await get_tree().process_frame
	_transition_overlay.color = Color(0, 0, 0, 1)
	var ft := create_tween()
	ft.tween_property(_transition_overlay, "color", Color(0, 0, 0, 0), duration)
