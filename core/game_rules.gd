class_name GameRules
extends RefCounted
## Common interface every game module implements.
##
## A game screen drives a GameRules object; the rules object never touches
## visuals. That keeps rules testable headlessly and lets bots reuse them.

enum Phase { SETUP, DEALING, BIDDING, PLAY, ROUND_OVER, GAME_OVER }

var config: Dictionary = {}
var phase: int = Phase.SETUP
var num_players: int = 4
var rng := RandomNumberGenerator.new()


## Options shown on the generic setup screen before a match.
## Each entry: { id, label, default, choices: [{ value, label, desc? }], show_if? }
static func get_options() -> Array:
	return []


## Apply the chosen options and reset the match.
func setup(p_config: Dictionary) -> void:
	config = p_config.duplicate()


## Start a new round. Returns the deal sequence: Array of [player, CardData].
func start_round() -> Array:
	return []


func get_current_player() -> int:
	return -1


## Cards the given player may legally play right now.
func get_valid_moves(_player: int) -> Array[CardData]:
	return []


func is_valid_move(player: int, card: CardData) -> bool:
	for c in get_valid_moves(player):
		if c.id() == card.id():
			return true
	return false


## Play a card. Returns a dictionary of events for the UI to animate.
func play_card(_player: int, _card: CardData) -> Dictionary:
	return {}


func is_round_over() -> bool:
	return phase == Phase.ROUND_OVER or phase == Phase.GAME_OVER


## Score the finished round. Returns a summary dictionary.
func score_round() -> Dictionary:
	return {}


func is_game_over() -> bool:
	return phase == Phase.GAME_OVER


## Winning player or team index, or -1 if the game is not over.
func get_winner() -> int:
	return -1


## Team index of a player (games without teams return the player index).
func team_of(player: int) -> int:
	return player
