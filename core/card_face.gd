class_name CardFace
extends Node2D
## Draws the front or back of a Card. Flip animations scale this node on X.

const FACE_BG := Color("fdfaf2")
const FACE_BORDER := Color("d8cfb8")
const BACK_RED := Color("8c1d2c")
const BACK_LINE := Color("b5394a")
const GOLD := Color("f2c14e")

static var _face_box: StyleBoxFlat
static var _back_box: StyleBoxFlat
static var _back_inner: StyleBoxFlat
static var _court_box_red: StyleBoxFlat
static var _court_box_black: StyleBoxFlat

var card  # Card (untyped to avoid a cyclic class reference)


func _ready() -> void:
	_ensure_styles()


static func _ensure_styles() -> void:
	if _face_box != null:
		return
	_face_box = StyleBoxFlat.new()
	_face_box.bg_color = FACE_BG
	_face_box.set_corner_radius_all(9)
	_face_box.set_border_width_all(1)
	_face_box.border_color = FACE_BORDER
	_face_box.shadow_color = Color(0, 0, 0, 0.32)
	_face_box.shadow_size = 6
	_face_box.shadow_offset = Vector2(0, 3)
	_face_box.anti_aliasing = true

	_back_box = _face_box.duplicate()
	_back_box.bg_color = Color("f4efe2")

	_back_inner = StyleBoxFlat.new()
	_back_inner.bg_color = BACK_RED
	_back_inner.set_corner_radius_all(6)
	_back_inner.anti_aliasing = true

	_court_box_red = StyleBoxFlat.new()
	_court_box_red.bg_color = Color("fbe7e2")
	_court_box_red.set_corner_radius_all(6)
	_court_box_red.set_border_width_all(2)
	_court_box_red.border_color = Color("d9a441")
	_court_box_red.anti_aliasing = true
	_court_box_black = _court_box_red.duplicate()
	_court_box_black.bg_color = Color("e6e9f4")


func _draw() -> void:
	if card == null:
		return
	var w: float = Card.W
	var h: float = Card.H
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	if card.face_up and card.data != null:
		_draw_front(rect)
	else:
		_draw_back(rect)


func _draw_front(rect: Rect2) -> void:
	var d: CardData = card.data
	var ink := SuitShapes.color_for(d.suit)
	draw_style_box(_face_box, rect)
	var font: Font = UITheme.font_bold if UITheme.font_bold else ThemeDB.fallback_font
	var label := d.rank_label()
	var fs := 30 if label.length() == 1 else 25

	# Top-left index, then the same rotated 180° for bottom-right.
	for flip in [false, true]:
		if flip:
			draw_set_transform(Vector2.ZERO, PI, Vector2.ONE)
		var tl := rect.position
		_draw_centered(font, tl + Vector2(16, 30), label, fs, ink)
		SuitShapes.draw_suit(self, d.suit, tl + Vector2(16, 45), 15, ink)
		if flip:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var center := rect.get_center()
	if d.is_face():
		var inner := Rect2(rect.position + Vector2(31, 20), rect.size - Vector2(62, 40))
		draw_style_box(_court_box_red if d.is_red() else _court_box_black, inner)
		_draw_centered(font, Vector2(center.x, center.y + 12), label, 40, ink)
		SuitShapes.draw_suit(self, d.suit, center + Vector2(0, 32), 18, ink)
		# Little crown flourish
		var cy := inner.position.y + 13
		var crown := PackedVector2Array([
			Vector2(center.x - 11, cy + 6), Vector2(center.x - 11, cy - 4), Vector2(center.x - 5, cy + 1),
			Vector2(center.x, cy - 7), Vector2(center.x + 5, cy + 1), Vector2(center.x + 11, cy - 4),
			Vector2(center.x + 11, cy + 6)])
		draw_colored_polygon(crown, Color("d9a441"))
	elif d.rank == CardData.ACE:
		SuitShapes.draw_suit(self, d.suit, center + Vector2(4, 4), 60, ink)
	else:
		SuitShapes.draw_suit(self, d.suit, center + Vector2(4, 6), 46, ink)


## Draw text horizontally centred on baseline point `at`.
func _draw_centered(font: Font, at: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(at.x - w * 0.5, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_back(rect: Rect2) -> void:
	draw_style_box(_back_box, rect)
	var inner := rect.grow(-6)
	draw_style_box(_back_inner, inner)
	# Diagonal lattice clipped to the inner rectangle.
	var r := inner.grow(-3)
	var step := 11.0
	var span := r.size.x + r.size.y
	var k := 0.0
	while k <= span:
		_clipped_diag(r, k, 1, BACK_LINE)
		_clipped_diag(r, k, -1, BACK_LINE)
		k += step
	# Centre emblem
	var c := rect.get_center()
	draw_circle(c, 22, BACK_RED)
	draw_arc(c, 22, 0, TAU, 48, GOLD, 2.5, true)
	draw_arc(c, 17, 0, TAU, 48, Color(GOLD, 0.5), 1.0, true)
	SuitShapes.draw_suit(self, CardData.Suit.SPADES, c, 22, GOLD)
	draw_rect(inner.grow(-1), Color(GOLD, 0.65), false, 1.5)


## Draws one diagonal line of the lattice, clipped to rect r.
## dir=1: lines going down-right; dir=-1: lines going up-right.
func _clipped_diag(r: Rect2, k: float, dir: int, col: Color) -> void:
	var a: Vector2
	var b: Vector2
	if dir == 1:
		# x - x0 + (y - y0) = k
		a = r.position + Vector2(minf(k, r.size.x), maxf(0.0, k - r.size.x))
		b = r.position + Vector2(maxf(0.0, k - r.size.y), minf(k, r.size.y))
	else:
		# x - x0 + (y_bottom - y) = k
		var bl := r.position + Vector2(0, r.size.y)
		a = bl + Vector2(minf(k, r.size.x), -maxf(0.0, k - r.size.x))
		b = bl + Vector2(maxf(0.0, k - r.size.y), -minf(k, r.size.y))
	draw_line(a, b, col, 1.2, true)
