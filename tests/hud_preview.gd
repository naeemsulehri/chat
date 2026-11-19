extends Node2D
## Visual check of HUD overlays. User args: --overlay=result|over|pause|picker

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	layer.add_child(FeltBackground.new())
	var hud := TableHUD.new()
	add_child(hud)
	hud.setup_seats([{"seat": 0, "name": "NAME_0", "team": 0}, {"seat": 1, "name": "NAME_1", "team": 1}, {"seat": 2, "name": "NAME_2", "team": 0, "sub": "PARTNER"}, {"seat": 3, "name": "NAME_3", "team": 1}])
	hud.set_target(7)
	hud.set_scores([4, 2])
	hud.set_tricks([7, 0], 3)
	hud.set_trump(1)
	hud.set_dealer(3)
	var vs := get_viewport_rect().size
	hud.layout(vs, {0: Vector2(360, vs.y - 300), 1: Vector2(708, 700), 2: Vector2(360, 180), 3: Vector2(12, 700)}, {0: 0, 1: 1, 2: 0, 3: -1}, vs.y - 400, 260)
	hud.set_turn(0)
	var mode := "result"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--overlay="):
			mode = a.substr(10)
	match mode:
		"result":
			hud.show_round_result(true, "ROUND_WON", ["COURT!", "Tricks 7 – 0  ·  +2 points"], [6, 2])
			Effects.confetti(self, Vector2(360, vs.y + 40), 120)
		"over":
			hud.show_game_over(0, [7, 3], func(): pass, func(): pass)
		"pause":
			hud.show_pause(func(): pass, func(): pass, func(): pass)
		"picker":
			hud.open_choices("MSG_CHOOSE_TRUMP", [{"value": 0, "label": "SUIT_0", "suit": 0}, {"value": 1, "label": "SUIT_1", "suit": 1}, {"value": 3, "label": "SUIT_3", "suit": 3}, {"value": 2, "label": "SUIT_2", "suit": 2}])
