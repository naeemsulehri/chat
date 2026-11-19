extends SceneTree
## Headless rules + AI test. Run:
##   godot --headless --path . -s res://tests/test_rang.gd

var failures := 0


func _init() -> void:
	_test_deck()
	_test_follow_suit()
	for mode in ["simple", "sar", "sar_no_ace"]:
		for pair in ["player", "team"]:
			_simulate(mode, pair, 60)
	_strength("simple")
	_strength("sar")
	print("\n%s (%d failures)" % ["ALL TESTS PASSED" if failures == 0 else "TESTS FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)


func _test_deck() -> void:
	var d := Deck.new()
	check(d.size() == 52, "deck has 52 cards")
	var ids := {}
	for c in d.cards:
		ids[c.id()] = true
	check(ids.size() == 52, "deck cards unique")


func _test_follow_suit() -> void:
	var r := RangRules.new()
	r.setup({"seed": 7})
	r.start_round()
	r.choose_trump(r.caller, CardData.Suit.HEARTS)
	var p := r.current
	var lead: CardData = r.hands[p][0]
	r.play_card(p, lead)
	var nxt := r.current
	var valid := r.get_valid_moves(nxt)
	var has_suit := false
	for c in r.hands[nxt]:
		if c.suit == lead.suit:
			has_suit = true
	for c in valid:
		if has_suit:
			check(c.suit == lead.suit, "must follow suit")
	check(r.get_valid_moves((nxt + 1) % 4).is_empty(), "no moves out of turn")


func _play_match(config: Dictionary, levels: Array) -> RangRules:
	var r := RangRules.new()
	r.setup(config)
	var bots := []
	for s in 4:
		bots.append(RangBot.new(s, levels[s]))
	var guard := 0
	while not r.is_game_over() and guard < 200:
		guard += 1
		var first := r.start_round()
		check(first.size() == 20, "first deal is 5 each")
		for s in 4:
			check(r.hands[s].size() == 5, "5 cards before trump")
		var suit: int = bots[r.caller].choose_trump(r)
		check(suit >= 0 and suit < 4, "trump suit valid")
		var rest := r.choose_trump(r.caller, suit)
		check(rest.size() == 32, "rest deal is 8 each")
		for s in 4:
			check(r.hands[s].size() == 13, "13 cards after deal")
		var steps := 0
		while r.phase == GameRules.Phase.PLAY and steps < 60:
			steps += 1
			var p := r.current
			var c: CardData = bots[p].choose_card(r)
			check(r.is_valid_move(p, c), "bot plays legal card")
			r.play_card(p, c)
		check(r.phase == GameRules.Phase.ROUND_OVER, "round ends")
		var tt: Array = r.team_tricks
		if r.is_sar():
			check(tt[0] + tt[1] == 13, "sar: all 13 tricks collected (got %s)" % [tt])
		else:
			check(tt[0] >= 7 or tt[1] >= 7, "simple: someone reached 7")
			check(tt[0] + tt[1] <= 13, "simple: <= 13 tricks")
		var s := r.score_round()
		check(s.points >= 1, "round scores points")
	check(r.is_game_over(), "match finishes")
	return r


func _simulate(mode: String, pair: String, matches: int) -> void:
	var courts := 0
	var rounds := 0
	for i in matches:
		var levels := [i % 3, (i + 1) % 3, (i + 2) % 3, i % 3]
		var r := _play_match({"trick_mode": mode, "sar_pair": pair, "seed": 1000 + i, "target": 7, "court_points": 2}, levels)
		rounds += r.round_number
	print("mode=%s pair=%s: %d matches, %d rounds OK" % [mode, pair, matches, rounds])


## Hard team (0 & 2) vs easy team (1 & 3) — hard should win clearly more.
func _strength(mode: String) -> void:
	var results := {}
	for pairing in [["hard", BotPlayer.Difficulty.HARD, BotPlayer.Difficulty.EASY], ["medium", BotPlayer.Difficulty.MEDIUM, BotPlayer.Difficulty.EASY], ["hard_vs_medium", BotPlayer.Difficulty.HARD, BotPlayer.Difficulty.MEDIUM]]:
		var wins := 0
		var n := 150
		for i in n:
			var a: int = pairing[1]
			var b: int = pairing[2]
			var r := _play_match({"trick_mode": mode, "seed": 5000 + i, "target": 7}, [a, b, a, b])
			if r.get_winner() == 0:
				wins += 1
		results[pairing[0]] = float(wins) / n
		print("mode=%s %s team win rate: %.0f%%" % [mode, pairing[0], 100.0 * wins / n])
	check(results.hard > 0.6, "hard beats easy in %s" % mode)
	check(results.medium > 0.55, "medium beats easy in %s" % mode)
