extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://gilgame_memory_jumper_save.json"

var current_data: Dictionary = _default_data()

func _ready() -> void:
	load_game()

func _default_data() -> Dictionary:
	return {"save_version": SAVE_VERSION, "collected_crystal_ids": [], "memory_complete": false, "play_time": 0.0, "best_completion_time": -1.0, "endings_unlocked": []}

func load_game() -> Dictionary:
	current_data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH): return current_data
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return current_data
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Save data is corrupted; using defaults.")
		return current_data
	for key in current_data.keys():
		if parsed.has(key): current_data[key] = parsed[key]
	return current_data

func save_game() -> bool:
	if has_node("/root/MemoryManager"):
		current_data.collected_crystal_ids = MemoryManager.get_collected_ids()
		current_data.memory_complete = MemoryManager.memory_complete
	if has_node("/root/GameTimeManager"): current_data.play_time = GameTimeManager.get_total_seconds()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(current_data, "  "))
	return true

func reset_save() -> void:
	current_data = _default_data()
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
