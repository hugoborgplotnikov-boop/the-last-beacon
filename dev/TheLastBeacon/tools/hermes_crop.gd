extends SceneTree
## hermes-crop: cut a region out of a PNG and scale it up, so the hero can
## be judged at the size a player actually perceives him.
## Usage: --script this -- <in.png> <out.png> <x> <y> <w> <h> <zoom>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	var x := int(a[2]); var y := int(a[3])
	var w := int(a[4]); var h := int(a[5])
	var zoom := int(a[6])
	var cut := img.get_region(Rect2i(x, y, w, h))
	cut.resize(w * zoom, h * zoom, Image.INTERPOLATE_NEAREST)
	cut.save_png(a[1])
	print("CROP: saved ", a[1], " ", cut.get_width(), "x", cut.get_height())
	quit(0)
