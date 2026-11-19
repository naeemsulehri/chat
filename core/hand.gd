class_name Hand
extends Node2D
## A player's hand: owns the ordering and computes where each card sits.
## Card nodes live in a shared card layer; this node only provides an anchor
## (its position) and layout maths in the same coordinate space.

enum Layout { FAN, ROW, COLUMN }

var layout: int = Layout.FAN
var cards: Array[Card] = []
var card_scale := 1.0
var max_span := 600.0      # max length the hand may occupy
var max_spacing := 48.0
var fan_curve := 0.00016   # vertical drop per px² from centre (FAN)
var fan_angle := 0.0008    # rotation per px from centre (FAN)
var base_rotation := 0.0   # ROW / COLUMN cards are rotated by this
var z_base := 0
var selected: Card = null
var lift := 34.0


func add_card(c: Card) -> void:
	cards.append(c)


func remove_card(c: Card) -> void:
	cards.erase(c)
	if selected == c:
		selected = null


func clear() -> void:
	cards.clear()
	selected = null


func find_card(d: CardData) -> Card:
	for c in cards:
		if c.data.id() == d.id():
			return c
	return null


## Sort by suit (alternating colours) then rank. `trump` goes last if given.
func sort_cards(trump := -1) -> void:
	var order := [CardData.Suit.SPADES, CardData.Suit.HEARTS, CardData.Suit.CLUBS, CardData.Suit.DIAMONDS]
	if trump >= 0:
		order.erase(trump)
		order.append(trump)
	cards.sort_custom(func(a: Card, b: Card) -> bool:
		var sa := order.find(a.data.suit)
		var sb := order.find(b.data.suit)
		if sa != sb:
			return sa < sb
		return a.data.rank < b.data.rank)


func spacing_for(count: int) -> float:
	if count <= 1:
		return 0.0
	var len_card := Card.W * card_scale
	return minf(max_spacing, (max_span - len_card) / (count - 1))


## Target transform for card i of n: { pos, rot }
func slot(i: int, n: int) -> Dictionary:
	var sp := spacing_for(n)
	var off := (i - (n - 1) * 0.5) * sp
	match layout:
		Layout.FAN:
			var pos := position + Vector2(off, off * off * fan_curve)
			var c: Card = cards[i] if i < cards.size() else null
			if c != null and c == selected:
				pos.y -= lift
			return {"pos": pos, "rot": off * fan_angle}
		Layout.ROW:
			return {"pos": position + Vector2(off, 0), "rot": base_rotation}
		_:
			return {"pos": position + Vector2(0, off), "rot": base_rotation}


func relayout(dur := 0.3) -> void:
	var n := cards.size()
	for i in n:
		var c := cards[i]
		var s := slot(i, n)
		c.z_index = z_base + i
		c.move_to(s.pos, s.rot, card_scale, dur)


func select(c: Card) -> void:
	selected = c
	relayout(0.15)
