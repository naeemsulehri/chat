class_name Card
extends Node2D
## Visual card: movement, flip, glow, shine and dimming.
## Root transform = movement; child `face` = flip (scale.x) + drawing.

signal flip_finished

const W := 100.0
const H := 140.0
const FACE_SHADER := preload("res://assets/shaders/card_face.gdshader")
const GLOW_SHADER := preload("res://assets/shaders/card_glow.gdshader")
const GLOW_SPREAD := 24.0

var data: CardData
var face_up := false:
	set(v):
		face_up = v
		if face:
			face.queue_redraw()
var selectable := false

var face: CardFace
var glow: Node2D
var _face_mat: ShaderMaterial
var _glow_mat: ShaderMaterial
var _move_tween: Tween
var _flip_tween: Tween
var _glow_tween: Tween
var _shine_tween: Tween
var _dim_tween: Tween


func _init() -> void:
	glow = Node2D.new()
	glow.name = "Glow"
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = GLOW_SHADER
	_glow_mat.set_shader_parameter("spread", GLOW_SPREAD)
	_glow_mat.set_shader_parameter("intensity", 0.0)
	glow.material = _glow_mat
	glow.visible = false
	glow.draw.connect(_draw_glow)
	add_child(glow)

	face = CardFace.new()
	face.name = "Face"
	face.card = self
	_face_mat = ShaderMaterial.new()
	_face_mat.shader = FACE_SHADER
	face.material = _face_mat
	add_child(face)


func setup(d: CardData, up := false) -> Card:
	data = d
	face_up = up
	name = "Card_%s" % str(d)
	return self


func _draw_glow() -> void:
	var m := GLOW_SPREAD
	glow.draw_rect(Rect2(-W * 0.5 - m, -H * 0.5 - m, W + m * 2, H + m * 2), Color.WHITE)


# --- motion ------------------------------------------------------------------

func move_to(pos: Vector2, rot := 0.0, scl := 1.0, dur := 0.35, delay := 0.0,
		trans := Tween.TRANS_CUBIC, easing := Tween.EASE_OUT) -> Tween:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween().set_parallel(true).set_trans(trans).set_ease(easing)
	_move_tween.tween_property(self, "position", pos, dur).set_delay(delay)
	_move_tween.tween_property(self, "rotation", rot, dur).set_delay(delay)
	_move_tween.tween_property(self, "scale", Vector2(scl, scl), dur).set_delay(delay)
	return _move_tween


## Flip with a squash on X and a small lift. Awaitable via `flip_finished`.
func flip_to(up: bool, dur := 0.26, delay := 0.0) -> void:
	if up == face_up:
		flip_finished.emit.call_deferred()
		return
	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()
	_flip_tween = create_tween()
	if delay > 0.0:
		_flip_tween.tween_interval(delay)
	_flip_tween.tween_callback(func(): Sound.play("flip", 0.1, -6.0))
	_flip_tween.tween_property(face, "scale", Vector2(0.0, 1.06), dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_flip_tween.parallel().tween_property(glow, "scale", Vector2(0.0, 1.06), dur * 0.5)
	_flip_tween.tween_callback(func(): face_up = up)
	_flip_tween.tween_property(face, "scale", Vector2.ONE, dur * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flip_tween.parallel().tween_property(glow, "scale", Vector2.ONE, dur * 0.5)
	_flip_tween.tween_callback(func(): flip_finished.emit())


# --- effects -----------------------------------------------------------------

func set_glow(on: bool, color := Color("f2c14e"), intensity := 1.0) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_mat.set_shader_parameter("glow_color", color)
	_glow_tween = create_tween()
	if on:
		glow.visible = true
		_glow_tween.tween_method(_set_glow_intensity, _get_glow_intensity(), intensity, 0.2)
	else:
		_glow_tween.tween_method(_set_glow_intensity, _get_glow_intensity(), 0.0, 0.2)
		_glow_tween.tween_callback(func(): glow.visible = false)


func _set_glow_intensity(v: float) -> void:
	_glow_mat.set_shader_parameter("intensity", v)


func _get_glow_intensity() -> float:
	return float(_glow_mat.get_shader_parameter("intensity"))


func set_dim(on: bool) -> void:
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween()
	var from := float(_face_mat.get_shader_parameter("dim"))
	_dim_tween.tween_method(func(v): _face_mat.set_shader_parameter("dim", v), from, 1.0 if on else 0.0, 0.18)


## A bright diagonal sweep across the card face.
func shine(dur := 0.7, strength := 1.0, delay := 0.0) -> void:
	if _shine_tween and _shine_tween.is_valid():
		_shine_tween.kill()
	_face_mat.set_shader_parameter("shine_strength", strength)
	_shine_tween = create_tween()
	_shine_tween.tween_method(func(v): _face_mat.set_shader_parameter("shine_pos", v), -0.4, 1.6, dur).set_delay(delay).set_trans(Tween.TRANS_SINE)
	_shine_tween.tween_callback(func(): _face_mat.set_shader_parameter("shine_strength", 0.0))


## Short wiggle used when an illegal card is tapped.
func wiggle() -> void:
	var t := create_tween()
	var r := rotation
	t.tween_property(self, "rotation", r + 0.09, 0.05)
	t.tween_property(self, "rotation", r - 0.09, 0.08)
	t.tween_property(self, "rotation", r, 0.05)


func hit_test(global_point: Vector2) -> bool:
	var p := to_local(global_point)
	return Rect2(-W * 0.5, -H * 0.5, W, H).has_point(p)
