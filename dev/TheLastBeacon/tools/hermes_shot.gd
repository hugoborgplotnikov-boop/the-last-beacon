extends SceneTree
## hermes-shot: load a boss scene alone, snap a close-up, quit.
## Usage: --script this -- <boss_scene> <out_png>

var fired := false
var frames := 0
var boss: Node
var out := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[1]
	var scene: PackedScene = load("res://scenes/%s.tscn" % a[0])
	boss = scene.instantiate()
	boss.set_physics_process(false)
	root.add_child(boss)
	# Dark stage behind him so the silhouette reads.
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 1)
	bg.size = Vector2(1280, 720)
	bg.position = Vector2(0, 0)
	root.add_child(bg)
	root.move_child(bg, 0)
	boss.position = Vector2(640, 400)


func _physics_process(_delta: float) -> bool:
	frames += 1
	if frames == 10 and not fired:
		fired = true
		call_deferred("_snap")
	return false


func _snap() -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	# A zoomed crop centered on the boss for silhouette review.
	var w := 200
	var h := 200
	var cx: int = clampi(int(boss.global_position.x) - w / 2, 0, img.get_width() - w)
	var cy: int = clampi(int(boss.global_position.y) - h / 2, 0, img.get_height() - h)
	var cut := img.get_region(Rect2i(cx, cy, w, h))
	cut.resize(w * 3, h * 3, Image.INTERPOLATE_NEAREST)
	cut.save_png(out.get_basename() + "_zoom.png")
	print("SHOT: saved ", out)
	quit(0)
