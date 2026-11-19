class_name Deck
extends RefCounted
## A standard 52-card deck.

var cards: Array[CardData] = []


func _init() -> void:
	reset()


func reset() -> void:
	cards.clear()
	for s in 4:
		for r in range(2, 15):
			cards.append(CardData.new(s, r))


func shuffle(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		cards.shuffle()
		return
	# Fisher-Yates with a seeded RNG (deterministic for tests/replays).
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cards[i]
		cards[i] = cards[j]
		cards[j] = tmp


func draw() -> CardData:
	return cards.pop_back()


func size() -> int:
	return cards.size()


func is_empty() -> bool:
	return cards.is_empty()
