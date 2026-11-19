class_name SeepBot
extends BotPlayer
## Computer player for Seep.
##  EASY   - captures when it can (often), otherwise random.
##  MEDIUM - scores each action by immediate gain, avoids leaving easy seeps.
##  HARD   - also estimates what the next opponent can take afterwards using
##           card counting (unseen cards), and values houses by safety.


func choose_bid(rules: SeepRules) -> int:
	var opts := rules.bid_options()
	if difficulty == Difficulty.EASY:
		return pick_random(opts)
	# Bid the value we can most likely build/capture with: pick one that sums
	# with a table-friendly card we hold, else the highest.
	var hand: Array = rules.hands[seat]
	var best: int = opts[-1]
	var best_score := -INF
	for v in opts:
		var count := hand.filter(func(c): return SeepRules.value_of(c) == v).size()
		var score: float = count * 3.0 + v * 0.1
		if score > best_score:
			best_score = score
			best = v
	return best


func choose_action(rules: SeepRules) -> Dictionary:
	var actions := rules.get_actions(seat)
	if actions.size() == 1:
		return actions[0]
	if difficulty == Difficulty.EASY:
		var caps := actions.filter(func(a): return a.type == "capture")
		if not caps.is_empty() and rng.randf() < 0.7:
			return pick_random(caps)
		return pick_random(actions)
	var best: Dictionary = actions[0]
	var best_score := -INF
	for a in actions:
		var s := _evaluate(rules, a)
		s += rng.randf() * (0.8 if difficulty == Difficulty.MEDIUM else 0.2)
		if s > best_score:
			best_score = s
			best = a
	return best


func _team(p: int, rules: SeepRules) -> int:
	return rules.team_of(p)


func _evaluate(rules: SeepRules, a: Dictionary) -> float:
	var sp := float(rules.config.seep_points)
	var card: CardData = a.card
	var used: Array = a.piles.map(func(id): return rules.pile_by_id(id))
	var score := 0.0
	var after := _table_after(rules, a, used)
	match a.type:
		"capture":
			var cards: Array = [card]
			for p in used:
				cards.append_array(p.cards)
			score += SeepRules.cards_points(cards) * 1.0 + cards.size() * 0.35
			if after.is_empty():
				score += sp
			for p in used:
				if p.house and _team(p.owner, rules) != _team(seat, rules):
					score += 4.0  # breaking an opponent's house
		"throw":
			score -= SeepRules.card_points(card) * 0.9 + 0.5
		"build", "cement", "raise":
			var pile_cards: Array = [card]
			for p in used:
				pile_cards.append_array(p.cards)
			if a.type != "build":
				pile_cards.append_array(rules.pile_by_id(a.target).cards)
			# We hold the capturing card, so most of this is ours later.
			var safe := 0.75 if a.type == "cement" else 0.6
			score += SeepRules.cards_points(pile_cards) * safe + pile_cards.size() * 0.25 + 1.5
			if a.type == "raise":
				score += 3.0  # stole an opponent's house
	# Leaving the table exposed: what can the next opponent grab?
	score -= _exposure(rules, after, sp)
	return score


## Expected loss from the next opponent's best capture on `tbl`.
func _exposure(rules: SeepRules, tbl: Array, sp: float) -> float:
	if tbl.is_empty():
		return 0.0
	var opp := rules.next_seat(seat)
	if _team(opp, rules) == _team(seat, rules):
		return 0.0
	var opp_cards: int = rules.hands[opp].size()
	if opp_cards == 0:
		return 0.0
	var unseen := _unseen_counts(rules)
	var total_unseen := 0
	for v in unseen:
		total_unseen += unseen[v]
	var loss := 0.0
	for v in range(1, 14):
		var targets := SeepRules.capture_targets(tbl, v)
		if targets.is_empty():
			continue
		var gain := 0.0
		var n_cards := 0
		for p in targets:
			gain += SeepRules.cards_points(p.cards)
			n_cards += p.cards.size()
		gain += n_cards * 0.35
		if targets.size() == tbl.size():
			gain += sp
		var prob := 1.0
		if difficulty == Difficulty.HARD and total_unseen > 0:
			var k: int = unseen.get(v, 0)
			prob = 1.0 - pow(1.0 - float(k) / total_unseen, opp_cards)
		else:
			prob = 0.35
		loss = maxf(loss, gain * prob)
	return loss * (1.0 if difficulty == Difficulty.HARD else 0.6)


func _unseen_counts(rules: SeepRules) -> Dictionary:
	var counts := {}
	var mine := {}
	for c in rules.hands[seat]:
		mine[c.id()] = true
	for id in 52:
		if rules.seen.has(id) or mine.has(id):
			continue
		var v := SeepRules.value_of(CardData.from_id(id))
		counts[v] = counts.get(v, 0) + 1
	return counts


func _table_after(rules: SeepRules, a: Dictionary, used: Array) -> Array:
	var t: Array = rules.table.filter(func(p): return not used.has(p))
	match a.type:
		"throw":
			t.append({"id": -1, "cards": [a.card], "value": a.value, "house": false, "cemented": false, "owner": -1})
		"build":
			var cards: Array = [a.card]
			for p in used:
				cards.append_array(p.cards)
			t.append({"id": -2, "cards": cards, "value": a.value, "house": true, "cemented": false, "owner": seat})
		"cement", "raise":
			var h: Dictionary = rules.pile_by_id(a.target).duplicate(true)
			t = t.filter(func(p): return p.id != h.id)
			h.cards.append(a.card)
			h.value = a.value
			h.owner = seat
			t.append(h)
	return t
