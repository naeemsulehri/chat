extends Node
## Scene navigation with a short fade, plus the hand-off of game config.

const MENU_SCENE := "res://ui/main_menu.tscn"
const SETUP_SCENE := "res://ui/game_setup.tscn"

var selected_game: Dictionary = {}
var game_config: Dictionary = {}

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.05, 0.04, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_schedule_screenshots()


## Dev helper: `-- --shot=/tmp/a.png@3.5` saves a screenshot after 3.5 s.
func _schedule_screenshots() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tap="):  # dev: --tap=360,1150@20 simulates a tap
			var spec2: String = arg.substr(6)
			var xy := spec2.substr(0, spec2.rfind("@")).split(",")
			var when := float(spec2.substr(spec2.rfind("@") + 1))
			get_tree().create_timer(when, true, false, true).timeout.connect(func():
				for down in [true, false]:
					var ev := InputEventMouseButton.new()
					ev.button_index = MOUSE_BUTTON_LEFT
					ev.pressed = down
					ev.position = Vector2(float(xy[0]), float(xy[1]))
					ev.global_position = ev.position
					Input.parse_input_event(ev))
			continue
		if not arg.begins_with("--shot="):
			continue
		var spec: String = arg.substr(7)
		var at := spec.rfind("@")
		var path := spec.substr(0, at)
		var secs := float(spec.substr(at + 1))
		get_tree().create_timer(secs, true, false, true).timeout.connect(func():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
			print("screenshot saved: ", path))


func goto_menu() -> void:
	_change(MENU_SCENE)


func open_setup(game: Dictionary) -> void:
	selected_game = game
	_change(SETUP_SCENE)


func start_game(config: Dictionary) -> void:
	game_config = config
	_change(selected_game.get("scene", MENU_SCENE))


func restart_game() -> void:
	_change(selected_game.get("scene", MENU_SCENE))


func _change(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.18)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.25)
	await t2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
