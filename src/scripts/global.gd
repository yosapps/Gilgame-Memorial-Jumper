extends Node

enum GameMode { NORMAL, HARD }

var is_mobile_web = false
var show_jump_bar = true
var pending_ending: StringName = &""
var current_game_mode: GameMode = GameMode.NORMAL
var skip_next_title_fade := false
## Keeps startup-threaded scenes alive in Godot's resource cache.
var startup_scene_cache: Dictionary = {}

func request_title_without_fade() -> void:
	skip_next_title_fade = true

func consume_title_fade_skip() -> bool:
	var should_skip := skip_next_title_fade
	skip_next_title_fade = false
	return should_skip

func set_game_mode(mode: GameMode) -> void:
	current_game_mode = mode
	show_jump_bar = mode == GameMode.NORMAL

func is_hard_mode() -> bool:
	return current_game_mode == GameMode.HARD
