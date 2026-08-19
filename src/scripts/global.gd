extends Node

enum GameMode { NORMAL, HARD }

var is_mobile_web = false
var show_jump_bar = true
var pending_ending: StringName = &""
var current_game_mode: GameMode = GameMode.NORMAL

func set_game_mode(mode: GameMode) -> void:
	current_game_mode = mode
	show_jump_bar = mode == GameMode.NORMAL

func is_hard_mode() -> bool:
	return current_game_mode == GameMode.HARD
