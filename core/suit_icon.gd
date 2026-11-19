class_name SuitIcon
extends Control
## A Control that draws a suit symbol; used in HUD and menus.

@export var suit: int = -1:
	set(v):
		suit = v
		queue_redraw()
@export var tint: Color = Color(0, 0, 0, 0)  # alpha 0 = use natural suit colour
@export var plate := true  # draw a cream disc behind the symbol


func _init(p_suit := -1, p_size := 40.0) -> void:
	suit = p_suit
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var s := minf(size.x, size.y)
	if plate:
		draw_circle(c, s * 0.5, Color("f6f1e3"))
		draw_arc(c, s * 0.5 - 1.0, 0, TAU, 40, Color(0, 0, 0, 0.25), 2.0, true)
	if suit < 0:
		return
	var col := SuitShapes.color_for(suit) if tint.a == 0.0 else tint
	SuitShapes.draw_suit(self, suit, c, s * (0.62 if plate else 0.95), col)
