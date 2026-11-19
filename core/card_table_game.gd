class_name CardTableGame
extends Node2D
## Base for every card-table screen: builds the felt, camera (with shake),
## card layer, effects layers, hands and HUD; provides dealing / shuffle /
## sweep animations, timing helpers, human card picking and pause/game-over.
## A game subclasses this and implements `_setup_game()` and `_run_match()`.

signal _human_card(card: CardData)
signal _continue

const HUMAN := 0
## Visual positions around the table.
enum Pos { BOTTOM, RIGHT, TOP, LEFT }

var num_seats := 4
var seat_pos: Array = [Pos.BOTTOM, Pos.RIGHT, Pos.TOP, Pos.LEFT]
var hands: Array[Hand] = []
var hud: TableHUD
var camera: ScreenShake
var card_layer: Node2D
var fx_layer: Node2D
var top_fx: CanvasLayer
var config: Dictionary = {}
var _bg: FeltBackground
var _nodes: Dictionary = {}          # card id -> Card
var _awaiting_human := false
var _vs := Vector2(720, 1280)
var _center := Vector2.ZERO
var _autoplay := false
var _speed := 1.0


# --- to implement in games ---------------------------------------------------------

## Create rules + bots from `config`; set num_seats / seat_pos if not 4 players.
func _setup_game() -> void:
	pass


## The match loop (await-based).
func _run_match() -> void:
	pass


## Tag info for a seat: { name, team, sub? }
func _seat_info(seat: int) -> Dictionary:
	return {"name": _name_key(seat), "team": seat % 2, "sub": "PARTNER" if seat == 2 else ""}


func _on_layout() -> void:
	pass


# --- setup ------------------------------------------------------------------------

func _ready() -> void:
	config = Router.game_config.duplicate()
	if config.is_empty():
		config = Settings.game_options.get(Router.selected_game.get("id", ""), {}).duplicate()
	_autoplay = config.get("autoplay", false) or "--autoplay" in OS.get_cmdline_user_args()
	if _autoplay:
		_speed = 4.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--speed="):
			_speed = float(a.substr(8))
		elif a.begins_with("--opt="):  # dev: --opt=players=2
			var kv := a.substr(6).split("=")
			config[kv[0]] = str_to_var(kv[1]) if str_to_var(kv[1]) != null else kv[1]
	_setup_game()

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	_bg = FeltBackground.new()
	bg_layer.add_child(_bg)

	camera = ScreenShake.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	card_layer = Node2D.new()
	add_child(card_layer)
	fx_layer = Node2D.new()
	fx_layer.z_index = 300
	add_child(fx_layer)

	for seat in num_seats:
		var h := Hand.new()
		h.z_base = 60 + seat * 15
		card_layer.add_child(h)
		hands.append(h)

	hud = TableHUD.new()
	add_child(hud)
	var infos := []
	for seat in num_seats:
		var info := _seat_info(seat)
		info.seat = seat
		infos.append(info)
	hud.setup_seats(infos)
	hud.next_round_pressed.connect(func(): _continue.emit())
	hud.menu_requested.connect(_open_pause)
	top_fx = CanvasLayer.new()
	top_fx.layer = 20
	add_child(top_fx)

	get_viewport().size_changed.connect(_layout)
	_layout()
	_run_match.call_deferred()


func _name_key(seat: int) -> String:
	# Name follows where the player sits: bottom You, right Bilal, top Sara, left Hamza.
	if num_seats == 2:
		return "NAME_0" if seat == 0 else "NAME_1"
	return "NAME_%d" % seat


func _name(seat: int) -> String:
	return tr(_name_key(seat))


func team_of(seat: int) -> int:
	return seat % 2


# --- layout -------------------------------------------------------------------------

func _layout() -> void:
	_vs = get_viewport_rect().size
	var w := _vs.x
	var h := _vs.y
	_center = Vector2(w * 0.5, h * 0.45)
	var anchors := {}
	var align := {}
	for seat in num_seats:
		var hd := hands[seat]
		match seat_pos[seat]:
			Pos.BOTTOM:
				hd.layout = Hand.Layout.FAN
				hd.position = Vector2(w * 0.5, h - 150)
				hd.card_scale = 1.08
				hd.max_span = w - 90
				hd.max_spacing = 56
				anchors[seat] = Vector2(w * 0.5, h - 300)
				align[seat] = 0
			Pos.RIGHT:
				hd.layout = Hand.Layout.COLUMN
				hd.position = Vector2(w - 46, h * 0.43)
				hd.card_scale = 0.5
				hd.base_rotation = -PI * 0.5
				hd.max_span = h * 0.30
				hd.max_spacing = 22
				anchors[seat] = Vector2(w - 12, h * 0.58 + 52)
				align[seat] = 1
			Pos.TOP:
				hd.layout = Hand.Layout.ROW
				hd.position = Vector2(w * 0.5, 262)
				hd.card_scale = 0.5
				hd.base_rotation = PI
				hd.max_span = w * 0.5
				hd.max_spacing = 22
				anchors[seat] = Vector2(w * 0.5, 180)
				align[seat] = 0
			Pos.LEFT:
				hd.layout = Hand.Layout.COLUMN
				hd.position = Vector2(46, h * 0.43)
				hd.card_scale = 0.5
				hd.base_rotation = PI * 0.5
				hd.max_span = h * 0.30
				hd.max_spacing = 22
				anchors[seat] = Vector2(12, h * 0.58 + 52)
				align[seat] = -1
		hd.relayout(0.2)
	hud.layout(_vs, anchors, align, h - 400, _center.y - 300)
	_on_layout()


## Point just off-screen behind a seat (where won cards fly to).
func _seat_edge(seat: int) -> Vector2:
	match seat_pos[seat]:
		Pos.BOTTOM: return Vector2(_vs.x * 0.5, _vs.y + 120)
		Pos.RIGHT: return Vector2(_vs.x + 120, _vs.y * 0.43)
		Pos.TOP: return Vector2(_vs.x * 0.5, 150)
	return Vector2(-120, _vs.y * 0.43)


## Where a seat's played card lands around the table centre.
func _play_slot(seat: int) -> Vector2:
	var off: Vector2 = [Vector2(0, 84), Vector2(92, 0), Vector2(0, -84), Vector2(-92, 0)][seat_pos[seat]]
	return _center + off


# --- helpers ------------------------------------------------------------------------

func _wait(t: float) -> void:
	await get_tree().create_timer(t / _speed, false).timeout


func _clear_table() -> void:
	for id in _nodes:
		var c: Card = _nodes[id]
		if is_instance_valid(c):
			c.queue_free()
	_nodes.clear()
	for hd in hands:
		hd.clear()


func _spawn_deck(count := 52, at := Vector2.INF) -> Array[Card]:
	if at == Vector2.INF:
		at = _center
	var arr: Array[Card] = []
	for i in count:
		var c := Card.new().setup(CardData.new(0, 2), false)
		c.position = at + Vector2(-i * 0.25, -i * 0.35)
		c.scale = Vector2(0.75, 0.75)
		c.z_index = i
		card_layer.add_child(c)
		arr.append(c)
	return arr


func _shuffle_anim(deck: Array[Card]) -> void:
	Sound.play("shuffle")
	var base: Vector2 = deck[0].position if not deck.is_empty() else _center
	for i in deck.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		deck[i].move_to(base + Vector2(side * 70, -i * 0.3), side * 0.12, 0.75, 0.18)
	await _wait(0.22)
	for i in deck.size():
		deck[i].move_to(base + Vector2(-i * 0.25, -i * 0.35), 0.0, 0.75, 0.22, i * 0.004)
	await _wait(0.45)


## Deal [[seat, CardData], ...] from the deck. Seat -1 = table: the game's
## `_deal_to_table(card, delay)` places it.
func _deal(seq: Array, deck: Array[Card], sort_human := true) -> void:
	var delay := 0.0
	var step := 0.06 / _speed
	for entry in seq:
		var seat: int = entry[0]
		var data: CardData = entry[1]
		var c: Card = deck.pop_back()
		c.data = data
		c.name = "Card_%s" % str(data)
		_nodes[data.id()] = c
		get_tree().create_timer(delay, false).timeout.connect(func(): Sound.play("deal", 0.12, -4.0))
		if seat < 0:
			_deal_to_table(c, delay)
		else:
			var hand := hands[seat]
			hand.add_card(c)
			c.z_index = hand.z_base + hand.cards.size()
			var s := hand.slot(hand.cards.size() - 1, hand.cards.size())
			c.move_to(s.pos, s.rot, hand.card_scale, 0.32 / _speed, delay, Tween.TRANS_QUART)
			if seat == HUMAN:
				c.flip_to(true, 0.24, delay + 0.2 / _speed)
		delay += step
	await _wait(delay * _speed + 0.4)
	for hd in hands:
		hd.relayout(0.25)
	if sort_human:
		_sort_human()
	hands[HUMAN].relayout(0.3)
	await _wait(0.3)


func _sort_human() -> void:
	hands[HUMAN].sort_cards()


func _deal_to_table(_c: Card, _delay: float) -> void:
	pass


## Fly cards off to a seat and free them.
func _sweep(cards: Array, seat: int) -> void:
	var dest := _seat_edge(seat)
	for i in cards.size():
		var c: Card = cards[i]
		if not is_instance_valid(c):
			continue
		var t := c.move_to(dest, 0.0, 0.4, 0.38 / _speed, i * 0.025, Tween.TRANS_CUBIC, Tween.EASE_IN)
		t.chain().tween_callback(c.queue_free)
		_nodes.erase(c.data.id())
	Sound.play("deal", 0.15, -2.0)
	await _wait(0.42)


# --- human input --------------------------------------------------------------------

## Highlight `valid` cards and wait for the human to choose one (tap to raise,
## tap again to play). Games can override `_on_human_select`.
func _human_pick(valid: Array[CardData], glow := true) -> CardData:
	_begin_human_pick(valid, glow)
	var card: CardData = await _human_card
	_end_human_pick()
	return card


func _begin_human_pick(valid: Array[CardData], glow := true) -> void:
	var valid_ids := {}
	for v in valid:
		valid_ids[v.id()] = true
	var hand := hands[HUMAN]
	for c in hand.cards:
		var ok := valid_ids.has(c.data.id())
		c.selectable = ok
		c.set_dim(not ok)
		c.set_glow(glow and ok and valid.size() < hand.cards.size(), Color("ffe07a"), 0.75)
	hud.show_hint("MSG_YOUR_TURN")
	_awaiting_human = true


func _end_human_pick() -> void:
	_awaiting_human = false
	hud.show_hint("")
	for c in hands[HUMAN].cards:
		c.selectable = false
		c.set_dim(false)
		c.set_glow(false)
	hands[HUMAN].selected = null


func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_human:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	# Use the event's own position (works for touch and mouse alike).
	var p: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * (event as InputEventMouseButton).position
	var hand := hands[HUMAN]
	var hit: Card = null
	for i in range(hand.cards.size() - 1, -1, -1):
		if hand.cards[i].hit_test(p):
			hit = hand.cards[i]
			break
	if hit == null:
		if hand.selected != null:
			hand.select(null)
			_on_human_select(null)
		return
	get_viewport().set_input_as_handled()
	if not hit.selectable:
		Sound.play("nope")
		hit.wiggle()
		_on_illegal_tap(hit)
		return
	if hand.selected == hit and _second_tap_plays():
		hand.selected = null
		_human_card.emit(hit.data)
	else:
		Sound.play("click", 0.05, -6.0)
		hand.select(hit)
		hit.shine(0.5, 0.7)
		_on_human_select(hit)


func _second_tap_plays() -> bool:
	return true


func _on_human_select(_card: Card) -> void:
	hud.show_hint("MSG_TAP_AGAIN")


func _on_illegal_tap(_card: Card) -> void:
	pass


# --- menus --------------------------------------------------------------------------

func _open_pause() -> void:
	get_tree().paused = true
	hud.show_pause(
		func():
			hud.close_overlay()
			get_tree().paused = false,
		func(): Router.restart_game(),
		func(): Router.goto_menu())


func _celebrate(big := false) -> void:
	Sound.play("win")
	if big:
		for i in 3:
			Effects.confetti(top_fx, Vector2(_vs.x * (0.2 + 0.3 * i), _vs.y + 40), 120, 260)
		camera.shake(0.5)
	else:
		Effects.confetti(top_fx, Vector2(_vs.x * 0.5, _vs.y + 40), 120)


func _show_game_over(winner_team: int, scores: Array, rounds: int) -> void:
	if winner_team == 0:
		_celebrate(true)
	else:
		Sound.play("lose")
	hud.show_game_over(winner_team, scores, func(): Router.restart_game(), func(): Router.goto_menu())
	if _autoplay:
		print("AUTOPLAY_DONE winner=%d scores=%s rounds=%d" % [winner_team, scores, rounds])
		await _wait(1.5)
		get_tree().quit()


## Wait for "Next round" (auto in autoplay).
func _await_continue() -> void:
	if _autoplay:
		await _wait(1.0)
		hud.close_overlay()
	else:
		await _continue
