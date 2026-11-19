class_name GameRegistry
extends RefCounted
## The list of games shown on the main menu. Add a game by appending an entry
## with its scene and rules script (which must extend GameRules).

static func all() -> Array:
	return [
		{
			"id": "rang", "name": "GAME_RANG", "desc": "GAME_RANG_DESC", "summary": "RULES_SUMMARY_RANG",
			"available": true, "players": 4, "suit": CardData.Suit.HEARTS, "accent": Color("e0544b"),
			"scene": "res://games/rang/rang_game.tscn",
			"rules": "res://games/rang/rang_rules.gd",
		},
		{
			"id": "seep", "name": "GAME_SEEP", "desc": "GAME_SEEP_DESC",
			"available": false, "suit": CardData.Suit.SPADES, "accent": Color("5cc8ff"),
		},
		{
			"id": "poker", "name": "GAME_POKER", "desc": "GAME_POKER_DESC",
			"available": false, "suit": CardData.Suit.DIAMONDS, "accent": Color("f2c14e"),
		},
		{
			"id": "bluff", "name": "GAME_BLUFF", "desc": "GAME_BLUFF_DESC",
			"available": false, "suit": CardData.Suit.CLUBS, "accent": Color("7ee081"),
		},
		{
			"id": "daketi", "name": "GAME_DAKETI", "desc": "GAME_DAKETI_DESC",
			"available": false, "suit": CardData.Suit.SPADES, "accent": Color("c792ea"),
		},
	]


static func get_game(id: String) -> Dictionary:
	for g in all():
		if g.id == id:
			return g
	return {}
