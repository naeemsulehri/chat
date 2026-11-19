class_name SuitShapes
extends RefCounted
## Vector suit symbols (no font glyphs needed). Shapes are generated once in
## a unit box (-0.5..0.5) and scaled when drawn.

static var _cache: Dictionary = {}

const RED_INK := Color("c8282d")
const BLACK_INK := Color("1d1f26")


static func color_for(suit: int) -> Color:
	return RED_INK if suit == CardData.Suit.HEARTS or suit == CardData.Suit.DIAMONDS else BLACK_INK


## Draw a suit symbol centred at `center`, `size` pixels tall.
static func draw_suit(ci: CanvasItem, suit: int, center: Vector2, size: float, color: Color) -> void:
	for part in _parts(suit):
		var pts := PackedVector2Array()
		pts.resize(part.size())
		for i in part.size():
			pts[i] = center + part[i] * size
		ci.draw_colored_polygon(pts, color)
		var outline := pts.duplicate()
		outline.append(pts[0])
		ci.draw_polyline(outline, color, maxf(1.0, size * 0.012), true)


static func _parts(suit: int) -> Array:
	if _cache.has(suit):
		return _cache[suit]
	var parts: Array = []
	match suit:
		CardData.Suit.HEARTS:
			parts.append(_heart(false))
		CardData.Suit.DIAMONDS:
			parts.append(_diamond())
		CardData.Suit.SPADES:
			parts.append(_heart(true, Vector2(0, -0.07), 0.86))
			parts.append(_stem(0.5))
		CardData.Suit.CLUBS:
			parts.append(_circle(Vector2(0, -0.22), 0.205))
			parts.append(_circle(Vector2(-0.215, 0.07), 0.205))
			parts.append(_circle(Vector2(0.215, 0.07), 0.205))
			parts.append(PackedVector2Array([Vector2(-0.08, -0.05), Vector2(0.08, -0.05), Vector2(0.08, 0.12), Vector2(-0.08, 0.12)]))
			parts.append(_stem(0.5))
	_cache[suit] = parts
	return parts


static func _heart(flip: bool, offset := Vector2.ZERO, scale := 1.0) -> PackedVector2Array:
	var raw: Array[Vector2] = []
	var min_v := Vector2(INF, INF)
	var max_v := Vector2(-INF, -INF)
	for i in 64:
		var t := TAU * i / 64.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		var v := Vector2(x, y)
		raw.append(v)
		min_v = min_v.min(v)
		max_v = max_v.max(v)
	var c := (min_v + max_v) * 0.5
	var s := 1.0 / maxf(max_v.x - min_v.x, max_v.y - min_v.y)
	var pts := PackedVector2Array()
	for v in raw:
		var p := (v - c) * s
		if flip:
			p.y = -p.y
		pts.append(p * scale + offset)
	return pts


static func _diamond() -> PackedVector2Array:
	var corners := [Vector2(0, -0.5), Vector2(0.38, 0), Vector2(0, 0.5), Vector2(-0.38, 0)]
	var pts := PackedVector2Array()
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var mid := (a + b) * 0.5 * 0.86  # pull the edge in for a slight curve
		for i in 8:
			var t := i / 8.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	return pts


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _stem(bottom: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-0.04, 0.12), Vector2(0.04, 0.12),
		Vector2(0.09, bottom - 0.05), Vector2(0.17, bottom),
		Vector2(-0.17, bottom), Vector2(-0.09, bottom - 0.05),
	])
