extends Node2D
## Rang table: drives RangRules, animates cards and talks to the HUD.
## Seat 0 is the human (bottom); seats 1..3 are bots (right, top, left).

signal _human_card(card: CardData)
signal _trump_chosen(suit: int)
signal _continue

const HUMAN := 0

var rules: RangRules
var bots: Array = [null, null, null, null]
var hands: Array[Hand] = []
var hud: RangHUD
var camera: ScreenShake
var card_layer: Node2D
var fx_layer: Node2D
var top_fx: CanvasLayer
var _bg: FeltBackground
var _nodes: Dictionary = {}          # card id -> Card
var _trick_cards: Array[Card] = []
var _pile_cards: Array[Card] = []
var _awaiting_human := false
var _vs := Vector2(720, 1280)
var _center := Vector2.ZERO
var _autoplay := false
var _speed := 1.0


func _ready() -> void:
	var cfg := Router.game_config.duplicate()
	if cfg.is_empty():
		cfg = Settings.game_options.get("rang", {}).duplicate()
	_autoplay = cfg.get("autoplay", false) or "--autoplay" in OS.get_cmdline_user_args()
	if _autoplay:
		_speed = 4.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--speed="):
			_speed = float(a.substr(8))
	rules = RangRules.new()
	rules.setup(cfg)
	var diff := BotPlayer.difficulty_from_string(str(cfg.get("difficulty", Settings.difficulty)))
	for s in range(1, 4):
		bots[s] = RangBot.new(s, diff)
	if _autoplay:
		bots[HUMAN] = RangBot.new(HUMAN, BotPlayer.Difficulty.HARD)

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	_bg = FeltBackground.new()
	bg_layer.add_child(_bg)

	camera = ScreenShake.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	card_layer = Node2D.new()
	add_child(card_layer)
	fx_layer = Node2D.new()
	fx_layer.z_index = 300
	add_child(fx_layer)

	for seat in 4:
		var h := Hand.new()
		h.z_base = 60 + seat * 15
		card_layer.add_child(h)
		hands.append(h)

	hud = RangHUD.new()
	add_child(hud)
	top_fx = CanvasLayer.new()
	top_fx.layer = 20
	add_child(top_fx)
	hud.trump_picked.connect(func(s): _trump_chosen.emit(s))
	hud.next_round_pressed.connect(func(): _continue.emit())
	hud.menu_requested.connect(_open_pause)
	hud.set_target(int(rules.config.target))
	hud.set_scores(rules.scores)
	hud.set_tricks([0, 0])
	hud.set_trump(-1)
	I18n.language_changed.connect(_on_language_changed)

	get_viewport().size_changed.connect(_layout)
	_layout()
	_run_match.call_deferred()


func _on_language_changed(_code: String) -> void:
	hud.refresh_language()
	hud.set_tricks(rules.team_tricks, rules.pile if rules.is_sar() else -1)


# --- layout ----------------------------------------------------------------------

func _layout() -> void:
	_vs = get_viewport_rect().size
	var w := _vs.x
	var h := _vs.y
	_center = Vector2(w * 0.5, h * 0.45)

	var human := hands[0]
	human.layout = Hand.Layout.FAN
	human.position = Vector2(w * 0.5, h - 150)
	human.card_scale = 1.08
	human.max_span = w - 90
	human.max_spacing = 56

	var right := hands[1]
	right.layout = Hand.Layout.COLUMN
	right.position = Vector2(w - 46, h * 0.43)
	right.card_scale = 0.5
	right.base_rotation = -PI * 0.5
	right.max_span = h * 0.30
	right.max_spacing = 22

	var top := hands[2]
	top.layout = Hand.Layout.ROW
	top.position = Vector2(w * 0.5, 262)
	top.card_scale = 0.5
	top.base_rotation = PI
	top.max_span = w * 0.5
	top.max_spacing = 22

	var left := hands[3]
	left.layout = Hand.Layout.COLUMN
	left.position = Vector2(46, h * 0.43)
	left.card_scale = 0.5
	left.base_rotation = PI * 0.5
	left.max_span = h * 0.30
	left.max_spacing = 22

	for hd in hands:
		hd.relayout(0.2)
	var col_half := h * 0.15
	hud.layout(_vs,
		{0: Vector2(w * 0.5, h - 300), 1: Vector2(w - 12, h * 0.43 + col_half + 52), 2: Vector2(w * 0.5, 180), 3: Vector2(12, h * 0.43 + col_half + 52)},
		{0: 0, 1: 1, 2: 0, 3: -1},
		h - 400, _center.y - 300)


func _trick_slot(seat: int) -> Vector2:
	var off: Vector2 = [Vector2(0, 84), Vector2(92, 0), Vector2(0, -84), Vector2(-92, 0)][seat]
	return _center + off


func _seat_edge(seat: int) -> Vector2:
	match seat:
		0: return Vector2(_vs.x * 0.5, _vs.y + 120)
		1: return Vector2(_vs.x + 120, _vs.y * 0.43)
		2: return Vector2(_vs.x * 0.5, 150)
	return Vector2(-120, _vs.y * 0.43)


func _pile_pos() -> Vector2:
	return _center + Vector2(-205, -170)


# --- helpers ---------------------------------------------------------------------

func _wait(t: float) -> void:
	await get_tree().create_timer(t / _speed, false).timeout


func _name(seat: int) -> String:
	return tr("NAME_%d" % seat)


func _clear_table() -> void:
	for id in _nodes:
		var c: Card = _nodes[id]
		if is_instance_valid(c):
			c.queue_free()
	_nodes.clear()
	_trick_cards.clear()
	_pile_cards.clear()
	for hd in hands:
		hd.clear()


func _spawn_deck() -> Array[Card]:
	var arr: Array[Card] = []
	for i in 52:
		var c := Card.new().setup(CardData.new(0, 2), false)
		c.position = _center + Vector2(-i * 0.25, -i * 0.35)
		c.scale = Vector2(0.75, 0.75)
		c.z_index = i
		card_layer.add_child(c)
		arr.append(c)
	return arr


# --- match flow ------------------------------------------------------------------

func _run_match() -> void:
	while is_inside_tree():
		await _play_round()
		if not is_inside_tree():
			return
		var summary := rules.score_round()
		hud.set_scores(summary.scores, true)
		var won: bool = summary.winner_team == 0
		if won:
			Sound.play("win")
			Effects.confetti(top_fx, Vector2(_vs.x * 0.5, _vs.y + 40), 120)
		else:
			Sound.play("lose")
		if summary.court or summary.bavan:
			camera.shake(0.7)
		await _wait(0.9)
		if rules.is_game_over():
			_show_game_over()
			return
		hud.show_round_result(summary)
		if _autoplay:
			await _wait(1.0)
			hud.close_overlay()
		else:
			await _continue


func _play_round() -> void:
	_clear_table()
	var first := rules.start_round()
	hud.set_trump(-1)
	hud.set_tricks([0, 0], 0 if rules.is_sar() else -1)
	hud.set_dealer(rules.dealer)
	hud.set_turn(-1)

	var deck := _spawn_deck()
	Sound.play("shuffle")
	await _shuffle_anim(deck)
	await _deal(first, deck)

	# Trump selection
	var caller := rules.caller
	hud.set_turn(caller)
	var suit: int
	if caller == HUMAN and not _autoplay:
		hud.show_hint("MSG_CHOOSE_TRUMP")
		for c in hands[HUMAN].cards:
			c.shine(0.8, 0.8, randf() * 0.3)
		hud.open_trump_picker()
		suit = await _trump_chosen
		hud.show_hint("")
	else:
		hud.show_hint(tr("MSG_CHOOSING") % _name(caller))
		await _wait(1.1)
		suit = (bots[caller] as RangBot).choose_trump(rules)
		hud.show_hint("")
	var rest := rules.choose_trump(caller, suit)
	Sound.play("trump")
	hud.set_trump(suit)
	hud.show_banner(tr("MSG_TRUMP_IS") % tr(CardData.suit_key(suit)), UITheme.GOLD)
	Effects.sparkle(fx_layer, hud.trump_icon_center(), UITheme.GOLD, 34)
	camera.shake(0.25)
	await _wait(0.5)
	await _deal(rest, deck)
	for c in deck:
		if is_instance_valid(c):
			c.queue_free()
	hands[HUMAN].sort_cards(rules.trump)
	hands[HUMAN].relayout(0.35)
	await _wait(0.4)

	# Tricks
	while rules.phase == GameRules.Phase.PLAY and is_inside_tree():
		var seat := rules.current
		hud.set_turn(seat)
		var card: CardData
		if seat == HUMAN and not _autoplay:
			card = await _human_turn()
		else:
			await _wait((bots[seat] as BotPlayer).think_time())
			card = (bots[seat] as RangBot).choose_card(rules)
		var ev := rules.play_card(seat, card)
		await _animate_play(seat, card)
		if ev.trick_complete:
			await _resolve_trick(ev)
	hud.set_turn(-1)


func _shuffle_anim(deck: Array[Card]) -> void:
	# Split, riffle, square up.
	for i in deck.size():
		var c := deck[i]
		var side := -1.0 if i % 2 == 0 else 1.0
		c.move_to(_center + Vector2(side * 70, -i * 0.3), side * 0.12, 0.75, 0.18, 0.0)
	await _wait(0.22)
	for i in deck.size():
		var c := deck[i]
		c.move_to(_center + Vector2(-i * 0.25, -i * 0.35), 0.0, 0.75, 0.22, i * 0.004)
	await _wait(0.45)


func _deal(seq: Array, deck: Array[Card]) -> void:
	var delay := 0.0
	var step := 0.06 / _speed
	for entry in seq:
		var seat: int = entry[0]
		var data: CardData = entry[1]
		var c: Card = deck.pop_back()
		c.data = data
		c.name = "Card_%s" % str(data)
		_nodes[data.id()] = c
		var hand := hands[seat]
		hand.add_card(c)
		c.z_index = hand.z_base + hand.cards.size()
		var s := hand.slot(hand.cards.size() - 1, hand.cards.size())
		get_tree().create_timer(delay, false).timeout.connect(func(): Sound.play("deal", 0.12, -4.0))
		c.move_to(s.pos, s.rot, hand.card_scale, 0.32 / _speed, delay, Tween.TRANS_QUART)
		if seat == HUMAN:
			c.flip_to(true, 0.24, delay + 0.2 / _speed)
		delay += step
	await _wait(delay * _speed + 0.4)
	for hd in hands:
		hd.relayout(0.25)
	if rules.trump < 0:
		hands[HUMAN].sort_cards()
	hands[HUMAN].relayout(0.3)
	await _wait(0.3)


# --- human input -----------------------------------------------------------------

func _human_turn() -> CardData:
	var valid := rules.get_valid_moves(HUMAN)
	var valid_ids := {}
	for v in valid:
		valid_ids[v.id()] = true
	for c in hands[HUMAN].cards:
		var ok := valid_ids.has(c.data.id())
		c.selectable = ok
		c.set_dim(not ok)
		c.set_glow(ok and valid.size() < hands[HUMAN].cards.size(), Color("ffe07a"), 0.75)
	hud.show_hint("MSG_YOUR_TURN")
	_awaiting_human = true
	var card: CardData = await _human_card
	_awaiting_human = false
	hud.show_hint("")
	for c in hands[HUMAN].cards:
		c.selectable = false
		c.set_dim(false)
		c.set_glow(false)
	return card


func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_human:
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if not pressed:
		return
	var p := card_layer.get_global_mouse_position()
	var hand := hands[HUMAN]
	var hit: Card = null
	for i in range(hand.cards.size() - 1, -1, -1):
		if hand.cards[i].hit_test(p):
			hit = hand.cards[i]
			break
	if hit == null:
		if hand.selected != null:
			hand.select(null)
		return
	get_viewport().set_input_as_handled()
	if not hit.selectable:
		Sound.play("nope")
		hit.wiggle()
		hud.show_hint("MSG_MUST_FOLLOW")
		return
	if hand.selected == hit:
		hand.selected = null
		_human_card.emit(hit.data)
	else:
		Sound.play("click", 0.05, -6.0)
		hand.select(hit)
		hit.shine(0.5, 0.7)
		hud.show_hint("MSG_TAP_AGAIN")


# --- trick animation -------------------------------------------------------------

func _animate_play(seat: int, data: CardData) -> void:
	var c: Card = _nodes[data.id()]
	hands[seat].remove_card(c)
	_trick_cards.append(c)
	c.z_index = 120 + _trick_cards.size()
	var target := _trick_slot(seat) + Vector2(randf_range(-5, 5), randf_range(-5, 5))
	var rot := randf_range(-0.14, 0.14)
	if not c.face_up:
		c.flip_to(true, 0.22)
	c.move_to(target, rot, 0.92, 0.28 / _speed, 0.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	Sound.play("deal", 0.1, -3.0)
	hands[seat].relayout(0.25)
	await _wait(0.3)
	Sound.play("place")
	if data.suit == rules.trump and rules.trick.size() != 0 and rules.led_suit() != rules.trump:
		c.shine(0.5, 1.0)


func _resolve_trick(ev: Dictionary) -> void:
	await _wait(0.35)
	var winner: int = ev.winner
	var wcard: Card = _nodes[ev.winning_card.id()]
	wcard.set_glow(true, UITheme.GOLD, 1.0)
	wcard.shine(0.6, 1.0)
	wcard.z_index = 160
	var pulse := wcard.create_tween()
	pulse.tween_property(wcard, "scale", Vector2(1.05, 1.05), 0.14)
	pulse.tween_property(wcard, "scale", Vector2(0.92, 0.92), 0.18)
	Sound.play("trick")
	Effects.sparkle(fx_layer, wcard.position, UITheme.GOLD, 18)
	if ev.trumped:
		camera.shake(0.22)
	hud.show_hint(tr("MSG_WINS_TRICK") % _name(winner))
	await _wait(0.75)
	wcard.set_glow(false)

	if rules.is_sar():
		# Trick goes face-down to the pile in the middle.
		var base := _pile_pos()
		for c in _trick_cards:
			_pile_cards.append(c)
			var i := _pile_cards.size()
			c.z_index = 100 + i
			c.flip_to(false, 0.2)
			c.move_to(base + Vector2(i * 0.6, -i * 0.6), randf_range(-0.05, 0.05), 0.45, 0.3 / _speed)
		_trick_cards.clear()
		await _wait(0.3)
		if ev.collected > 0:
			await _sweep(_pile_cards, winner)
			_pile_cards.clear()
			Sound.play("collect")
			if ev.collected > 1:
				hud.show_banner(tr("MSG_COLLECTS") % [_name(winner), ev.collected], UITheme.TEAM_US if winner % 2 == 0 else UITheme.TEAM_THEM, 0.8, 38)
	else:
		await _sweep(_trick_cards, winner)
		_trick_cards.clear()

	hud.set_tricks(ev.team_tricks, ev.pile if rules.is_sar() else -1)
	hud.show_hint("")
	if ev.court:
		Sound.play("win")
		hud.show_banner("MSG_COURT", UITheme.GOLD, 1.0, 70)
		camera.shake(0.55)
		Effects.confetti(top_fx, Vector2(_vs.x * 0.5, _center.y + 200), 90, 500)
		await _wait(0.8)


func _sweep(cards: Array[Card], winner: int) -> void:
	var dest := _seat_edge(winner)
	for i in cards.size():
		var c := cards[i]
		if not is_instance_valid(c):
			continue
		var t := c.move_to(dest, 0.0, 0.4, 0.38 / _speed, i * 0.025, Tween.TRANS_CUBIC, Tween.EASE_IN)
		t.chain().tween_callback(c.queue_free)
		_nodes.erase(c.data.id())
	Sound.play("deal", 0.15, -2.0)
	await _wait(0.42)


# --- menus -----------------------------------------------------------------------

func _open_pause() -> void:
	get_tree().paused = true
	hud.show_pause(
		func():
			hud.close_overlay()
			get_tree().paused = false,
		func(): Router.restart_game(),
		func(): Router.goto_menu())


func _show_game_over() -> void:
	var w := rules.get_winner()
	if w == 0:
		Sound.play("win")
		for i in 3:
			Effects.confetti(top_fx, Vector2(_vs.x * (0.2 + 0.3 * i), _vs.y + 40), 120, 260)
		camera.shake(0.5)
	else:
		Sound.play("lose")
	hud.show_game_over(w, rules.scores, func(): Router.restart_game(), func(): Router.goto_menu())
	if _autoplay:
		print("AUTOPLAY_DONE winner=%d scores=%s rounds=%d" % [w, rules.scores, rules.round_number])
		await _wait(1.5)
		get_tree().quit()
