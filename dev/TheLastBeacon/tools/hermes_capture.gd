extends SceneTree
## hermes-capture: screenshots of the game for visual review.
## Runs NON-headless (needs a real framebuffer). Loads an arena, poses the
## hero at a requested moment, saves a PNG, quits.
##
## Usage: godot --path <proj> --script <this> -- <shot> <out_png>
##   shots: idle | run | attack | jump | roll | wide

var frames := 0
var shot := "idle"
var arena_name := "captain_arena"
var out_path := "C:/Users/hugob/game-project/docs/shots/capture.png"
var arena: Node2D
var player: CharacterBody2D
var boss: Node
var fired := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		shot = args[0]
	if args.size() >= 2:
		out_path = args[1]
	if args.size() >= 3:
		arena_name = args[2]
	var scene: PackedScene = load("res://scenes/%s.tscn" % arena_name)
	arena = scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	print("CAPTURE: shot=", shot, " arena=", arena_name, " -> ", out_path)


func _process(_delta: float) -> bool:
	frames += 1
	# Pose the hero for the requested moment.
	if frames == 20:
		match shot:
			"idle":
				player.global_position = Vector2(420, 603)
				player.velocity = Vector2.ZERO
			"run":
				player.global_position = Vector2(420, 603)
				Input.action_press("move_right")
			"attack":
				player.global_position = Vector2(420, 603)
				player.velocity = Vector2.ZERO
			"jump":
				player.global_position = Vector2(420, 500)
				player.velocity = Vector2(120.0, -260.0)
			"roll":
				player.global_position = Vector2(420, 603)
			"wide":
				player.global_position = Vector2(700, 603)
				player.velocity = Vector2.ZERO
			"steam":
				# Cinematic action frame: mid-arena, sword forward, UI hidden.
				player.global_position = Vector2(650, 603)
				player.velocity = Vector2.ZERO
				_hide_ui()
	# Trigger the action a few frames before the shot so we catch mid-motion.
	if frames == 34:
		match shot:
			"attack":
				player.start_attack()
			"roll":
				player.facing = Vector2.RIGHT
				player.start_roll()
			"steam":
				player.start_attack()
	if frames == 42 and shot == "jump":
		player.velocity = Vector2(120.0, -260.0)
	# Snap late enough for the trail ribbon to have points.
	if frames == 50 and not fired:
		fired = true
		_snap()
	return false


func _hide_ui() -> void:
	# Steam shots are marketing frames: strip the HUD, keep the world.
	for layer in arena.get_children():
		if layer is CanvasLayer or layer.name == "UI":
			layer.visible = false
	# The boss too — these shots are about the world and the hero.
	for node in arena.get_children():
		if node.name == "Boss":
			node.visible = false


func _snap() -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	var dir := out_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(out_path)
	# Also save a hero-centred crop: the camera follows him, so his screen
	# position is derived, never guessed.
	var cam: Camera2D = player.get_node("Camera2D")
	var screen: Vector2 = player.global_position - cam.get_screen_center_position() \
		+ Vector2(root.size) * 0.5
	var w := 150
	var h := 120
	var cx: int = clampi(int(screen.x) - w / 2, 0, img.get_width() - w)
	var cy: int = clampi(int(screen.y) - h / 2 - 10, 0, img.get_height() - h)
	var cut := img.get_region(Rect2i(cx, cy, w, h))
	cut.resize(w * 5, h * 5, Image.INTERPOLATE_NEAREST)
	var crop_path := out_path.get_basename() + "_hero.png"
	cut.save_png(crop_path)
	print("CAPTURE: saved err=", err, " hero at screen ", screen, " crop=", crop_path)
	for action in ["move_left", "move_right", "attack", "roll"]:
		Input.action_release(action)
	quit(0)
