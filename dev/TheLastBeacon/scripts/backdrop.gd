extends Node2D

## A parallax backdrop — far hills, mid columns, near occlusion, a beacon
## glow, and drifting motes. Built entirely from flat colours and silhouette
## polygons. Each arena calls setup_for() then _do_build().

@export var near_colour := Color(0.16, 0.14, 0.12, 1)
@export var mid_colour := Color(0.12, 0.1, 0.09, 1)
@export var far_colour := Color(0.06, 0.05, 0.07, 1)
@export var glow_colour := Color(1, 0.75, 0.4, 0.05)
@export var glow_size := 300.0


func setup_for(boss_name: String) -> void:
	match boss_name:
		"THE BASTION":
			near_colour = Color(0.10, 0.14, 0.16, 1)
			mid_colour  = Color(0.06, 0.08, 0.12, 1)
			far_colour  = Color(0.04, 0.06, 0.10, 1)
			glow_colour = Color(0.7, 0.78, 1, 0.05)
			glow_size   = 340.0
		"THE FALLEN BEACON":
			near_colour = Color(0.15, 0.11, 0.06, 1)
			mid_colour  = Color(0.10, 0.06, 0.04, 1)
			far_colour  = Color(0.05, 0.03, 0.04, 1)
			glow_colour = Color(1, 0.55, 0.25, 0.06)
			glow_size   = 310.0
		_:  # "THE CAPTAIN" + default
			pass  # keep the exported defaults
	_do_build()


func _do_build() -> void:
	var far_layer := _make_layer(0.15)
	var mid_layer := _make_layer(0.40)
	var near_layer := _make_layer(0.65)

	# --- far layer: sky gradient + faint distant mountains ---
	_fill(far_layer, far_colour)
	_hills(far_layer, far_colour.lightened(0.08), 800.0, 180.0, 4, 0.15)

	# --- mid layer: darker silhouette
	_fill(mid_layer, mid_colour)
	_hills(mid_layer, mid_colour.lightened(0.14), 900.0, 230.0, 7, 0.22)
	_columns(mid_layer, mid_colour.darkened(0.15), 920.0)

	# --- near layer: foreground occlusion
	_fill(near_layer, Color(0, 0, 0, 0))
	_hills(near_layer, near_colour, 900.0, 270.0, 5, 0.35)
	_columns(near_layer, near_colour.darkened(0.12), 920.0)
	_banner(near_layer, near_colour.lightened(0.1))

	# --- beacon glow, in world space ---
	var glow := Polygon2D.new()
	glow.color = glow_colour
	glow.z_index = -10
	glow.polygon = _ngon(32, glow_size * 1.2)
	glow.position = Vector2(700, 90)
	add_child(glow)

	# --- drifting mote layer (soft ambient motion) ---
	var motes := _make_layer(0.18)
	motes.name = "Motes"
	_fill(motes, Color(0, 0, 0, 0))
	_spawn_motes(motes, 14, glow_colour)


func _make_layer(scale: float) -> Parallax2D:
	var p := Parallax2D.new()
	p.autoscroll = Vector2.ZERO
	p.scroll_scale = Vector2(scale, 1.0)
	p.scroll_offset = Vector2(0, 0)
	p.repeat_size = Vector2(1920, 720)
	add_child(p)
	return p


func _fill(layer: Parallax2D, colour: Color) -> void:
	var r := ColorRect.new()
	r.color = colour
	r.size = Vector2(1920, 720)
	r.z_index = -100
	layer.add_child(r)


func _hills(layer: Parallax2D, colour: Color, w: float, base_y: float,
		count: int, roughness: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(get_instance_id()) + str(count))
	pts.append(Vector2(-10, base_y + 300))
	var last_y := base_y
	for i in count + 1:
		var x: float = -10 + w * i / float(count)
		last_y = base_y + (rng.randf_range(-roughness * 90, roughness * 90) + (last_y - base_y) * 0.5)
		pts.append(Vector2(x, last_y))
	pts.append(Vector2(w + 10, base_y + 300))
	var shape := Polygon2D.new()
	shape.color = colour
	shape.z_index = -90
	shape.polygon = pts
	layer.add_child(shape)


func _columns(layer: Parallax2D, colour: Color, base_y: float) -> void:
	var x_positions: Array[float] = [60.0, 180.0, 370.0, 680.0, 950.0, 1120.0, 1380.0]
	var widths: Array[float] = [36.0, 28.0, 20.0, 48.0, 24.0, 32.0, 40.0]
	var heights: Array[float] = [460.0, 380.0, 500.0, 470.0, 410.0, 440.0, 390.0]
	for i in x_positions.size():
		var col := Polygon2D.new()
		col.color = colour
		col.z_index = -80
		var hw: float = widths[i] * 0.5
		var top_y: float = base_y - heights[i]
		col.polygon = PackedVector2Array([
			Vector2(-hw, top_y), Vector2(hw, top_y),
			Vector2(hw, base_y), Vector2(-hw, base_y)])
		col.position = Vector2(x_positions[i], base_y)
		layer.add_child(col)


func _banner(layer: Parallax2D, colour: Color) -> void:
	var b := Polygon2D.new()
	b.color = colour
	b.z_index = -75
	b.position = Vector2(80, 270)
	b.polygon = PackedVector2Array([
		Vector2(-2, -60), Vector2(8, -50), Vector2(3, 30),
		Vector2(-8, 20), Vector2(-18, 0)])
	layer.add_child(b)


func _spawn_motes(layer: Parallax2D, count: int, colour: Color) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in count:
		var mote := ColorRect.new()
		mote.color = Color(colour.r, colour.g, colour.b, randf_range(0.08, 0.22))
		mote.size = Vector2(2, 2)
		mote.position = Vector2(randf_range(0, 1920), randf_range(40, 520))
		mote.z_index = -70
		layer.add_child(mote)
		var tw: Tween = create_tween().set_loops()
		tw.tween_property(mote, "position:x", mote.position.x - randf_range(30, 90),
			randf_range(8, 22)).as_relative()
		tw.tween_property(mote, "position:x", 0.0,
			randf_range(8, 22)).as_relative().from_current()


func _ngon(sides: int, radius: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in sides:
		var a: float = TAU * i / float(sides)
		pts.append(Vector2(cos(a) * radius, sin(a) * 0.55 * radius))
	return pts
