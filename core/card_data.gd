class_name CardData
extends RefCounted
## Pure data for a single playing card. No visuals here.

enum Suit { SPADES, HEARTS, DIAMONDS, CLUBS }

const JACK := 11
const QUEEN := 12
const KING := 13
const ACE := 14

var suit: int
var rank: int  # 2..14 (Ace high)


func _init(p_suit: int = Suit.SPADES, p_rank: int = 2) -> void:
	suit = p_suit
	rank = p_rank


## Stable integer id 0..51, handy for dictionaries and sets.
func id() -> int:
	return suit * 13 + (rank - 2)


func is_red() -> bool:
	return suit == Suit.HEARTS or suit == Suit.DIAMONDS


func is_face() -> bool:
	return rank >= JACK and rank <= KING


func rank_label() -> String:
	match rank:
		ACE: return "A"
		KING: return "K"
		QUEEN: return "Q"
		JACK: return "J"
	return str(rank)


static func suit_key(s: int) -> String:
	return "SUIT_%d" % s


static func from_id(card_id: int) -> CardData:
	return CardData.new(card_id / 13, card_id % 13 + 2)


func _to_string() -> String:
	return rank_label() + ["S", "H", "D", "C"][suit]
