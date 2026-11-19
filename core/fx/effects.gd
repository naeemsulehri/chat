class_name Effects
extends RefCounted
## One-shot particle effects (CPUParticles2D works on every renderer/mobile).

static var _dot_tex: Texture2D
static var _rect_tex: Texture2D

const CONFETTI_COLORS := [Color("f2c14e"), Color("ff6b6b"), Color("5cc8ff"), Color("7ee081"), Color("c792ea"), Color("ffffff")]


static func _dot() -> Texture2D:
	if _dot_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot_tex = t
	return _dot_tex


static func _rect() -> Texture2D:
	if _rect_tex == null:
		var img := Image.create(10, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_rect_tex = ImageTexture.create_from_image(img)
	return _rect_tex


static func _gradient(colors: Array) -> Gradient:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offs.append(float(i) / maxf(1.0, colors.size() - 1))
		cols.append(colors[i])
	g.offsets = offs
	g.colors = cols
	return g


static func _finish(p: CPUParticles2D) -> void:
	p.emitting = true
	p.finished.connect(p.queue_free)


## Big celebratory confetti burst (round/game wins).
static func confetti(parent: Node, pos: Vector2, amount := 140, spread_width := 700.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 2.6
	p.texture = _rect()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(spread_width * 0.5, 10)
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.initial_velocity_min = 380.0
	p.initial_velocity_max = 900.0
	p.gravity = Vector2(0, 900)
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.6
	p.color_initial_ramp = _gradient(CONFETTI_COLORS)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.8, Color(1, 1, 1, 1))
	p.color_ramp = fade
	p.z_index = 500
	parent.add_child(p)
	_finish(p)


## Small golden sparkle burst (trick wins, trump reveal).
static func sparkle(parent: Node, pos: Vector2, color := Color("f2c14e"), amount := 26) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.8
	p.texture = _dot()
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 160)
	p.damping_min = 120.0
	p.damping_max = 200.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 1.0))
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 400
	parent.add_child(p)
	_finish(p)
