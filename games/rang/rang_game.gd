extends CardTableGame
## Rang table. Seat 0 is the human (bottom); seats 1..3 are bots.

signal _trump_chosen(suit: int)

var rules: RangRules
var bots: Array = [null, null, null, null]
var _trick_cards: Array[Card] = []
var _pile_cards: Array[Card] = []


func _setup_game() -> void:
	rules = RangRules.new()
	rules.setup(config)
	var diff := BotPlayer.difficulty_from_string(str(config.get("difficulty", Settings.difficulty)))
	for s in range(1, 4):
		bots[s] = RangBot.new(s, diff)
	if _autoplay:
		bots[HUMAN] = RangBot.new(HUMAN, BotPlayer.Difficulty.HARD)


func _ready() -> void:
	super._ready()
	hud.choice_made.connect(func(v): _trump_chosen.emit(v))
	hud.set_info_title("TRUMP")
	hud.set_target(int(rules.config.target))
	hud.set_scores(rules.scores)
	hud.set_tricks([0, 0])
	hud.set_trump(-1)
	I18n.language_changed.connect(func(_c):
		hud.refresh_language()
		hud.set_tricks(rules.team_tricks, rules.pile if rules.is_sar() else -1))


func _pile_pos() -> Vector2:
	return _center + Vector2(-205, -170)


func _sort_human() -> void:
	hands[HUMAN].sort_cards(rules.trump)


func _clear_table() -> void:
	super._clear_table()
	_trick_cards.clear()
	_pile_cards.clear()


# --- match flow ----------------------------------------------------------------------

func _run_match() -> void:
	while is_inside_tree():
		await _play_round()
		if not is_inside_tree():
			return
		var summary := rules.score_round()
		hud.set_scores(summary.scores, true)
		var won: bool = summary.winner_team == 0
		if won:
			_celebrate()
		else:
			Sound.play("lose")
		if summary.court or summary.bavan:
			camera.shake(0.7)
		await _wait(0.9)
		if rules.is_game_over():
			_show_game_over(rules.get_winner(), rules.scores, rules.round_number)
			return
		var lines := []
		if summary.bavan or summary.court:
			lines.append(tr("MSG_BAVAN" if summary.bavan else "MSG_COURT"))
		lines.append(tr("ROUND_DETAIL") % [summary.tricks[0], summary.tricks[1], summary.points])
		hud.show_round_result(won, "ROUND_WON" if won else "ROUND_LOST", lines, summary.scores)
		await _await_continue()


func _play_round() -> void:
	_clear_table()
	var first := rules.start_round()
	hud.set_trump(-1)
	hud.set_tricks([0, 0], 0 if rules.is_sar() else -1)
	hud.set_dealer(rules.dealer)
	hud.set_turn(-1)

	var deck := _spawn_deck()
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
		var opts := []
		for s in [CardData.Suit.SPADES, CardData.Suit.HEARTS, CardData.Suit.CLUBS, CardData.Suit.DIAMONDS]:
			opts.append({"value": s, "label": CardData.suit_key(s), "suit": s})
		hud.open_choices("MSG_CHOOSE_TRUMP", opts)
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
	await _wait(0.4)

	# Tricks
	while rules.phase == GameRules.Phase.PLAY and is_inside_tree():
		var seat := rules.current
		hud.set_turn(seat)
		var card: CardData
		if seat == HUMAN and not _autoplay:
			card = await _human_pick(rules.get_valid_moves(HUMAN))
		else:
			await _wait((bots[seat] as BotPlayer).think_time())
			card = (bots[seat] as RangBot).choose_card(rules)
		var ev := rules.play_card(seat, card)
		await _animate_play(seat, card)
		if ev.trick_complete:
			await _resolve_trick(ev)
	hud.set_turn(-1)


func _on_illegal_tap(_card: Card) -> void:
	hud.show_hint("MSG_MUST_FOLLOW")


# --- trick animation -----------------------------------------------------------------

func _animate_play(seat: int, data: CardData) -> void:
	var c: Card = _nodes[data.id()]
	hands[seat].remove_card(c)
	_trick_cards.append(c)
	c.z_index = 120 + _trick_cards.size()
	var target := _play_slot(seat) + Vector2(randf_range(-5, 5), randf_range(-5, 5))
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
