extends Node

signal save_data_reset

const SAVE_VERSION := 3
const SAVE_PATH := "user://gilgame_memory_jumper_save.json"

var current_data: Dictionary = _default_data()

func _ready() -> void:
	load_game()

func _default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"collected_crystal_ids": [],
		"memory_complete": false,
		"play_time": 0.0,
		"best_completion_time": -1.0,
		"endings_unlocked": [],
		"opening_cutscene_seen": false,
		"highest_stage_unlocked": 1,
		"completed_stage_ids": [],
	}

func has_seen_opening() -> bool:
	return bool(current_data.get("opening_cutscene_seen", false))

func mark_opening_seen() -> bool:
	current_data.opening_cutscene_seen = true
	return save_game()

func unlock_stage(stage_index: int) -> void:
	current_data.highest_stage_unlocked = maxi(int(current_data.get("highest_stage_unlocked", 0)), clampi(stage_index, 0, 10))
	save_game()

func complete_stage(stage_id: StringName, next_stage_index: int) -> void:
	var completed: Array = current_data.get("completed_stage_ids", [])
	if not completed.has(String(stage_id)): completed.append(String(stage_id))
	current_data.completed_stage_ids = completed
	current_data.highest_stage_unlocked = maxi(int(current_data.get("highest_stage_unlocked", 0)), clampi(next_stage_index, 0, 10))
	save_game()

func get_gameplay_start_scene() -> String:
	var stage := clampi(int(current_data.get("highest_stage_unlocked", 0)), 0, 10)
	return "res://src/scenes/stages/memory/memory_stage_%d.tscn" % stage

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
	current_data.save_version = SAVE_VERSION
	return current_data

func save_game() -> bool:
	if has_node("/root/MemoryManager"):
		current_data.collected_crystal_ids = MemoryManager.get_collected_ids()
		current_data.memory_complete = MemoryManager.memory_complete
	if has_node("/root/GameTimeManager"):
		current_data.play_time = GameTimeManager.get_total_seconds()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(current_data, "  "))
	return true

func reset_save() -> void:
	current_data = _default_data()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

## Reset persistent and runtime progress together for editor testing.
func reset_all_data() -> void:
	reset_save()
	var memory_manager := get_node_or_null("/root/MemoryManager")
	if memory_manager != null: memory_manager.reset_runtime_state()
	var time_manager := get_node_or_null("/root/GameTimeManager")
	if time_manager != null:
		time_manager.reset_timer()
		time_manager.stop_run()
	var global := get_node_or_null("/root/Global")
	if global != null: global.pending_ending = &""
	save_data_reset.emit()
