extends Control
## Main menu: pick a game, switch language, toggle sound.

var _deco: Node2D
var _floaters: Array = []
var _sound_btn: Button
var _toast: Label
var _tiles: Array[Control] = []
var _time := 0.0


func _ready() -> void:
	add_child(FeltBackground.new(Color("1b4d63"), Color("07141f")))
	_deco = Node2D.new()
	add_child(_deco)
	_spawn_floaters()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	col.add_child(_build_logo())
	var title := UITheme.make_label("APP_TITLE", 72, UITheme.GOLD, true)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.1, 0.9))
	col.add_child(title)
	col.add_child(UITheme.make_label("APP_TAGLINE", 26, UITheme.MUTED))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	col.add_child(spacer)
	col.add_child(UITheme.make_label("MENU_CHOOSE", 24, Color(UITheme.CREAM, 0.8)))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for g in GameRegistry.all():
		var tile := _make_tile(g)
		list.add_child(tile)
		_tiles.append(tile)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(bottom)
	var lang := UITheme.make_button("LANG_SWITCH", "dark", 26)
	lang.custom_minimum_size = Vector2(260, 76)
	lang.pressed.connect(func(): I18n.toggle())
	bottom.add_child(lang)
	_sound_btn = UITheme.make_button("", "dark", 26)
	_sound_btn.custom_minimum_size = Vector2(260, 76)
	_sound_btn.pressed.connect(_toggle_sound)
	bottom.add_child(_sound_btn)
	_update_sound_label()

	_toast = UITheme.make_label("", 26, UITheme.INK, true)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y -= 170
	_toast.modulate.a = 0.0
	var ts := UITheme.panel_style(UITheme.GOLD, UITheme.GOLD_DARK, 30)
	ts.set_content_margin_all(14)
	_toast.add_theme_stylebox_override("normal", ts)
	add_child(_toast)

	_animate_in()


func _process(delta: float) -> void:
	_time += delta
	var vs := get_viewport_rect().size
	for f in _floaters:
		var c: Card = f.card
		c.position += f.vel * delta
		c.rotation += f.spin * delta
		if c.position.y < -120:
			c.position.y = vs.y + 120
			c.position.x = randf_range(0, vs.x)


func _spawn_floaters() -> void:
	var vs := get_viewport_rect().size
	var deck := Deck.new()
	deck.shuffle()
	for i in 9:
		var c := Card.new().setup(deck.draw(), randf() < 0.7)
		c.position = Vector2(randf_range(0, vs.x), randf_range(0, vs.y))
		c.rotation = randf_range(-0.6, 0.6)
		var s := randf_range(0.55, 0.9)
		c.scale = Vector2(s, s)
		c.modulate = Color(1, 1, 1, 0.16 + 0.1 * s)
		_deco.add_child(c)
		_floaters.append({"card": c, "vel": Vector2(randf_range(-8, 8), -randf_range(14, 30) * s), "spin": randf_range(-0.12, 0.12)})


func _build_logo() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 175)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var anchor := Node2D.new()
	holder.add_child(anchor)
	holder.resized.connect(func(): anchor.position = Vector2(holder.size.x * 0.5, 108))
	var picks := [CardData.new(CardData.Suit.SPADES, CardData.ACE), CardData.new(CardData.Suit.HEARTS, CardData.KING), CardData.new(CardData.Suit.DIAMONDS, CardData.QUEEN)]
	for i in 3:
		var c := Card.new().setup(picks[i], true)
		var target_rot := (i - 1) * 0.28
		c.position = Vector2((i - 1) * 62, 12 + absf(i - 1) * 14)
		c.rotation = 0.0
		c.scale = Vector2(0.2, 0.2)
		anchor.add_child(c)
		c.move_to(c.position, target_rot, 1.0, 0.7, 0.15 + i * 0.12, Tween.TRANS_BACK)
		c.shine(0.9, 1.0, 1.0 + i * 0.15)
	return holder


func _make_tile(g: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 108)
	btn.focus_mode = Control.FOCUS_NONE
	var accent: Color = g.accent
	var base := UITheme.panel_style(Color(0.05, 0.12, 0.16, 0.95), Color(accent, 0.75), 22)
	base.border_width_left = 8
	base.shadow_size = 8
	var hover := base.duplicate()
	hover.bg_color = Color(0.08, 0.17, 0.22, 0.92)
	var pressed := base.duplicate()
	pressed.bg_color = Color(0.03, 0.08, 0.1, 0.95)
	btn.add_theme_stylebox_override("normal", base)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 24
	row.offset_right = -20
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	var icon := SuitIcon.new(g.suit, 66)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var name_l := UITheme.make_label(g.name, 32, UITheme.CREAM, true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texts.add_child(name_l)
	var desc_l := UITheme.make_label(g.desc, 21, UITheme.MUTED)
	desc_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(desc_l)

	if g.available:
		var play := UITheme.make_label("›", 56, accent, true)
		row.add_child(play)
	else:
		var badge := UITheme.make_label("COMING_SOON", 18, UITheme.INK, true)
		var bs := UITheme.panel_style(Color(UITheme.CREAM, 0.85), Color(0, 0, 0, 0), 14)
		bs.set_content_margin_all(8)
		bs.shadow_size = 0
		badge.add_theme_stylebox_override("normal", bs)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(badge)
		btn.modulate = Color(1, 1, 1, 0.72)

	btn.pressed.connect(_on_tile_pressed.bind(g, btn))
	return btn


func _on_tile_pressed(g: Dictionary, btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5
	var t := create_tween()
	t.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.06)
	t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	if not g.available:
		Sound.play("nope")
		_show_toast("COMING_SOON")
		return
	Sound.play("shuffle")
	Router.open_setup(g)


func _show_toast(key: String) -> void:
	_toast.text = key
	_toast.reset_size()
	_toast.position.x = (size.x - _toast.size.x) * 0.5
	var t := create_tween()
	t.tween_property(_toast, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.2)
	t.tween_property(_toast, "modulate:a", 0.0, 0.3)


func _toggle_sound() -> void:
	Sound.set_enabled(not Settings.sound_on)
	_update_sound_label()


func _update_sound_label() -> void:
	_sound_btn.text = "SOUND_ON" if Settings.sound_on else "SOUND_OFF"


func _animate_in() -> void:
	await get_tree().process_frame
	for i in _tiles.size():
		var tile := _tiles[i]
		tile.pivot_offset = tile.size * 0.5
		tile.modulate.a = 0.0
		tile.scale = Vector2(0.92, 0.92)
		var target_a := 1.0 if GameRegistry.all()[i].available else 0.72
		var t := create_tween().set_parallel(true)
		t.tween_property(tile, "modulate:a", target_a, 0.35).set_delay(0.25 + i * 0.07)
		t.tween_property(tile, "scale", Vector2.ONE, 0.45).set_delay(0.25 + i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
