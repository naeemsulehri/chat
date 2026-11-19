extends Node
## Persistent player preferences.

signal changed

const PATH := "user://settings.cfg"

var language: String = "en"
var sound_on: bool = true
var difficulty: String = "medium"
## Last chosen rule options per game id: { "rang": {...} }
var game_options: Dictionary = {}


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	language = cfg.get_value("general", "language", language)
	sound_on = cfg.get_value("general", "sound_on", sound_on)
	difficulty = cfg.get_value("general", "difficulty", difficulty)
	game_options = cfg.get_value("games", "options", {})


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "language", language)
	cfg.set_value("general", "sound_on", sound_on)
	cfg.set_value("general", "difficulty", difficulty)
	cfg.set_value("games", "options", game_options)
	cfg.save(PATH)
	changed.emit()
