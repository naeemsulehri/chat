extends Control
## Generic rules/options screen. Reads the selected game's GameRules
## options and lets the player choose before starting.

var game: Dictionary
var rules_script: Script
var values: Dictionary = {}
var _rows: Dictionary = {}       # option id -> row Control
var _desc_labels: Dictionary = {} # option id -> Label
var _options: Array = []


func _ready() -> void:
	game = Router.selected_game
	if game.is_empty():
		game = GameRegistry.get_game("rang")
		Router.selected_game = game
	rules_script = load(game.rules)
	_options = rules_script.get_options()
	_options.append({
		"id": "difficulty", "label": "OPT_DIFFICULTY", "default": "medium",
		"choices": [{"value": "easy", "label": "DIFF_EASY"}, {"value": "medium", "label": "DIFF_MEDIUM"}, {"value": "hard", "label": "DIFF_HARD"}],
	})
	var saved: Dictionary = Settings.game_options.get(game.id, {})
	for o in _options:
		values[o.id] = saved.get(o.id, o.default)
	if not saved.has("difficulty"):
		values.difficulty = Settings.difficulty

	add_child(FeltBackground.new())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	col.add_child(header)
	header.add_child(SuitIcon.new(game.suit, 70))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var t := UITheme.make_label(game.name, 40, UITheme.GOLD, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titles.add_child(t)
	var st := UITheme.make_label("SETUP_TITLE", 24, UITheme.MUTED)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titles.add_child(st)

	if game.has("summary"):
		var sum := UITheme.make_label(game.summary, 21, Color(UITheme.CREAM, 0.85))
		sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(sum)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for o in _options:
		var row := _build_option(o)
		list.add_child(row)
		_rows[o.id] = row
	_refresh_visibility()

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	col.add_child(buttons)
	var back := UITheme.make_button("BACK", "dark")
	back.custom_minimum_size = Vector2(200, 88)
	back.pressed.connect(func(): Router.goto_menu())
	buttons.add_child(back)
	var start := UITheme.make_button("START", "primary", 32)
	start.custom_minimum_size = Vector2(0, 88)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start)
	buttons.add_child(start)


func _build_option(o: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var ps := UITheme.panel_style(Color(0.02, 0.09, 0.07, 0.82), Color(UITheme.GOLD, 0.3), 20)
	ps.set_content_margin_all(18)
	ps.shadow_size = 6
	panel.add_theme_stylebox_override("panel", ps)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var l := UITheme.make_label(o.label, 25, UITheme.CREAM, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(l)

	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 8)
	v.add_child(seg)
	var group := ButtonGroup.new()
	for ch in o.choices:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = ch.label
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 66
		b.add_theme_font_size_override("font_size", 23)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		b.add_theme_stylebox_override("normal", UITheme.button_style(Color("21453a"), false, 14))
		b.add_theme_stylebox_override("hover", UITheme.button_style(Color("28564a"), false, 14))
		b.add_theme_stylebox_override("pressed", UITheme.button_style(UITheme.GOLD, true, 14))
		b.add_theme_stylebox_override("hover_pressed", UITheme.button_style(UITheme.GOLD, true, 14))
		b.add_theme_color_override("font_pressed_color", UITheme.INK)
		b.add_theme_color_override("font_hover_pressed_color", UITheme.INK)
		b.button_pressed = values[o.id] == ch.value
		b.toggled.connect(func(on: bool):
			if on:
				Sound.play("click")
				values[o.id] = ch.value
				_update_desc(o)
				_refresh_visibility())
		seg.add_child(b)

	var desc := UITheme.make_label("", 20, UITheme.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(desc)
	_desc_labels[o.id] = desc
	_update_desc(o)
	return panel


func _update_desc(o: Dictionary) -> void:
	var desc: Label = _desc_labels.get(o.id)
	if desc == null:
		return
	desc.text = ""
	for ch in o.choices:
		if ch.value == values[o.id] and ch.has("desc"):
			desc.text = ch.desc
	desc.visible = desc.text != ""


func _refresh_visibility() -> void:
	for o in _options:
		if not o.has("show_if") or not _rows.has(o.id):
			continue
		var show := true
		for key in o.show_if:
			if not values.get(key) in o.show_if[key]:
				show = false
		_rows[o.id].visible = show


func _start() -> void:
	Settings.game_options[game.id] = values.duplicate()
	Settings.difficulty = values.difficulty
	Settings.save_settings()
	Sound.play("shuffle")
	Router.start_game(values.duplicate())
