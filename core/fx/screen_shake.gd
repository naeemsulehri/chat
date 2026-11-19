class_name ScreenShake
extends Camera2D
## Camera with trauma-based screen shake (light and decaying).

var _trauma := 0.0
var _time := 0.0
var max_offset := 14.0
var max_roll := 0.02
var decay := 2.2


func shake(amount := 0.35) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	_time += delta * 40.0
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var amt := _trauma * _trauma
	offset = Vector2(sin(_time * 1.3), cos(_time * 1.7)) * max_offset * amt
	rotation = sin(_time * 0.9) * max_roll * amt
