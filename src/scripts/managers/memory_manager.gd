extends Node

signal memory_collected(data: MemoryCrystalData)
signal memory_sequence_started(data: MemoryCrystalData)
signal memory_sequence_finished(data: MemoryCrystalData)
signal all_memories_collected

const TOTAL_MEMORIES := 10
var memories: Dictionary = {}
var collected_ids: Array[StringName] = []
var memory_complete := false

func _ready() -> void:
	for index in range(1, TOTAL_MEMORIES + 1):
		var data := load("res://src/resources/memories/memory_%02d.tres" % index) as MemoryCrystalData
		if data != null and data.is_configured(): memories[data.crystal_id] = data
		else: push_warning("Memory %02d could not be loaded." % index)
	for value in SaveManager.current_data.get("collected_crystal_ids", []): collected_ids.append(StringName(value))
	memory_complete = bool(SaveManager.current_data.get("memory_complete", false))

func can_collect(id: StringName) -> bool:
	if not memories.has(id) or collected_ids.has(id): return false
	var data: MemoryCrystalData = memories[id]
	for condition in data.unlock_conditions:
		if not collected_ids.has(condition): return false
	return true

func collect_memory(id: StringName) -> bool:
	if not can_collect(id): return false
	collected_ids.append(id)
	collected_ids.sort()
	var data: MemoryCrystalData = memories[id]
	memory_collected.emit(data)
	if collected_ids.size() >= TOTAL_MEMORIES:
		memory_complete = true
		all_memories_collected.emit()
	SaveManager.save_game()
	return true

func is_collected(id: StringName) -> bool: return collected_ids.has(id)
func get_collected_ids() -> Array[StringName]: return collected_ids.duplicate()
func get_collected_count() -> int: return collected_ids.size()
func get_memory(id: StringName) -> MemoryCrystalData: return memories.get(id) as MemoryCrystalData
func get_memory_by_index(index: int) -> MemoryCrystalData: return get_memory(StringName("memory_%02d" % index))

func unlock_memory(index: int) -> void:
	if OS.is_debug_build(): collect_memory(StringName("memory_%02d" % index))
func unlock_all_memories() -> void:
	if OS.is_debug_build():
		for index in range(1, TOTAL_MEMORIES + 1): collect_memory(StringName("memory_%02d" % index))
func clear_memories() -> void:
	if OS.is_debug_build():
		collected_ids.clear(); memory_complete = false; SaveManager.save_game()
