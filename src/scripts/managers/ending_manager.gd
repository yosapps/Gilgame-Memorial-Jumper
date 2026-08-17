extends Node

signal ending_triggered(ending_id: StringName)
var config: EndingConfig = preload("res://src/resources/endings/default_ending_config.tres")

func determine_ending() -> StringName:
	if config.require_complete_memory and not MemoryManager.memory_complete: return &"incomplete_memory"
	var time := GameTimeManager.get_total_seconds()
	if time <= config.fast_threshold_seconds: return &"ending_a"
	if time <= config.medium_threshold_seconds: return &"ending_b"
	return &"ending_c"

func trigger_ending(id: StringName = &"") -> StringName:
	var result := determine_ending() if id.is_empty() else id
	if not OS.is_debug_build() and not id.is_empty(): result = determine_ending()
	var unlocked: Array = SaveManager.current_data.get("endings_unlocked", [])
	if not unlocked.has(String(result)): unlocked.append(String(result))
	SaveManager.current_data.endings_unlocked = unlocked
	var best := float(SaveManager.current_data.get("best_completion_time", -1.0))
	var current := GameTimeManager.get_total_seconds()
	if best < 0.0 or current < best: SaveManager.current_data.best_completion_time = current
	SaveManager.save_game()
	ending_triggered.emit(result)
	return result
