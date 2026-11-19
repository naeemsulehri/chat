class_name FeltBackground
extends ColorRect
## Full-screen felt backdrop using the felt shader.

const FELT := preload("res://assets/shaders/felt.gdshader")


func _init(center := Color(0.10, 0.50, 0.32), edge := Color(0.02, 0.15, 0.10)) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = FELT
	m.set_shader_parameter("center_color", center)
	m.set_shader_parameter("edge_color", edge)
	material = m
