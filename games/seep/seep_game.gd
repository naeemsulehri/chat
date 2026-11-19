extends CardTableGame
## Seep table. Seat 0 is the human. 4 players (teams) or 2 (head to head).

signal _human_action(action: Dictionary)
signal _bid_chosen(value: int)

var rules: SeepRules
var bots: Array = []
var _deck_cards: Array[Card] = []
var _badges: Dictionary = {}     # pile id -> Label
var _badge_layer: Node2D
var _actions: Array = []         # actions offered for the selected card
var _picking := ""               # "bid" | "action"
var _hl_cards: Array[Card] = []


func _setup_game() -> void:
	rules = SeepRules.new()
	rules.setup(config)
	num_seats = rules.num_players
	if num_seats == 2:
		seat_pos = [Pos.BOTTOM, Pos.TOP]
	var diff := BotPlayer.difficulty_from_string(str(config.get("difficulty", Settings.difficulty)))
	bots.resize(num_seats)
	for s in range(1, num_seats):
		bots[s] = SeepBot.new(s, diff)
	if _autoplay:
		bots[HUMAN] = SeepBot.new(HUMAN, BotPlayer.Difficulty.HARD)


func _seat_info(seat: int) -> Dictionary:
	return {"name": _name_key(seat), "team": seat % 2, "sub": "PARTNER" if num_seats == 4 and seat == 2 else ""}


func _ready() -> void:
	super._ready()
	_badge_layer = Node2D.new()
	_badge_layer.z_index = 250
	card_layer.add_child(_badge_layer)
	hud.choice_made.connect(_on_choice)
	hud.set_info_title("BID")
	hud.set_info_text("")
	hud.set_target_text({"lead100": "TARGET_LEAD100", "first200": "TARGET_FIRST200", "single": "TARGET_SINGLE"}.get(str(rules.config.match), "TARGET_LEAD100"))
	hud.set_scores(rules.scores)
	_update_stats()
	I18n.language_changed.connect(func(_c):
		hud.refresh_language()
		_update_stats())


func _on_choice(v) -> void:
	if _picking == "bid":
		_bid_chosen.emit(v)
	elif _picking == "action" and v is int and v < _actions.size():
		_human_action.emit(_actions[v])


func _update_stats() -> void:
	hud.set_team_stat("POINTS", SeepRules.cards_points(rules.captured[0]), SeepRules.cards_points(rules.captured[1]))
	hud.set_extra(tr("SEEPS_FMT") % [rules.seeps[0], rules.seeps[1]], UITheme.GOLD)


static func vlabel(v: int) -> String:
	match v:
		1: return "A"
		11: return "J·11"
		12: return "Q·12"
		13: return "K·13"
	return str(v)


# --- table layout ------------------------------------------------------------------

func _deck_pos() -> Vector2:
	return Vector2(_vs.x - 150, 345)


func _table_rect() -> Rect2:
	var top := 400.0
	var bottom := _vs.y * 0.66
	return Rect2(100, top, _vs.x - 200, bottom - top)


## Target position for every card on the table: id -> { pos, z }
func _table_targets() -> Dictionary:
	var out := {}
	var piles := rules.table
	var r := _table_rect()
	var scale := 0.8 if piles.size() <= 8 else (0.66 if piles.size() <= 15 else 0.54)
	var cw := Card.W * scale + 34
	var ch := Card.H * scale + 28
	var cols := maxi(1, int(r.size.x / cw))
	var rows := ceili(float(piles.size()) / cols)
	for i in piles.size():
		var p: Dictionary = piles[i]
		var row := i / cols
		var in_row := mini(cols, piles.size() - row * cols)
		var col := i % cols
		var x := r.get_center().x + (col - (in_row - 1) * 0.5) * cw
		var y := r.position.y + Card.H * scale * 0.5 + row * ch
		if rows <= 2:
			y += ch * 0.4
		var n: int = p.cards.size()
		for k in n:
			var step := minf(8.0, 30.0 / maxf(1.0, n - 1))
			var off := Vector2(k * step - (n - 1) * step * 0.5, k * step * 0.6) if p.house else Vector2.ZERO
			out[p.cards[k].id()] = {"pos": Vector2(x, y) + off, "z": 20 + k, "scale": scale, "pile": p.id, "top": Vector2(x, y - Card.H * scale * 0.5)}
	return out


func _relayout_table(dur := 0.3) -> void:
	var t := _table_targets()
	for id in t:
		var c: Card = _nodes.get(id)
		if c == null or not is_instance_valid(c):
			continue
		c.z_index = t[id].z
		if not c.face_up:
			c.flip_to(true, 0.2)
		c.move_to(t[id].pos, 0.0, t[id].scale, dur / _speed)
	_update_badges(t)


func _update_badges(t: Dictionary) -> void:
	var live := {}
	for p in rules.table:
		if not p.house:
			continue
		live[p.id] = true
		var b: Label = _badges.get(p.id)
		var fresh := b == null
		if fresh:
			b = UITheme.make_label("", 22, UITheme.INK, true)
			b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
			_badge_layer.add_child(b)
			_badges[p.id] = b
		var team_col := UITheme.TEAM_US if rules.team_of(p.owner) == 0 else UITheme.TEAM_THEM
		var st := StyleBoxFlat.new()
		st.bg_color = team_col
		st.set_corner_radius_all(14)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.set_border_width_all(4 if p.cemented else 0)
		st.border_color = UITheme.GOLD
		if p.cemented:
			st.shadow_color = Color(UITheme.GOLD, 0.6)
			st.shadow_size = 6
		st.anti_aliasing = true
		b.add_theme_stylebox_override("normal", st)
		b.text = vlabel(p.value)
		b.reset_size()
		var top: Vector2 = t[p.cards[0].id()].top
		var target := top - Vector2(b.size.x * 0.5, b.size.y * 0.75)
		if fresh:
			b.position = target
			b.pivot_offset = b.size * 0.5
			b.scale = Vector2(0.2, 0.2)
			var tw := b.create_tween()
			tw.tween_property(b, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			b.create_tween().tween_property(b, "position", target, 0.25 / _speed)
	for id in _badges.keys():
		if not live.has(id):
			_badges[id].queue_free()
			_badges.erase(id)


func _deal_to_table(c: Card, delay: float) -> void:
	var t := _table_targets()
	var info: Dictionary = t.get(c.data.id(), {"pos": _center, "z": 20, "scale": 0.66})
	c.z_index = info.z
	c.move_to(info.pos, 0.0, info.scale, 0.32 / _speed, delay, Tween.TRANS_QUART)
	c.flip_to(true, 0.24, delay + 0.2 / _speed)


func _clear_table() -> void:
	super._clear_table()
	for id in _badges:
		_badges[id].queue_free()
	_badges.clear()
	_deck_cards.clear()


func _on_layout() -> void:
	if rules != null and _badge_layer != null:
		_relayout_table(0.2)
	for i in _deck_cards.size():
		if is_instance_valid(_deck_cards[i]):
			_deck_cards[i].position = _deck_pos() + Vector2(-i * 0.2, -i * 0.3)


# --- match flow ----------------------------------------------------------------------

func _run_match() -> void:
	while is_inside_tree():
		await _play_round()
		if not is_inside_tree():
			return
		var s := rules.score_round()
		hud.set_scores(s.scores, true)
		var won: bool = s.winner_team == 0
		if won:
			_celebrate()
		else:
			Sound.play("lose")
		await _wait(0.9)
		if rules.is_game_over():
			_show_game_over(rules.get_winner(), rules.scores, rules.round_number)
			return
		var lines := [
			tr("DEAL_CARD_POINTS") % [s.card_points[0], s.card_points[1]],
			tr("DEAL_SEEPS") % [s.seeps[0], s.seeps[1], int(rules.config.seep_points)],
			tr("DEAL_TOTAL") % [s.points[0], s.points[1]],
		]
		hud.show_round_result(won, "DEAL_WON" if won else "DEAL_LOST", lines, s.scores)
		await _await_continue()


func _play_round() -> void:
	_clear_table()
	var first := rules.start_round()
	_update_stats()
	hud.set_info_text("")
	hud.set_dealer(rules.dealer)
	hud.set_turn(-1)

	var deck := _spawn_deck()
	await _shuffle_anim(deck)
	await _deal(first, deck)

	# Bid
	var b := rules.bidder
	hud.set_turn(b)
	var bid: int
	if b == HUMAN and not _autoplay:
		var opts := []
		for v in rules.bid_options():
			opts.append({"value": v, "label": vlabel(v)})
		_picking = "bid"
		hud.open_choices("MSG_CHOOSE_BID", opts, "center", 5)
		bid = await _bid_chosen
		_picking = ""
	else:
		hud.show_hint(tr("MSG_BIDDING") % _name(b))
		await _wait(1.0)
		bid = (bots[b] as SeepBot).choose_bid(rules)
		hud.show_hint("")
	Sound.play("trump")
	hud.set_info_text(vlabel(bid).split("·")[0])
	hud.show_banner(tr("MSG_BID_IS") % vlabel(bid), UITheme.GOLD)
	var tseq := rules.choose_bid(bid)
	await _deal(tseq, deck, false)
	# Park the rest of the deck in the corner.
	_deck_cards = deck
	for i in deck.size():
		deck[i].move_to(_deck_pos() + Vector2(-i * 0.2, -i * 0.3), 0.0, 0.55, 0.35 / _speed, i * 0.004)
	_relayout_table()

	while rules.phase == GameRules.Phase.PLAY and is_inside_tree():
		var seat := rules.current
		hud.set_turn(seat)
		var action: Dictionary
		if seat == HUMAN and not _autoplay:
			action = await _human_turn()
		else:
			await _wait((bots[seat] as BotPlayer).think_time() + 0.2)
			action = (bots[seat] as SeepBot).choose_action(rules)
		var ev := rules.apply_action(seat, action)
		await _animate_action(seat, ev)
		_update_stats()
		if not ev.deal.is_empty():
			await _deal(ev.deal, _deck_cards)
		if ev.round_over:
			await _animate_leftover(ev)
	hud.set_turn(-1)
	for c in _deck_cards:
		if is_instance_valid(c):
			c.queue_free()
	_deck_cards.clear()


# --- human turn ------------------------------------------------------------------------

func _human_turn() -> Dictionary:
	var valid := rules.get_valid_moves(HUMAN)
	_begin_human_pick(valid, false)
	if rules.first_move_pending and rules.bidder == HUMAN:
		hud.show_hint(tr("MSG_BID_PLAY") % vlabel(rules.bid))
	else:
		hud.show_hint("MSG_PICK_CARD")
	var action: Dictionary = await _human_action
	_picking = ""
	hud.close_choices()
	_clear_highlights()
	_end_human_pick()
	return action


func _second_tap_plays() -> bool:
	return false


func _on_human_select(card: Card) -> void:
	_clear_highlights()
	hud.close_choices()
	if card == null:
		return
	_actions = rules.actions_for_card(HUMAN, card.data)
	_actions.sort_custom(func(a, b): return _action_rank(a) < _action_rank(b))
	var opts := []
	for i in _actions.size():
		opts.append({"value": i, "label": _action_label(_actions[i])})
	_picking = "action"
	hud.show_hint("")
	hud.open_choices("", opts, "bottom", 2)
	# Glow the table cards the best option would use.
	var a: Dictionary = _actions[0]
	var ids: Array = a.piles.duplicate()
	if a.has("target"):
		ids.append(a.target)
	for id in ids:
		var p := rules.pile_by_id(id)
		for cd in p.get("cards", []):
			var c: Card = _nodes.get(cd.id())
			if c:
				c.set_glow(true, Color("7ee8ff"), 0.9)
				_hl_cards.append(c)


func _clear_highlights() -> void:
	for c in _hl_cards:
		if is_instance_valid(c):
			c.set_glow(false)
	_hl_cards.clear()


func _action_rank(a: Dictionary) -> int:
	return ["capture", "cement", "build", "raise", "throw"].find(a.type)


func _action_label(a: Dictionary) -> String:
	match a.type:
		"capture":
			var n := 1
			for id in a.piles:
				n += rules.pile_by_id(id).cards.size()
			return tr("ACT_CAPTURE") % n
		"build": return tr("ACT_BUILD") % vlabel(a.value)
		"cement": return tr("ACT_CEMENT") % vlabel(a.value)
		"raise": return tr("ACT_RAISE") % vlabel(a.value)
	return tr("ACT_THROW")


# --- animations ------------------------------------------------------------------------

func _animate_action(seat: int, ev: Dictionary) -> void:
	var data: CardData = ev.card
	var c: Card = _nodes[data.id()]
	hands[seat].remove_card(c)
	hands[seat].relayout(0.25)
	if not c.face_up:
		c.flip_to(true, 0.22)
	c.z_index = 200
	Sound.play("deal", 0.1, -3.0)
	match ev.type:
		"capture":
			# Fly to the captured piles, gather them, then sweep to the player.
			var taken: Array = [c]
			var center := Vector2.ZERO
			var n := 0
			for cd in ev.captured:
				if cd.id() == data.id():
					continue
				var tc: Card = _nodes.get(cd.id())
				if tc:
					taken.append(tc)
					center += tc.position
					n += 1
			if n > 0:
				center /= n
			c.move_to(center + Vector2(0, -20), randf_range(-0.1, 0.1), 0.72, 0.3 / _speed, 0.0, Tween.TRANS_BACK)
			await _wait(0.32)
			Sound.play("place")
			for tc in taken:
				tc.set_glow(true, UITheme.GOLD, 0.9)
			c.shine(0.5, 1.0)
			Effects.sparkle(fx_layer, center, UITheme.GOLD, 16)
			hud.show_hint(tr("MSG_TAKES") % [_name(seat), taken.size()])
			await _wait(0.45)
			for tc in taken:
				tc.set_glow(false)
			if ev.seep:
				hud.show_banner("MSG_SEEP", UITheme.GOLD, 1.0, 76)
				camera.shake(0.6)
				Sound.play("win")
				Effects.confetti(top_fx, Vector2(_vs.x * 0.5, _center.y + 260), 90, 520)
			Sound.play("collect", 0.05, -4.0)
			await _sweep(taken, seat)
			hud.show_hint("")
			_relayout_table()
		"throw":
			_relayout_table()
			await _wait(0.3)
			Sound.play("place")
		_:
			_relayout_table(0.35)
			await _wait(0.38)
			Sound.play("place")
			c.shine(0.5, 0.9)
			var key: String = {"build": "MSG_BUILDS", "cement": "MSG_CEMENTS", "raise": "MSG_RAISES"}[ev.type]
			hud.show_hint(tr(key) % [_name(seat), vlabel(ev.value)])
			if ev.type == "raise":
				camera.shake(0.2)
			await _wait(0.45)
			hud.show_hint("")


func _animate_leftover(ev: Dictionary) -> void:
	var left: Array = ev.get("leftover", [])
	if left.is_empty():
		return
	await _wait(0.4)
	hud.show_hint(tr("MSG_LEFTOVER") % _name(ev.leftover_player))
	var cards: Array = []
	for cd in left:
		var c: Card = _nodes.get(cd.id())
		if c:
			cards.append(c)
	await _sweep(cards, ev.leftover_player)
	_update_badges({})
	_update_stats()
	await _wait(0.4)
	hud.show_hint("")
