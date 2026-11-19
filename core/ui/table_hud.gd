class_name TableHUD
extends CanvasLayer
## Shared on-screen UI for card tables: team score bar, an info box (e.g.
## trump or bid), player tags, banners, hints, a choice picker and
## round / game-over / pause overlays. Games configure it; no game rules here.

signal choice_made(value)
signal next_round_pressed
signal menu_requested

var root: Control
var _score_us: Label
var _score_them: Label
var _target: Label
var _tricks_us: Label
var _tricks_them: Label
var _pile_label: Label
var _info_title: Label
var _trump_icon: SuitIcon
var _trump_q: Label
var _tags: Array[PanelContainer] = []
var _tag_by_seat: Dictionary = {}     # seat -> index into _tags
var _sub_extra: Label
var _tag_styles: Array[StyleBoxFlat] = []
var _dealer_chips: Array[Label] = []
var _banner: Label
var _hint: Label
var _picker: PanelContainer
var _overlay: Control
var _turn_tween: Tween
var _active_tag := -1
var _target_points := 7
var _target_key := ""


func _init() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar()
	_banner = UITheme.make_label("", 50, UITheme.GOLD, true)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.05, 0.95))
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_hint = UITheme.make_label("", 26, UITheme.CREAM, true)
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_hint.modulate.a = 0.0
	root.add_child(_hint)


# --- construction --------------------------------------------------------------

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	var s := UITheme.panel_style(Color(0.02, 0.07, 0.05, 0.88), Color(UITheme.GOLD, 0.35), 0)
	s.corner_radius_bottom_left = 28
	s.corner_radius_bottom_right = 28
	s.border_width_top = 0
	s.border_width_left = 0
	s.border_width_right = 0
	s.content_margin_top = 14
	s.content_margin_bottom = 12
	s.content_margin_left = 16
	s.content_margin_right = 16
	bar.add_theme_stylebox_override("panel", s)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	var menu := UITheme.make_button("MENU", "dark", 22)
	menu.custom_minimum_size = Vector2(110, 70)
	menu.pressed.connect(func(): menu_requested.emit())
	row.add_child(menu)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 0)
	row.add_child(center)
	var scores := HBoxContainer.new()
	scores.alignment = BoxContainer.ALIGNMENT_CENTER
	scores.add_theme_constant_override("separation", 12)
	center.add_child(scores)
	var us := UITheme.make_label("TEAM_US", 22, UITheme.TEAM_US, true)
	scores.add_child(us)
	_score_us = UITheme.make_label("0", 40, UITheme.CREAM, true)
	scores.add_child(_score_us)
	scores.add_child(UITheme.make_label(":", 34, UITheme.MUTED, true))
	_score_them = UITheme.make_label("0", 40, UITheme.CREAM, true)
	scores.add_child(_score_them)
	scores.add_child(UITheme.make_label("TEAM_THEM", 22, UITheme.TEAM_THEM, true))

	var sub := HBoxContainer.new()
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	sub.add_theme_constant_override("separation", 14)
	center.add_child(sub)
	_target = UITheme.make_label("", 18, UITheme.MUTED)
	sub.add_child(_target)
	_tricks_us = UITheme.make_label("", 18, UITheme.TEAM_US, true)
	sub.add_child(_tricks_us)
	_tricks_them = UITheme.make_label("", 18, UITheme.TEAM_THEM, true)
	sub.add_child(_tricks_them)
	_pile_label = UITheme.make_label("", 18, UITheme.GOLD, true)
	sub.add_child(_pile_label)
	_sub_extra = UITheme.make_label("", 18, UITheme.CREAM, true)
	sub.add_child(_sub_extra)

	var trump_box := VBoxContainer.new()
	trump_box.custom_minimum_size = Vector2(110, 0)
	trump_box.add_theme_constant_override("separation", 2)
	row.add_child(trump_box)
	_info_title = UITheme.make_label("TRUMP", 18, UITheme.MUTED, true)
	trump_box.add_child(_info_title)
	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trump_box.add_child(icon_holder)
	_trump_icon = SuitIcon.new(-1, 54)
	icon_holder.add_child(_trump_icon)
	_trump_q = UITheme.make_label("?", 30, UITheme.INK, true)
	_trump_q.set_anchors_preset(Control.PRESET_FULL_RECT)
	_trump_icon.add_child(_trump_q)


## seats: Array of { seat, name, team (0 = us), sub? }
func setup_seats(seats: Array) -> void:
	for s in seats:
		_tag_by_seat[s.seat] = _tags.size()
		_build_tag(s)


func _build_tag(info: Dictionary) -> void:
	var tag := PanelContainer.new()
	var team_col := UITheme.TEAM_US if info.team == 0 else UITheme.TEAM_THEM
	var s := UITheme.panel_style(Color(0.02, 0.07, 0.05, 0.85), Color(team_col, 0.8), 18)
	s.set_content_margin_all(8)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.shadow_size = 6
	tag.add_theme_stylebox_override("panel", s)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.set_meta("team_col", Color(team_col, 0.8))
	_tag_styles.append(s)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tag.add_child(row)
	var dot := ColorRect.new()
	dot.color = team_col
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	row.add_child(v)
	var n := UITheme.make_label(info.name, 22, UITheme.CREAM, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(n)
	if info.get("sub", "") != "":
		var p := UITheme.make_label(info.sub, 15, team_col)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(p)
	var chip := UITheme.make_label("D", 16, UITheme.INK, true)
	var cs := StyleBoxFlat.new()
	cs.bg_color = UITheme.GOLD
	cs.set_corner_radius_all(12)
	cs.content_margin_left = 7
	cs.content_margin_right = 7
	cs.anti_aliasing = true
	chip.add_theme_stylebox_override("normal", cs)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.visible = false
	chip.tooltip_text = "DEALER"
	row.add_child(chip)
	_dealer_chips.append(chip)
	root.add_child(tag)
	_tags.append(tag)


# --- layout ----------------------------------------------------------------------

## Positions seat tags. `anchors` maps seat -> Vector2 screen point, `align`
## seat -> -1 (left edge at point), 0 (centred), 1 (right edge at point).
func layout(vs: Vector2, anchors: Dictionary, align: Dictionary, hint_y: float, banner_y: float) -> void:
	for seat in _tag_by_seat:
		var tag := _tags[_tag_by_seat[seat]]
		tag.reset_size()
		var p: Vector2 = anchors[seat]
		var a: int = align[seat]
		var x := p.x - tag.size.x * (0.5 + 0.5 * a) if a != -1 else p.x
		tag.position = Vector2(x, p.y - tag.size.y * 0.5)
	_hint.size = Vector2(vs.x, 40)
	_hint.position = Vector2(0, hint_y)
	_banner.size = Vector2(vs.x, 80)
	_banner.position = Vector2(0, banner_y)
	_banner.pivot_offset = _banner.size * 0.5


# --- updates ---------------------------------------------------------------------

func set_target(points: int) -> void:
	_target_points = points
	_refresh_target()


func _refresh_target() -> void:
	if _target_key != "":
		_target.text = tr(_target_key)
	else:
		_target.text = tr("TARGET_FMT") % _target_points


## Show a fixed text (translation key) instead of "First to N".
func set_target_text(key: String) -> void:
	_target_key = key
	_refresh_target()


func refresh_language() -> void:
	_refresh_target()


func set_scores(s: Array, animate := false) -> void:
	for i in 2:
		var l := _score_us if i == 0 else _score_them
		var txt := str(s[i])
		if animate and l.text != txt:
			l.pivot_offset = l.size * 0.5
			var t := create_tween()
			t.tween_property(l, "scale", Vector2(1.5, 1.5), 0.12)
			t.tween_callback(func(): l.text = txt)
			t.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		else:
			l.text = txt


## Per-team running stat in the score bar, e.g. tricks or card points.
func set_team_stat(label_key: String, a: int, b: int) -> void:
	_tricks_us.text = "%s %d" % [tr(label_key), a]
	_tricks_them.text = "· %d" % b


func set_tricks(t: Array, pile := -1) -> void:
	_tricks_us.text = "%s %d" % [tr("TRICKS"), t[0]]
	_tricks_them.text = "· %d" % t[1]
	_pile_label.text = (tr("PILE_FMT") % pile) if pile > 0 else ""


func set_info_title(key: String) -> void:
	_info_title.text = key


## Extra text in the score bar's second line (e.g. "Bid 11").
func set_extra(text: String, color := UITheme.CREAM) -> void:
	_sub_extra.text = text
	_sub_extra.add_theme_color_override("font_color", color)


## Info box shows text instead of a suit (e.g. a bid value).
func set_info_text(text: String) -> void:
	_trump_icon.suit = -1
	_trump_q.visible = true
	_trump_q.text = text if text != "" else "?"


func set_trump(suit: int) -> void:
	_trump_q.text = "?"
	_trump_icon.suit = suit
	_trump_q.visible = suit < 0
	if suit >= 0:
		_trump_icon.pivot_offset = _trump_icon.size * 0.5
		_trump_icon.scale = Vector2(0.2, 0.2)
		var t := create_tween()
		t.tween_property(_trump_icon, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func trump_icon_center() -> Vector2:
	return _trump_icon.get_global_rect().get_center()


func set_dealer(seat: int) -> void:
	for st in _tag_by_seat:
		_dealer_chips[_tag_by_seat[st]].visible = st == seat


func set_turn(seat: int) -> void:
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	for i in _tags.size():
		_tag_styles[i].border_color = _tag_styles[i].get_meta("team_col")
		_tag_styles[i].set_border_width_all(2)
		_tags[i].scale = Vector2.ONE
	_active_tag = seat
	if seat < 0 or not _tag_by_seat.has(seat):
		return
	var st := _tag_styles[_tag_by_seat[seat]]
	st.border_color = UITheme.GOLD
	st.set_border_width_all(4)
	var tag := _tags[_tag_by_seat[seat]]
	tag.pivot_offset = tag.size * 0.5
	_turn_tween = create_tween().set_loops()
	_turn_tween.tween_property(tag, "scale", Vector2(1.07, 1.07), 0.45).set_trans(Tween.TRANS_SINE)
	_turn_tween.tween_property(tag, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func tag_center(seat: int) -> Vector2:
	return _tags[_tag_by_seat[seat]].get_global_rect().get_center()


func show_banner(text: String, color := UITheme.GOLD, hold := 1.1, font_size := 50) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.add_theme_font_size_override("font_size", font_size)
	_banner.scale = Vector2(0.4, 0.4)
	_banner.modulate.a = 0.0
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_banner, "modulate:a", 1.0, 0.2)
	t.set_parallel(false)
	t.tween_interval(hold)
	t.tween_property(_banner, "modulate:a", 0.0, 0.3)


func show_hint(text: String) -> void:
	_hint.text = text
	var t := create_tween()
	t.tween_property(_hint, "modulate:a", 1.0 if text != "" else 0.0, 0.2)


# --- choice picker ---------------------------------------------------------------

## Opens a panel of big buttons; emits `choice_made(value)`.
## options: Array of { value, label, suit? (draws a suit icon), sub? }
## where: "center" or "bottom" (above the player's hand).
func open_choices(title: String, options: Array, where := "center", columns := 4) -> void:
	close_choices()
	_picker = PanelContainer.new()
	root.add_child(_picker)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_picker.add_child(v)
	if title != "":
		v.add_child(UITheme.make_label(title, 26, UITheme.GOLD, true))
	var grid := GridContainer.new()
	grid.columns = mini(columns, options.size())
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	var vs := root.get_viewport_rect().size
	var big := options.any(func(o): return o.has("suit"))
	for o in options:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(130, 150) if big else Vector2(minf(300.0, (vs.x - 120) / grid.columns), 78)
		b.add_theme_stylebox_override("normal", UITheme.button_style(Color("f6f1e3"), false, 18))
		b.add_theme_stylebox_override("hover", UITheme.button_style(Color("fffaf0"), false, 18))
		b.add_theme_stylebox_override("pressed", UITheme.button_style(UITheme.GOLD, true, 18))
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_theme_constant_override("separation", 0)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		if o.has("suit"):
			var ic_holder := CenterContainer.new()
			ic_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(ic_holder)
			var ic := SuitIcon.new(o.suit, 70)
			ic.plate = false
			ic_holder.add_child(ic)
		var nl := UITheme.make_label(o.label, 22 if big else 24, UITheme.INK, true)
		nl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		inner.add_child(nl)
		if o.get("sub", "") != "":
			var sl := UITheme.make_label(o.sub, 16, Color(UITheme.INK, 0.7))
			sl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
			inner.add_child(sl)
		var val = o.value
		b.pressed.connect(func():
			Sound.play("click")
			close_choices()
			choice_made.emit(val))
		grid.add_child(b)
	_picker.reset_size()
	var y := vs.y * 0.30 if where == "center" else vs.y - 420 - _picker.size.y
	_picker.position = Vector2((vs.x - _picker.size.x) * 0.5, y)
	_picker.pivot_offset = _picker.size * 0.5
	_picker.scale = Vector2(0.7, 0.7)
	_picker.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(_picker, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_picker, "modulate:a", 1.0, 0.18)


func close_choices() -> void:
	if _picker and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null


# --- overlays --------------------------------------------------------------------

func _make_overlay() -> VBoxContainer:
	close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	_overlay.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_overlay, "modulate:a", 1.0, 0.25)
	panel.pivot_offset = Vector2(280, 150)
	panel.scale = Vector2(0.85, 0.85)
	var t2 := create_tween()
	t2.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return v


func close_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


## lines: extra text lines (already translated) under the title.
func show_round_result(won: bool, title: String, lines: Array, scores: Array) -> void:
	var v := _make_overlay()
	var t := UITheme.make_label(title, 40, UITheme.GOLD if won else UITheme.TEAM_THEM, true)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	for i in lines.size():
		var l := UITheme.make_label(lines[i], 34 if i == 0 and lines[i].ends_with("!") else 23, UITheme.CREAM if i == 0 else UITheme.MUTED, i == 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	v.add_child(_score_row(scores))
	var b := UITheme.make_button("NEXT_ROUND", "primary", 30)
	b.custom_minimum_size.y = 88
	b.pressed.connect(func():
		close_overlay()
		next_round_pressed.emit())
	v.add_child(b)


func show_game_over(winner_team: int, final_scores: Array, on_again: Callable, on_menu: Callable) -> void:
	var v := _make_overlay()
	var won := winner_team == 0
	var title := UITheme.make_label("GAME_WON" if won else "GAME_LOST", 64, UITheme.GOLD if won else UITheme.TEAM_THEM, true)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	v.add_child(title)
	v.add_child(UITheme.make_label(tr("FINAL_SCORE") % [final_scores[0], final_scores[1]], 28, UITheme.CREAM))
	v.add_child(_score_row(final_scores))
	var again := UITheme.make_button("PLAY_AGAIN", "primary", 30)
	again.custom_minimum_size.y = 88
	again.pressed.connect(on_again)
	v.add_child(again)
	var menu := UITheme.make_button("MAIN_MENU", "dark", 28)
	menu.custom_minimum_size.y = 80
	menu.pressed.connect(on_menu)
	v.add_child(menu)


func show_pause(on_resume: Callable, on_restart: Callable, on_menu: Callable) -> void:
	var v := _make_overlay()
	v.add_child(UITheme.make_label("PAUSED", 44, UITheme.GOLD, true))
	var lang := UITheme.make_button("LANG_SWITCH", "dark", 26)
	lang.custom_minimum_size.y = 76
	lang.pressed.connect(func(): I18n.toggle())
	v.add_child(lang)
	for entry in [["RESUME", "primary", on_resume], ["RESTART", "secondary", on_restart], ["MAIN_MENU", "dark", on_menu]]:
		var b := UITheme.make_button(entry[0], entry[1], 28)
		b.custom_minimum_size.y = 84
		b.pressed.connect(entry[2])
		v.add_child(b)


func _score_row(s: Array) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	for i in 2:
		var box := VBoxContainer.new()
		box.add_child(UITheme.make_label("TEAM_US" if i == 0 else "TEAM_THEM", 24, UITheme.TEAM_US if i == 0 else UITheme.TEAM_THEM, true))
		box.add_child(UITheme.make_label(str(s[i]), 56, UITheme.CREAM, true))
		row.add_child(box)
		if i == 0:
			var dash := UITheme.make_label("–", 48, UITheme.MUTED, true)
			dash.size_flags_vertical = Control.SIZE_SHRINK_END
			row.add_child(dash)
	return row
