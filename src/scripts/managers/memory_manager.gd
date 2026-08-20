extends Node

signal memory_collected(data: MemoryCrystalData)
signal memory_sequence_started(data: MemoryCrystalData)
signal memory_sequence_finished(data: MemoryCrystalData)
signal all_memories_collected

## Keep explicit references so Resources remain discoverable in exported builds.
## Directory enumeration can expose exported files as `.tres.remap` instead of `.tres`.
const MEMORY_RESOURCES := [
	preload("res://src/resources/memories/memory_01.tres"),
	preload("res://src/resources/memories/memory_02.tres"),
	preload("res://src/resources/memories/memory_03.tres"),
	preload("res://src/resources/memories/memory_04.tres"),
	preload("res://src/resources/memories/memory_05.tres"),
	preload("res://src/resources/memories/memory_06.tres"),
	preload("res://src/resources/memories/memory_07.tres"),
	preload("res://src/resources/memories/memory_08.tres"),
	preload("res://src/resources/memories/memory_09.tres"),
	preload("res://src/resources/memories/memory_10.tres"),
]
var memories: Dictionary = {}
var collected_ids: Array[StringName] = []
var memory_complete := false

func _ready() -> void:
	for resource in MEMORY_RESOURCES:
		var data := resource as MemoryCrystalData
		if data != null and data.is_configured():
			memories[data.crystal_id] = data
		else:
			push_warning("Memory Resource is missing or incorrectly configured.")
	reload_active_progress()

func reload_active_progress() -> void:
	collected_ids.clear()
	var progress := SaveManager.get_active_progress()
	for value in progress.get("collected_crystal_ids", []): collected_ids.append(StringName(value))
	memory_complete = bool(progress.get("memory_complete", false))

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
	if not memories.is_empty() and collected_ids.size() >= memories.size():
		memory_complete = true
		all_memories_collected.emit()
	SaveManager.save_game()
	return true

func is_collected(id: StringName) -> bool: return collected_ids.has(id)
func get_collected_ids() -> Array[StringName]: return collected_ids.duplicate()
func get_collected_count() -> int: return collected_ids.size()
func get_total_count() -> int: return memories.size()
func get_memory(id: StringName) -> MemoryCrystalData: return memories.get(id) as MemoryCrystalData
func get_memory_by_index(index: int) -> MemoryCrystalData:
	for data in memories.values():
		if (data as MemoryCrystalData).memory_index == index: return data as MemoryCrystalData
	return null
func get_all_memories() -> Array[MemoryCrystalData]:
	var result: Array[MemoryCrystalData] = []
	for value in memories.values(): result.append(value as MemoryCrystalData)
	result.sort_custom(func(a: MemoryCrystalData, b: MemoryCrystalData) -> bool: return a.memory_index < b.memory_index)
	return result

func reset_runtime_state() -> void:
	collected_ids.clear()
	memory_complete = false

func unlock_memory(index: int) -> void:
	if OS.is_debug_build(): collect_memory(StringName("memory_%02d" % index))
func unlock_all_memories() -> void:
	if OS.is_debug_build():
		for data in get_all_memories(): collect_memory(data.crystal_id)
func clear_memories() -> void:
	if OS.is_debug_build():
		reset_runtime_state(); SaveManager.save_game()
