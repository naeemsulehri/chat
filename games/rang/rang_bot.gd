class_name RangBot
extends BotPlayer
## Computer player for Rang. Only uses public information + its own hand.
##  EASY   - random legal card, trump = longest suit.
##  MEDIUM - sensible heuristics: win cheaply, don't overtake partner.
##  HARD   - card counting, void tracking, master cards, smart trumping.


func choose_trump(rules: RangRules) -> int:
	var hand: Array = rules.hands[seat]
	var best := -1
	var best_score := -INF
	for s in 4:
		var score := 0.0
		for c in hand:
			if c.suit != s:
				continue
			score += 2.0
			if difficulty != Difficulty.EASY:
				score += maxf(0.0, c.rank - 9) * 0.9  # J=1.8 .. A=4.5
		if difficulty == Difficulty.EASY:
			score += rng.randf() * 0.5
		elif difficulty == Difficulty.MEDIUM:
			score += rng.randf() * 0.3
		if score > best_score:
			best_score = score
			best = s
	return best


func choose_card(rules: RangRules) -> CardData:
	var valid := rules.get_valid_moves(seat)
	if valid.size() == 1:
		return valid[0]
	match difficulty:
		Difficulty.EASY:
			# Mostly random; sometimes plays sensibly so it isn't hopeless.
			if rng.randf() < 0.35:
				return _medium(rules, valid)
			return pick_random(valid)
		Difficulty.MEDIUM:
			return _medium(rules, valid)
	return _hard(rules, valid)


# --- helpers -------------------------------------------------------------------

func _lowest(cards: Array, trump: int, avoid_trump := true) -> CardData:
	var best: CardData = null
	for c in cards:
		if best == null:
			best = c
			continue
		var c_t: bool = avoid_trump and c.suit == trump
		var b_t: bool = avoid_trump and best.suit == trump
		if c_t != b_t:
			if b_t:
				best = c
			continue
		if c.rank < best.rank:
			best = c
	return best


func _highest(cards: Array) -> CardData:
	var best: CardData = null
	for c in cards:
		if best == null or c.rank > best.rank:
			best = c
	return best


## Cheapest card in `cards` that beats the current trick winner.
func _cheapest_winner(rules: RangRules, cards: Array) -> CardData:
	var win: Dictionary = rules.trick_winner()
	var led := rules.led_suit()
	var best: CardData = null
	for c in cards:
		if not rules.beats(c, win.card, led):
			continue
		if best == null:
			best = c
		elif (best.suit == rules.trump) != (c.suit == rules.trump):
			if best.suit == rules.trump:
				best = c  # prefer winning without trump
		elif c.rank < best.rank:
			best = c
	return best


func _partner_winning(rules: RangRules) -> bool:
	var win: Dictionary = rules.trick_winner()
	return not win.is_empty() and win.player == RangRules.partner_of(seat)


func _by_suit(cards: Array) -> Dictionary:
	var d := {}
	for c in cards:
		if not d.has(c.suit):
			d[c.suit] = []
		d[c.suit].append(c)
	return d


# --- MEDIUM --------------------------------------------------------------------

func _medium(rules: RangRules, valid: Array[CardData]) -> CardData:
	var trump := rules.trump
	if rules.trick.is_empty():
		# Lead: an Ace of a side suit, else low from the longest side suit.
		for c in valid:
			if c.rank == CardData.ACE and c.suit != trump:
				return c
		var groups := _by_suit(valid)
		var best_suit := -1
		for s in groups:
			if s == trump and groups.size() > 1:
				continue
			if best_suit == -1 or groups[s].size() > groups[best_suit].size():
				best_suit = s
		return _lowest(groups[best_suit], trump)

	if _partner_winning(rules):
		return _lowest(valid, trump)
	var w := _cheapest_winner(rules, valid)
	if w != null:
		return w
	return _lowest(valid, trump)


# --- HARD ----------------------------------------------------------------------

func _is_master(rules: RangRules, c: CardData) -> bool:
	for r in rules.unplayed_in_suit(c.suit):
		if r > c.rank and not _holds(rules, c.suit, r):
			return false
	return true


func _holds(rules: RangRules, suit: int, rank: int) -> bool:
	for c in rules.hands[seat]:
		if c.suit == suit and c.rank == rank:
			return true
	return false


func _opponents() -> Array:
	return [(seat + 1) % 4, (seat + 3) % 4]


## Outstanding cards of a suit held by others (not played, not mine).
func _outstanding(rules: RangRules, suit: int) -> int:
	var n := 0
	for r in rules.unplayed_in_suit(suit):
		if not _holds(rules, suit, r):
			n += 1
	return n


func _opponent_may_ruff(rules: RangRules, suit: int, players: Array) -> bool:
	if suit == rules.trump:
		return false
	for p in players:
		if p == RangRules.partner_of(seat):
			continue
		if rules.voids[p].has(suit) and not rules.voids[p].has(rules.trump):
			return true
	return false


func _hard(rules: RangRules, valid: Array[CardData]) -> CardData:
	var trump := rules.trump
	var hand: Array = rules.hands[seat]
	var groups := _by_suit(valid)
	var opps := _opponents()

	if rules.trick.is_empty():
		# 1) Pull trumps when strong: hold the master trump and plenty of trumps.
		if groups.has(trump):
			var my_trumps: int = groups[trump].size()
			var out_trumps := _outstanding(rules, trump)
			var top: CardData = _highest(groups[trump])
			if out_trumps > 0 and _is_master(rules, top) and my_trumps >= out_trumps:
				return top
		# 2) Cash a master card in a side suit opponents can't ruff.
		var cash: CardData = null
		for c in valid:
			if c.suit == trump or not _is_master(rules, c):
				continue
			if _opponent_may_ruff(rules, c.suit, opps):
				continue
			if _outstanding(rules, c.suit) == 0:
				continue  # nobody else has the suit; save it
			if cash == null or c.rank > cash.rank:
				cash = c
		if cash != null:
			return cash
		# 3) Lead a suit partner is void in (partner may ruff), low.
		var partner := RangRules.partner_of(seat)
		for s in groups:
			if s != trump and rules.voids[partner].has(s) and not rules.voids[partner].has(trump) \
					and not _opponent_may_ruff(rules, s, opps):
				return _lowest(groups[s], trump)
		# 4) Otherwise low from the longest safe side suit.
		var best_suit := -1
		var best_len := -100
		for s in groups:
			if s == trump:
				continue
			var l: int = groups[s].size() - (3 if _opponent_may_ruff(rules, s, opps) else 0)
			if l > best_len:
				best_len = l
				best_suit = s
		if best_suit == -1:
			best_suit = trump
		return _lowest(groups[best_suit], trump, best_suit != trump)

	# Following
	var win: Dictionary = rules.trick_winner()
	var led := rules.led_suit()
	var played_players: Array = rules.trick.map(func(e): return e.player)
	var still_to_play: Array = []
	for p in range(4):
		if p != seat and not played_players.has(p):
			still_to_play.append(p)
	var opps_left := still_to_play.filter(func(p): return p != RangRules.partner_of(seat))

	if _partner_winning(rules):
		var safe := opps_left.is_empty()
		if not safe:
			safe = _card_is_safe(rules, win.card, led, opps_left)
		if safe:
			return _discard(rules, valid)
		# Partner might be beaten: overtake with a master if we can follow.
		var cover := _cheapest_winner(rules, valid)
		if cover != null and cover.suit == led and _is_master(rules, cover):
			return cover
		return _discard(rules, valid)

	var w := _cheapest_winner(rules, valid)
	if w == null:
		return _discard(rules, valid)
	if opps_left.is_empty():
		return w  # last to play: cheapest winner is perfect
	# Not last: prefer a winner that's likely to hold.
	if w.suit == led and not _card_is_safe(rules, w, led, opps_left):
		var top := _highest(valid.filter(func(c): return c.suit == led))
		if top != null and _is_master(rules, top) and rules.beats(top, win.card, led) \
				and not _opponent_may_ruff(rules, led, opps_left):
			return top
		# A low win attempt isn't worth much if it will be beaten; play low.
		if w.rank < CardData.QUEEN and _outstanding_higher(rules, w) > 1:
			return _discard(rules, valid)
	return w


func _outstanding_higher(rules: RangRules, c: CardData) -> int:
	var n := 0
	for r in rules.unplayed_in_suit(c.suit):
		if r > c.rank and not _holds(rules, c.suit, r):
			n += 1
	return n


## Will `c` (currently winning) survive the remaining players?
func _card_is_safe(rules: RangRules, c: CardData, led: int, remaining: Array) -> bool:
	if c.suit == rules.trump:
		return _is_master(rules, c) or remaining.all(func(p): return rules.voids[p].has(rules.trump))
	if not _is_master(rules, c):
		return false
	return not _opponent_may_ruff(rules, led, remaining) and \
		remaining.all(func(p): return not rules.voids[p].has(led) or rules.voids[p].has(rules.trump))


## Throw away the least useful card: lowest non-master from the shortest side suit.
func _discard(rules: RangRules, valid: Array[CardData]) -> CardData:
	var trump := rules.trump
	var groups := _by_suit(valid)
	var best: CardData = null
	var best_score := INF
	for c in valid:
		var score: float = c.rank
		if c.suit == trump:
			score += 20.0
		if _is_master(rules, c):
			score += 12.0
		score += groups[c.suit].size() * 0.6  # prefer emptying short suits
		if score < best_score:
			best_score = score
			best = c
	return best
