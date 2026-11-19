class_name RangRules
extends GameRules
## Rang / Court Piece rules. 4 players, seats 0..3 in play order
## (counter-clockwise on screen: 0 bottom, 1 right, 2 top, 3 left).
## Teams: 0 = seats 0 & 2, 1 = seats 1 & 3.
##
## House rules (configurable on the setup screen):
## - trick_mode: "simple" | "sar" | "sar_no_ace"
## - sar_pair:   "player" | "team"  (who must win two in a row to collect)
## - target:     match points to win (default 7)
## - court_points: points for a Court (Bavan Court scores double that)
## Fixed: the player after the dealer sees 5 cards and picks trump; the
## deal passes to the next player every round.

const HAND_SIZE := 13
const FIRST_DEAL := 5
const TRICKS_TO_WIN := 7

var deck := Deck.new()
var hands: Array = [[], [], [], []]     # Array[Array[CardData]] per seat
var dealer := 3
var caller := 0                          # trump chooser
var trump := -1
var leader := 0
var current := 0
var trick: Array = []                    # [{ "player": int, "card": CardData }]
var tricks_played := 0
var team_tricks := [0, 0]                # tricks credited (collected) per team
var pile := 0                            # Sar: uncollected tricks in the middle
var last_winner := -1                    # Sar streak tracking
var scores := [0, 0]
var round_number := 0
var court_team := -1                     # team that has a Court in progress/achieved
var round_summary: Dictionary = {}

# Public knowledge bots may use (no peeking at hands):
var played: Dictionary = {}              # card id -> true
var voids: Array = [{}, {}, {}, {}]      # seat -> { suit: true }

var _pending_deal: Array = []


static func get_options() -> Array:
	return [
		{
			"id": "trick_mode", "label": "OPT_TRICK_MODE", "default": "simple",
			"choices": [
				{"value": "simple", "label": "MODE_SIMPLE", "desc": "MODE_SIMPLE_DESC"},
				{"value": "sar", "label": "MODE_SAR", "desc": "MODE_SAR_DESC"},
				{"value": "sar_no_ace", "label": "MODE_SAR_NO_ACE", "desc": "MODE_SAR_NO_ACE_DESC"},
			],
		},
		{
			"id": "sar_pair", "label": "OPT_SAR_PAIR", "default": "player",
			"show_if": {"trick_mode": ["sar", "sar_no_ace"]},
			"choices": [
				{"value": "player", "label": "PAIR_PLAYER"},
				{"value": "team", "label": "PAIR_TEAM"},
			],
		},
		{
			"id": "target", "label": "OPT_TARGET", "default": 7,
			"choices": [{"value": 5, "label": "5"}, {"value": 7, "label": "7"}, {"value": 10, "label": "10"}],
		},
		{
			"id": "court_points", "label": "OPT_COURT_POINTS", "default": 2,
			"choices": [{"value": 2, "label": "2"}, {"value": 3, "label": "3"}],
		},
	]


func setup(p_config: Dictionary) -> void:
	super.setup(p_config)
	for opt in get_options():
		if not config.has(opt.id):
			config[opt.id] = opt.default
	num_players = 4
	scores = [0, 0]
	round_number = 0
	dealer = 3
	if config.has("seed"):
		rng.seed = int(config.seed)
	else:
		rng.randomize()
	phase = Phase.SETUP


func is_sar() -> bool:
	return config.trick_mode != "simple"


func team_of(player: int) -> int:
	return player % 2


static func partner_of(player: int) -> int:
	return (player + 2) % 4


static func next_seat(player: int) -> int:
	return (player + 1) % 4


# --- round flow ----------------------------------------------------------------

## Shuffles and deals the first 5 cards to everyone (caller first).
## Returns the deal sequence [[player, CardData], ...].
func start_round() -> Array:
	round_number += 1
	dealer = next_seat(dealer)
	caller = next_seat(dealer)
	trump = -1
	trick.clear()
	tricks_played = 0
	team_tricks = [0, 0]
	pile = 0
	last_winner = -1
	court_team = -1
	round_summary = {}
	played.clear()
	voids = [{}, {}, {}, {}]
	hands = [[], [], [], []]
	deck.reset()
	deck.shuffle(rng)

	var seq: Array = []
	for i in FIRST_DEAL:
		for k in 4:
			var p := (caller + k) % 4
			var c := deck.draw()
			hands[p].append(c)
			seq.append([p, c])
	# Remaining 8 each are dealt after trump is chosen, in two packets of 4.
	_pending_deal.clear()
	for packet in 2:
		for k in 4:
			var p := (caller + k) % 4
			for i in 4:
				_pending_deal.append([p, deck.draw()])
	phase = Phase.BIDDING
	return seq


## Caller picks trump. Returns the rest of the deal sequence.
func choose_trump(player: int, suit: int) -> Array:
	assert(phase == Phase.BIDDING and player == caller)
	trump = suit
	for entry in _pending_deal:
		hands[entry[0]].append(entry[1])
	var seq := _pending_deal.duplicate()
	_pending_deal.clear()
	leader = caller
	current = caller
	phase = Phase.PLAY
	return seq


func get_current_player() -> int:
	return current


func led_suit() -> int:
	return trick[0].card.suit if not trick.is_empty() else -1


func get_valid_moves(player: int) -> Array[CardData]:
	var out: Array[CardData] = []
	if phase != Phase.PLAY or player != current:
		return out
	var hand: Array = hands[player]
	var led := led_suit()
	if led >= 0:
		for c in hand:
			if c.suit == led:
				out.append(c)
	if out.is_empty():
		for c in hand:
			out.append(c)
	return out


## Does card a beat card b given the led suit and trump?
func beats(a: CardData, b: CardData, led: int) -> bool:
	if a.suit == b.suit:
		return a.rank > b.rank
	if a.suit == trump:
		return true
	if b.suit == trump:
		return false
	return a.suit == led and b.suit != led


## Current winning entry of the trick in progress: { player, card } or {}.
func trick_winner() -> Dictionary:
	if trick.is_empty():
		return {}
	var best: Dictionary = trick[0]
	var led := led_suit()
	for e in trick:
		if beats(e.card, best.card, led):
			best = e
	return best


func play_card(player: int, card: CardData) -> Dictionary:
	assert(phase == Phase.PLAY and player == current, "Not this player's turn")
	assert(is_valid_move(player, card), "Illegal card %s" % card)
	var hand: Array = hands[player]
	for i in hand.size():
		if hand[i].id() == card.id():
			hand.remove_at(i)
			break
	var led := led_suit()
	if led >= 0 and card.suit != led:
		voids[player][led] = true
	trick.append({"player": player, "card": card})
	played[card.id()] = true

	var ev := {"player": player, "card": card, "trick_complete": false}
	if trick.size() < 4:
		current = next_seat(current)
		return ev

	# --- trick complete -------------------------------------------------------
	var win: Dictionary = trick_winner()
	var winner: int = win.player
	var team := team_of(winner)
	tricks_played += 1
	ev.trick_complete = true
	ev.winner = winner
	ev.winning_card = win.card
	ev.trick = trick.duplicate()
	ev.trumped = win.card.suit == trump and led != trump
	ev.collected = 0
	ev.court = false

	if is_sar():
		pile += 1
		var streak := false
		if last_winner >= 0:
			streak = (winner == last_winner) if config.sar_pair == "player" else (team_of(winner) == team_of(last_winner))
		var ace_block: bool = config.trick_mode == "sar_no_ace" and win.card.rank == CardData.ACE
		if tricks_played == HAND_SIZE or (streak and not ace_block):
			team_tricks[team] += pile
			ev.collected = pile
			pile = 0
			last_winner = -1
		else:
			last_winner = winner
	else:
		team_tricks[team] += 1
		ev.collected = 1

	ev.pile = pile
	ev.team_tricks = team_tricks.duplicate()
	_check_court(team, ev)

	trick.clear()
	leader = winner
	current = winner
	if _round_finished():
		phase = Phase.ROUND_OVER
		ev.round_over = true
	else:
		ev.round_over = false
	return ev


func _check_court(team: int, ev: Dictionary) -> void:
	var other := 1 - team
	if team_tricks[team] >= TRICKS_TO_WIN and team_tricks[other] == 0 and court_team == -1:
		court_team = team
		ev.court = true


func _round_finished() -> bool:
	if tricks_played >= HAND_SIZE:
		return true
	if is_sar():
		return false  # Sar always plays out all 13 tricks
	# Simple: a team with 7 wins, unless it is chasing a Bavan (all 13).
	for t in 2:
		if team_tricks[t] >= TRICKS_TO_WIN:
			if court_team == t and team_tricks[1 - t] == 0:
				return false
			return true
	return false


## Scores the finished round and advances the match.
func score_round() -> Dictionary:
	var winner_team := 0 if team_tricks[0] > team_tricks[1] else 1
	var court := court_team == winner_team
	var bavan: bool = court and team_tricks[winner_team] == HAND_SIZE
	var pts := 1
	if bavan:
		pts = int(config.court_points) * 2
	elif court:
		pts = int(config.court_points)
	scores[winner_team] += pts
	round_summary = {
		"winner_team": winner_team,
		"tricks": team_tricks.duplicate(),
		"court": court,
		"bavan": bavan,
		"points": pts,
		"scores": scores.duplicate(),
		"caller": caller,
		"trump": trump,
	}
	phase = Phase.GAME_OVER if scores[winner_team] >= int(config.target) else Phase.ROUND_OVER
	return round_summary


func get_winner() -> int:
	if phase != Phase.GAME_OVER:
		return -1
	return 0 if scores[0] > scores[1] else 1


## Cards of a suit not yet played (and not in `exclude`).
func unplayed_in_suit(suit: int) -> Array:
	var out: Array = []
	for r in range(2, 15):
		var cid := suit * 13 + (r - 2)
		if not played.has(cid):
			out.append(r)
	return out
