extends Node
## Builds the app-wide UI theme in code (fonts with Urdu fallback, rounded
## buttons, panels) and offers small factory helpers for consistent widgets.

const GOLD := Color("f2c14e")
const GOLD_DARK := Color("a8771f")
const CREAM := Color("f6f1e3")
const MUTED := Color("b9c7bd")
const INK := Color("1b1d22")
const RED := Color("d23c3c")
const TEAM_US := Color("5cc8ff")
const TEAM_THEM := Color("ff7f6e")
const PANEL_BG := Color(0.03, 0.10, 0.08, 0.90)
const BTN_GREEN := Color("1f8a5b")
const BTN_DARK := Color("1d3a31")

var font_regular: Font
var font_bold: Font
var theme: Theme


func _ready() -> void:
	font_regular = _make_font("res://assets/fonts/Nunito-SemiBold.woff2", "res://assets/fonts/NotoNaskhArabic-Regular.woff2")
	font_bold = _make_font("res://assets/fonts/Nunito-ExtraBold.woff2", "res://assets/fonts/NotoNaskhArabic-Bold.woff2")
	theme = _build_theme()
	# Merge into the engine default theme so every Control picks it up,
	# including those under CanvasLayers / Node2D parents.
	var default_theme := ThemeDB.get_default_theme()
	default_theme.merge_with(theme)
	default_theme.default_font = font_regular
	default_theme.default_font_size = 26
	ThemeDB.fallback_font = font_regular


func _make_font(latin_path: String, urdu_path: String) -> Font:
	var latin: FontFile = load(latin_path)
	var urdu: FontFile = load(urdu_path)
	if latin == null:
		return ThemeDB.fallback_font
	var f: FontFile = latin.duplicate()
	if urdu != null:
		f.fallbacks = [urdu]
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.oversampling = 1.0
	return f


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = 26

	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 2)

	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", 28)
	t.set_stylebox("normal", "Button", button_style(BTN_GREEN))
	t.set_stylebox("hover", "Button", button_style(BTN_GREEN.lightened(0.1)))
	t.set_stylebox("pressed", "Button", button_style(BTN_GREEN.darkened(0.2), true))
	t.set_stylebox("disabled", "Button", button_style(Color(0.25, 0.3, 0.28, 0.7)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", CREAM)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.45))

	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())
	return t


func button_style(color: Color, pressed := false, radius := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(14)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.border_width_bottom = 2 if pressed else 5
	s.border_color = color.darkened(0.45)
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 2 if pressed else 6
	s.shadow_offset = Vector2(0, 2 if pressed else 4)
	s.anti_aliasing = true
	return s


func panel_style(bg := PANEL_BG, border := Color(GOLD, 0.55), radius := 24) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(22)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 6)
	s.anti_aliasing = true
	return s


func make_label(text: String, size := 26, color := CREAM, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## kind: "primary" (gold), "secondary" (green), "dark"
func make_button(text: String, kind := "secondary", font_size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	var col := BTN_GREEN
	match kind:
		"primary": col = GOLD
		"dark": col = BTN_DARK
		"danger": col = RED
	b.add_theme_stylebox_override("normal", button_style(col))
	b.add_theme_stylebox_override("hover", button_style(col.lightened(0.08)))
	b.add_theme_stylebox_override("pressed", button_style(col.darkened(0.15), true))
	if kind == "primary":
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(c, INK)
	b.button_down.connect(func(): Sound.play("click"))
	return b
