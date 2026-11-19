extends Node2D
## Visual check: every card face plus a back. Run this scene directly.

func _ready() -> void:
	var bg := FeltBackground.new()
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	layer.add_child(bg)
	var deck := Deck.new()
	for i in 52:
		var c := Card.new().setup(deck.cards[i], true)
		c.position = Vector2(60 + (i % 13) * 52, 110 + (i / 13) * 150) if i % 13 < 13 else Vector2.ZERO
		c.scale = Vector2(0.5, 0.5) if false else Vector2.ONE
		c.position = Vector2(70 + (i % 7) * 96, 90 + (i / 7) * 150)
		c.scale = Vector2(0.9, 0.9)
		add_child(c)
	var back := Card.new().setup(CardData.new(), false)
	back.position = Vector2(70 + 3 * 96, 90 + 7 * 150)
	back.scale = Vector2(0.9, 0.9)
	add_child(back)
	var g := Card.new().setup(CardData.new(1, 14), true)
	g.position = Vector2(70 + 5 * 96, 90 + 7 * 150)
	g.scale = Vector2(0.9, 0.9)
	add_child(g)
	g.set_glow(true)
