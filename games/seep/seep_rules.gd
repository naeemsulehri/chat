class_name SeepRules
extends GameRules
## Seep (Sweep), the classic North-Indian / Pakistani fishing game
## (rules after pagat.com/fishing/seep.html), with selectable variants.
##
## Card values: A=1, 2..10, J=11, Q=12, K=13.
## Points (100 per deal): every spade = its value, other Aces = 1,
## 10♦ = 6. A Seep (clearing the table) scores a bonus.
##
## Each turn a player plays one card and either:
##  - throws it loose on the table,
##  - captures every loose card / combination / house equal to its value,
##  - builds a house (value 9..13) from the card + loose cards,
##    holding another card of that value to capture it later,
##  - cements (pakka) a house of the same value, or
##  - raises an opponent's open house to a higher value.
##
## Options: players 4 (teams) / 2, match length, seep bonus, house values,
## whether a house owner may throw loose cards.

const BID_MIN := 9

var hands: Array = []
var table: Array = []          # piles: { id, cards, value, house, cemented, owner }
var dealer := -1
var bidder := 0
var bid := 0
var current := 0
var first_move_pending := false
var captured: Array = [[], []] # per team
var seeps := [0, 0]
var last_capturer := -1
var scores := [0, 0]
var round_number := 0
var round_summary: Dictionary = {}
var seen: Dictionary = {}      # card id -> true for every card that hit the table
var deck := Deck.new()
var _next_id := 1
var _pending_stage: Array = [] # 2-player second half of the deal
var _rest_dealt := false


static func get_options() -> Array:
	return [
		{
			"id": "players", "label": "OPT_PLAYERS", "default": 4,
			"choices": [
				{"value": 4, "label": "PLAYERS_4", "desc": "PLAYERS_4_DESC"},
				{"value": 2, "label": "PLAYERS_2", "desc": "PLAYERS_2_DESC"},
			],
		},
		{
			"id": "match", "label": "OPT_MATCH", "default": "lead100",
			"choices": [
				{"value": "lead100", "label": "MATCH_LEAD100", "desc": "MATCH_LEAD100_DESC"},
				{"value": "first200", "label": "MATCH_FIRST200", "desc": "MATCH_FIRST200_DESC"},
				{"value": "single", "label": "MATCH_SINGLE", "desc": "MATCH_SINGLE_DESC"},
			],
		},
		{
			"id": "seep_points", "label": "OPT_SEEP_POINTS", "default": 50,
			"choices": [{"value": 50, "label": "50"}, {"value": 25, "label": "25"}],
		},
		{
			"id": "house_min", "label": "OPT_HOUSES", "default": 9,
			"choices": [
				{"value": 9, "label": "HOUSES_CLASSIC", "desc": "HOUSES_CLASSIC_DESC"},
				{"value": 2, "label": "HOUSES_ANY", "desc": "HOUSES_ANY_DESC"},
			],
		},
		{
			"id": "house_lock", "label": "OPT_HOUSE_LOCK", "default": true,
			"choices": [
				{"value": true, "label": "YES", "desc": "HOUSE_LOCK_DESC"},
				{"value": false, "label": "NO"},
			],
		},
	]


func setup(p_config: Dictionary) -> void:
	super.setup(p_config)
	for opt in get_options():
		if not config.has(opt.id):
			config[opt.id] = opt.default
	num_players = int(config.players)
	scores = [0, 0]
	round_number = 0
	dealer = num_players - 1
	if config.has("seed"):
		rng.seed = int(config.seed)
	else:
		rng.randomize()


func team_of(player: int) -> int:
	return player % 2


func next_seat(p: int) -> int:
	return (p + 1) % num_players


static func value_of(c: CardData) -> int:
	return 1 if c.rank == CardData.ACE else c.rank


static func card_points(c: CardData) -> int:
	if c.suit == CardData.Suit.SPADES:
		return value_of(c)
	if c.rank == CardData.ACE:
		return 1
	if c.suit == CardData.Suit.DIAMONDS and c.rank == 10:
		return 6
	return 0


static func cards_points(cards: Array) -> int:
	var n := 0
	for c in cards:
		n += card_points(c)
	return n


# --- dealing --------------------------------------------------------------------------

## Deals 4 cards to the bidder (redealing until they hold a 9 or higher).
func start_round() -> Array:
	round_number += 1
	dealer = next_seat(dealer)
	bidder = next_seat(dealer)
	table.clear()
	captured = [[], []]
	seeps = [0, 0]
	last_capturer = -1
	seen.clear()
	round_summary = {}
	_pending_stage.clear()
	var seq: Array = []
	while true:
		hands = []
		for i in num_players:
			hands.append([])
		deck.reset()
		deck.shuffle(rng)
		seq.clear()
		for i in 4:
			var c := deck.draw()
			hands[bidder].append(c)
			seq.append([bidder, c])
		if not bid_options().is_empty():
			break
	phase = Phase.BIDDING
	return seq


func bid_options() -> Array:
	var out: Array = []
	for c in hands[bidder]:
		var v := value_of(c)
		if v >= BID_MIN and not v in out:
			out.append(v)
	out.sort()
	return out


## Bidder announces a value; four cards go face up to the table.
## Returns the table deal sequence ([-1, card] entries).
func choose_bid(value: int) -> Array:
	assert(phase == Phase.BIDDING and value in bid_options())
	bid = value
	var seq: Array = []
	for i in 4:
		var c := deck.draw()
		table.append(_loose(c))
		seen[c.id()] = true
		seq.append([-1, c])
	current = bidder
	first_move_pending = true
	_rest_dealt = false
	phase = Phase.PLAY
	return seq


func _deal_rest() -> Array:
	var seq: Array = []
	var per: int = 12
	# Bidder already got 4; everyone else gets 12, in packets of 4.
	var need := []
	for p in num_players:
		need.append(per - (4 if p == bidder else 0))
	var p := next_seat(dealer)
	while need.any(func(n): return n > 0):
		if need[p] > 0:
			for i in 4:
				var c := deck.draw()
				hands[p].append(c)
				seq.append([p, c])
			need[p] -= 4
		p = next_seat(p)
	if num_players == 2:
		# Second half of the deal waits until both hands are empty.
		while not deck.is_empty():
			_pending_stage.append(deck.draw())
	return seq


func _deal_stage_two() -> Array:
	var seq: Array = []
	var p := next_seat(dealer)
	while not _pending_stage.is_empty():
		for i in 4:
			var c: CardData = _pending_stage.pop_back()
			hands[p].append(c)
			seq.append([p, c])
		p = next_seat(p)
	return seq


func _loose(c: CardData) -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "cards": [c], "value": value_of(c), "house": false, "cemented": false, "owner": -1}


func get_current_player() -> int:
	return current


func houses() -> Array:
	return table.filter(func(p): return p.house)


func loose_piles() -> Array:
	return table.filter(func(p): return not p.house)


func pile_by_id(id: int) -> Dictionary:
	for p in table:
		if p.id == id:
			return p
	return {}


# --- move generation ------------------------------------------------------------------

## All subsets (as Arrays of piles) of `piles` whose values sum to `target`.
static func subsets_summing(piles: Array, target: int, limit := 64) -> Array:
	var out: Array = []
	var sorted := piles.duplicate()
	sorted.sort_custom(func(a, b): return a.value > b.value)
	_subsets_rec(sorted, 0, target, [], out, limit)
	return out


static func _subsets_rec(piles: Array, i: int, remaining: int, chosen: Array, out: Array, limit: int) -> void:
	if out.size() >= limit:
		return
	if remaining == 0 and not chosen.is_empty():
		out.append(chosen.duplicate())
		return
	for k in range(i, piles.size()):
		var v: int = piles[k].value
		if v > remaining:
			continue
		chosen.append(piles[k])
		_subsets_rec(piles, k + 1, remaining - v, chosen, out, limit)
		chosen.pop_back()


## Largest set of disjoint loose combinations each summing to `v`.
static func best_cover(loose: Array, v: int) -> Array:
	var best: Array = []
	_cover_rec(loose, v, [], best, 0)
	return best


static func _cover_rec(pool: Array, v: int, taken: Array, best: Array, depth: int) -> void:
	if _count_cards(taken) > _count_cards(best):
		best.clear()
		best.append_array(taken)
	if depth > 6 or pool.is_empty():
		return
	var subs := subsets_summing(pool, v, 12)
	for s in subs:
		var rest := pool.filter(func(p): return not s.has(p))
		var t2 := taken.duplicate()
		t2.append_array(s)
		_cover_rec(rest, v, t2, best, depth + 1)
		if subs.size() > 6:
			break  # plenty of options; greedy is good enough


static func _count_cards(piles: Array) -> int:
	var n := 0
	for p in piles:
		n += p.cards.size()
	return n


## Piles a card of value `v` would capture on the given table.
static func capture_targets(tbl: Array, v: int) -> Array:
	var targets: Array = []
	var loose: Array = []
	for p in tbl:
		if p.house:
			if p.value == v:
				targets.append(p)
		elif p.value == v:
			targets.append(p)
		else:
			loose.append(p)
	targets.append_array(best_cover(loose, v))
	return targets


func _holds_value(player: int, v: int, except: CardData) -> bool:
	for c in hands[player]:
		if c.id() != except.id() and value_of(c) == v:
			return true
	return false


## Every legal action for the player. Action = { type, card, piles: [ids], value, target? }
func get_actions(player: int) -> Array:
	var out: Array = []
	if phase != Phase.PLAY or player != current:
		return out
	var hmin: int = int(config.house_min)
	var loose := loose_piles()
	var hs := houses()
	var owns_house := hs.any(func(h): return h.owner == player)
	var throws: Array = []
	for c in hands[player]:
		var v := value_of(c)
		# Capture
		var tg := capture_targets(table, v)
		if not tg.is_empty():
			out.append({"type": "capture", "card": c, "piles": tg.map(func(p): return p.id), "value": v})
		# Cement onto an existing house of value t
		for h in hs:
			var t: int = h.value
			if not _holds_value(player, t, c):
				continue
			if v == t:
				out.append({"type": "cement", "card": c, "piles": [], "value": t, "target": h.id})
			elif v < t:
				var subs := subsets_summing(loose, t - v, 8)
				if not subs.is_empty():
					out.append({"type": "cement", "card": c, "piles": _best_sub(subs).map(func(p): return p.id), "value": t, "target": h.id})
		# Raise an opponent's open house
		for h in hs:
			if h.cemented or team_of(h.owner) == team_of(player):
				continue
			for t2 in range(h.value + v, 14):
				if t2 < hmin or not _holds_value(player, t2, c):
					continue
				if hs.any(func(o): return o.id != h.id and o.value == t2):
					continue  # would duplicate a house; cement that one instead
				var extra: int = t2 - h.value - v
				if extra == 0:
					out.append({"type": "raise", "card": c, "piles": [], "value": t2, "target": h.id})
				else:
					var subs2 := subsets_summing(loose, extra, 8)
					if not subs2.is_empty():
						out.append({"type": "raise", "card": c, "piles": _best_sub(subs2).map(func(p): return p.id), "value": t2, "target": h.id})
		# Build a new house of value t
		for t in range(maxi(hmin, v + 1), 14):
			if not _holds_value(player, t, c):
				continue
			if hs.any(func(h): return h.value == t):
				continue  # covered by cement
			var subs3 := subsets_summing(loose, t - v, 8)
			if not subs3.is_empty():
				out.append({"type": "build", "card": c, "piles": _best_sub(subs3).map(func(p): return p.id), "value": t})
		throws.append({"type": "throw", "card": c, "piles": [], "value": v})

	if first_move_pending and player == bidder:
		out = out.filter(func(a): return a.value == bid if a.type in ["build", "cement", "raise"] else value_of(a.card) == bid)
		throws = throws.filter(func(a): return value_of(a.card) == bid)
	var lock: bool = config.house_lock and owns_house and not out.is_empty()
	if not lock:
		out.append_array(throws)
	return out


## Prefer the subset with the most points, then the most cards.
static func _best_sub(subs: Array) -> Array:
	var best: Array = subs[0]
	var best_score := -1.0
	for s in subs:
		var sc := 0.0
		for p in s:
			sc += cards_points(p.cards) * 10 + p.cards.size()
		if sc > best_score:
			best_score = sc
			best = s
	return best


func actions_for_card(player: int, card: CardData) -> Array:
	return get_actions(player).filter(func(a): return a.card.id() == card.id())


func get_valid_moves(player: int) -> Array[CardData]:
	var out: Array[CardData] = []
	var ids := {}
	for a in get_actions(player):
		if not ids.has(a.card.id()):
			ids[a.card.id()] = true
			out.append(a.card)
	return out


# --- applying actions -----------------------------------------------------------------

func apply_action(player: int, action: Dictionary) -> Dictionary:
	assert(phase == Phase.PLAY and player == current)
	var card: CardData = action.card
	var hand: Array = hands[player]
	for i in hand.size():
		if hand[i].id() == card.id():
			hand.remove_at(i)
			break
	seen[card.id()] = true
	var team := team_of(player)
	var ev := {"type": action.type, "player": player, "card": card, "value": action.value,
		"piles": action.piles.duplicate(), "seep": false, "deal": [], "round_over": false}
	var used: Array = []
	for id in action.piles:
		var p := pile_by_id(id)
		used.append(p)
		table.erase(p)

	match action.type:
		"throw":
			var lp := _loose(card)
			table.append(lp)
			ev.pile_id = lp.id
		"capture":
			var cards: Array = [card]
			for p in used:
				cards.append_array(p.cards)
			captured[team].append_array(cards)
			ev.captured = cards
			last_capturer = player
		"build":
			_next_id += 1
			var cards: Array = [card]
			for p in used:
				cards.append_array(p.cards)
			var h := {"id": _next_id, "cards": cards, "value": action.value, "house": true, "cemented": false, "owner": player}
			table.append(h)
			ev.pile_id = h.id
		"cement", "raise":
			var h := pile_by_id(action.target)
			h.cards.append(card)
			for p in used:
				h.cards.append_array(p.cards)
			h.value = action.value
			h.owner = player
			if action.type == "cement":
				h.cemented = true
			ev.pile_id = h.id

	first_move_pending = first_move_pending and player != bidder
	var hands_empty := hands.all(func(h): return h.is_empty())
	var last_play := hands_empty and _pending_stage.is_empty() and _rest_dealt
	if action.type == "capture" and table.is_empty() and not last_play:
		seeps[team] += 1
		ev.seep = true

	current = next_seat(current)
	if not _rest_dealt:
		_rest_dealt = true
		ev.deal = _deal_rest()
	elif hands_empty and not _pending_stage.is_empty():
		ev.deal = _deal_stage_two()
	elif hands_empty:
		# Deal over: whatever is left goes to the last team that captured.
		var left: Array = []
		for p in table:
			left.append_array(p.cards)
		var lt := team_of(last_capturer) if last_capturer >= 0 else team_of(bidder)
		captured[lt].append_array(left)
		ev.leftover = left
		ev.leftover_team = lt
		ev.leftover_player = last_capturer if last_capturer >= 0 else bidder
		table.clear()
		phase = Phase.ROUND_OVER
		ev.round_over = true
	return ev


# --- scoring --------------------------------------------------------------------------

func score_round() -> Dictionary:
	var sp: int = int(config.seep_points)
	var card_pts := [cards_points(captured[0]), cards_points(captured[1])]
	var pts := [card_pts[0] + seeps[0] * sp, card_pts[1] + seeps[1] * sp]
	scores[0] += pts[0]
	scores[1] += pts[1]
	var winner_team := 0 if pts[0] >= pts[1] else 1
	round_summary = {"winner_team": winner_team, "points": pts, "card_points": card_pts,
		"seeps": seeps.duplicate(), "cards": [captured[0].size(), captured[1].size()], "scores": scores.duplicate()}
	var over := false
	match str(config.match):
		"single": over = true
		"first200": over = scores[0] >= 200 or scores[1] >= 200
		_: over = absi(scores[0] - scores[1]) >= 100
	phase = Phase.GAME_OVER if over else Phase.ROUND_OVER
	return round_summary


func get_winner() -> int:
	if phase != Phase.GAME_OVER:
		return -1
	return 0 if scores[0] >= scores[1] else 1
