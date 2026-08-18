extends Node

func _allowed() -> bool: return OS.is_debug_build()
func unlock_memory(index: int) -> void:
	if _allowed(): MemoryManager.unlock_memory(index)
func unlock_all_memories() -> void:
	if _allowed(): MemoryManager.unlock_all_memories()
func clear_memories() -> void:
	if _allowed(): MemoryManager.clear_memories()
func set_play_time(seconds: float) -> void:
	if _allowed(): GameTimeManager.set_play_time(seconds)
func trigger_ending(id: StringName) -> void:
	if _allowed():
		Global.pending_ending = EndingManager.trigger_ending(id)
		get_tree().change_scene_to_file("res://src/scenes/ending_scene.tscn")
func reset_save() -> void:
	if _allowed():
		SaveManager.reset_all_data()
