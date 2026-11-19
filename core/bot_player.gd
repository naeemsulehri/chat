class_name BotPlayer
extends RefCounted
## Base class for computer opponents. Each game subclasses this.

enum Difficulty { EASY, MEDIUM, HARD }

var difficulty: int = Difficulty.MEDIUM
var seat: int = 0
var rng := RandomNumberGenerator.new()


func _init(p_seat: int = 0, p_difficulty: int = Difficulty.MEDIUM) -> void:
	seat = p_seat
	difficulty = p_difficulty
	rng.randomize()


static func difficulty_from_string(s: String) -> int:
	match s:
		"easy": return Difficulty.EASY
		"hard": return Difficulty.HARD
	return Difficulty.MEDIUM


## Seconds the bot "thinks" before acting, for a natural pace.
func think_time() -> float:
	return rng.randf_range(0.45, 0.85)


func pick_random(arr: Array):
	return arr[rng.randi_range(0, arr.size() - 1)]
