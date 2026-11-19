extends SceneTree
## Headless Seep rules + AI test:  godot --headless -s res://tests/test_seep.gd

var failures := 0


func _init() -> void:
	_test_points()
	for players in [4, 2]:
		for lock in [true, false]:
			for hmin in [9, 2]:
				_simulate({"players": players, "house_lock": lock, "house_min": hmin, "match": "single", "seep_points": 50}, 40)
	_simulate({"players": 4, "match": "lead100"}, 15)
	_strength(4)
	_strength(2)
	print("\n%s (%d failures)" % ["ALL TESTS PASSED" if failures == 0 else "TESTS FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)


func _test_points() -> void:
	var d := Deck.new()
	check(SeepRules.cards_points(d.cards) == 100, "deck worth 100 points")
	var t := [{"id": 1, "cards": [CardData.new(1, 3)], "value": 3, "house": false},
		{"id": 2, "cards": [CardData.new(2, 5)], "value": 5, "house": false},
		{"id": 3, "cards": [CardData.new(3, 8)], "value": 8, "house": false},
		{"id": 4, "cards": [CardData.new(0, 4)], "value": 4, "house": false},
		{"id": 5, "cards": [CardData.new(0, 4)], "value": 4, "house": false}]
	var tg := SeepRules.capture_targets(t, 8)
	check(tg.size() == 5, "8 captures 8, 3+5 and 4+4 (got %d)" % tg.size())


func _play(config: Dictionary, levels: Array) -> SeepRules:
	var r := SeepRules.new()
	r.setup(config)
	var bots := []
	for s in r.num_players:
		bots.append(SeepBot.new(s, levels[s % levels.size()]))
	var guard := 0
	while not r.is_game_over() and guard < 60:
		guard += 1
		var first := r.start_round()
		check(first.size() == 4, "bidder gets 4")
		var b: int = bots[r.bidder].choose_bid(r)
		check(b >= 9 and b <= 13, "bid 9..13")
		r.choose_bid(b)
		check(r.table.size() == 4, "4 cards on table")
		var steps := 0
		var total_dealt := 8
		while r.phase == GameRules.Phase.PLAY and steps < 200:
			steps += 1
			var p := r.current
			var acts := r.get_actions(p)
			check(not acts.is_empty(), "player has an action")
			if acts.is_empty():
				break
			var a: Dictionary = bots[p].choose_action(r)
			if steps == 1:
				check(SeepRules.value_of(a.card) == b or a.value == b, "bidder's first play uses the bid")
			var ev := r.apply_action(p, a)
			total_dealt += ev.deal.size()
		check(r.phase == GameRules.Phase.ROUND_OVER, "deal finishes")
		check(total_dealt == 52, "all 52 cards dealt (%d)" % total_dealt)
		check(r.captured[0].size() + r.captured[1].size() == 52, "all cards captured at the end")
		var s := r.score_round()
		check(s.card_points[0] + s.card_points[1] == 100, "card points sum to 100")
	check(r.is_game_over(), "match ends")
	return r


func _simulate(cfg: Dictionary, n: int) -> void:
	var seeps := 0
	for i in n:
		cfg.seed = 300 + i
		var r := _play(cfg, [i % 3, (i + 1) % 3])
		seeps += r.round_summary.seeps[0] + r.round_summary.seeps[1]
	print("seep %s: %d matches OK, %d seeps in final deals" % [cfg, n, seeps])


func _strength(players: int) -> void:
	for pairing in [["hard_vs_easy", 2, 0], ["medium_vs_easy", 1, 0], ["hard_vs_medium", 2, 1]]:
		var wins := 0
		var n := 120
		for i in n:
			var r := _play({"players": players, "match": "single", "seed": 9000 + i}, [pairing[1], pairing[2]])
			if r.get_winner() == 0:
				wins += 1
		print("seep %dp %s: team win rate %.0f%%" % [players, pairing[0], 100.0 * wins / n])
