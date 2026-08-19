extends Node

signal save_data_reset

const SAVE_VERSION := 6
const SAVE_PATH := "user://gilgame_memory_jumper_save.json"
const DEFAULT_BGM_VOLUME := 0.75
const DEFAULT_SFX_VOLUME := 0.75

var current_data: Dictionary = _default_data()

func _ready() -> void:
	load_game()
	apply_audio_settings()

func _default_data() -> Dictionary:
	var data := _default_progress()
	data.merge({
		"save_version": SAVE_VERSION,
		"game_cleared_once": false,
		"hard_mode_unlocked": false,
		"bgm_volume": DEFAULT_BGM_VOLUME,
		"sfx_volume": DEFAULT_SFX_VOLUME,
		"hard_mode_progress": _default_progress(),
	})
	return data

func _default_progress() -> Dictionary:
	return {
		"collected_crystal_ids": [],
		"memory_complete": false,
		"play_time": 0.0,
		"best_completion_time": -1.0,
		"endings_unlocked": [],
		"opening_cutscene_seen": false,
		"highest_stage_unlocked": 1,
		"completed_stage_ids": [],
	}

func get_active_progress() -> Dictionary:
	if has_node("/root/Global") and Global.is_hard_mode():
		return current_data.get("hard_mode_progress", _default_progress())
	return current_data

func activate_game_mode(mode: Global.GameMode) -> void:
	Global.set_game_mode(mode)
	var memory_manager := get_node_or_null("/root/MemoryManager")
	if memory_manager != null: memory_manager.reload_active_progress()
	var time_manager := get_node_or_null("/root/GameTimeManager")
	if time_manager != null: time_manager.load_active_progress()

func has_cleared_game() -> bool:
	return bool(current_data.get("game_cleared_once", false))

func is_hard_mode_unlocked() -> bool:
	return bool(current_data.get("hard_mode_unlocked", false))

func mark_game_cleared() -> bool:
	current_data.game_cleared_once = true
	return save_game()

func unlock_hard_mode() -> bool:
	current_data.hard_mode_unlocked = true
	return save_game()

## Keeps permanent unlocks and records, but prepares the active mode for a new climb.
func prepare_active_mode_for_new_run() -> bool:
	var progress := get_active_progress()
	progress.play_time = 0.0
	progress.highest_stage_unlocked = 1
	progress.completed_stage_ids = []
	var time_manager := get_node_or_null("/root/GameTimeManager")
	if time_manager != null:
		time_manager.reset_timer()
		time_manager.stop_run()
	return save_game()

func get_normal_best_time() -> float:
	return float(current_data.get("best_completion_time", -1.0))

func get_hard_best_time() -> float:
	var hard_progress: Dictionary = current_data.get("hard_mode_progress", {})
	return float(hard_progress.get("best_completion_time", -1.0))

func get_bgm_volume() -> float:
	return clampf(float(current_data.get("bgm_volume", DEFAULT_BGM_VOLUME)), 0.0, 1.0)

func get_sfx_volume() -> float:
	return clampf(float(current_data.get("sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)

func set_bgm_volume(value: float) -> bool:
	current_data.bgm_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(&"BGM", current_data.bgm_volume)
	return _write_current_data()

func set_sfx_volume(value: float) -> bool:
	current_data.sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(&"SFX", current_data.sfx_volume)
	return _write_current_data()

func apply_audio_settings() -> void:
	_apply_bus_volume(&"BGM", get_bgm_volume())
	_apply_bus_volume(&"SFX", get_sfx_volume())

func _apply_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Audio bus '%s' was not found." % bus_name)
		return
	var muted := linear_volume <= 0.0001
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)))

func has_seen_opening() -> bool:
	return bool(get_active_progress().get("opening_cutscene_seen", false))

func mark_opening_seen() -> bool:
	var progress := get_active_progress()
	progress.opening_cutscene_seen = true
	return save_game()

func unlock_stage(stage_index: int) -> void:
	var progress := get_active_progress()
	progress.highest_stage_unlocked = maxi(int(progress.get("highest_stage_unlocked", 0)), clampi(stage_index, 0, 10))
	save_game()

func complete_stage(stage_id: StringName, next_stage_index: int) -> void:
	var progress := get_active_progress()
	var completed: Array = progress.get("completed_stage_ids", [])
	if not completed.has(String(stage_id)): completed.append(String(stage_id))
	progress.completed_stage_ids = completed
	progress.highest_stage_unlocked = maxi(int(progress.get("highest_stage_unlocked", 0)), clampi(next_stage_index, 0, 10))
	save_game()

func get_gameplay_start_scene() -> String:
	var stage := clampi(int(get_active_progress().get("highest_stage_unlocked", 0)), 0, 10)
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
	var hard_progress := _default_progress()
	var saved_hard = current_data.get("hard_mode_progress", {})
	if saved_hard is Dictionary:
		for key in hard_progress.keys():
			if saved_hard.has(key): hard_progress[key] = saved_hard[key]
	current_data.hard_mode_progress = hard_progress
	current_data.save_version = SAVE_VERSION
	return current_data

func save_game() -> bool:
	var progress := get_active_progress()
	if has_node("/root/MemoryManager"):
		progress.collected_crystal_ids = MemoryManager.get_collected_ids()
		progress.memory_complete = MemoryManager.memory_complete
	if has_node("/root/GameTimeManager"):
		progress.play_time = GameTimeManager.get_total_seconds()
	return _write_current_data()

func _write_current_data() -> bool:
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
	apply_audio_settings()
	var memory_manager := get_node_or_null("/root/MemoryManager")
	if memory_manager != null: memory_manager.reset_runtime_state()
	var time_manager := get_node_or_null("/root/GameTimeManager")
	if time_manager != null:
		time_manager.reset_timer()
		time_manager.stop_run()
	var global := get_node_or_null("/root/Global")
	if global != null:
		global.pending_ending = &""
		global.set_game_mode(global.GameMode.NORMAL)
	save_data_reset.emit()
