class_name MemoryCrystalData
extends Resource

## メモリー結晶の編集用データ。
## 収集状況の正本は将来のMemoryManager/SaveManagerがID単位で保持します。

@export_category("Identity")
@export var crystal_id: StringName
@export_range(1, 999, 1, "or_greater") var memory_index := 1
@export var display_name := "Memory"
@export_multiline var developer_description := ""
@export var associated_dungeon_area: StringName

@export_category("Visual Story")
@export var memory_images: Array[Texture2D] = []
## 仮画像をResource参照せず、アーティスト向けの配置予定先だけ記録します。
@export var expected_image_paths: PackedStringArray = []
@export_multiline var short_subtitle := ""
@export_range(0.5, 30.0, 0.1, "or_greater") var seconds_per_image := 4.0
@export_range(0.1, 5.0, 0.1, "or_greater") var transition_duration := 1.0

@export_category("Optional Audio")
@export var ambient_sound: AudioStream
@export var collection_sound: AudioStream
@export var memory_music: AudioStream

@export_category("Unlocking")
## 通常はfalse。デバッグや特殊な初期状態にのみ使用します。
@export var collected := false
## 将来のMemoryManagerが解釈する条件ID。空なら無条件です。
@export var unlock_conditions: Array[StringName] = []


func is_configured() -> bool:
	return not crystal_id.is_empty() and memory_index > 0 and not display_name.is_empty()


func get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if crystal_id.is_empty():
		warnings.append("crystal_id is required.")
	if memory_index <= 0:
		warnings.append("memory_index must be greater than zero.")
	if display_name.is_empty():
		warnings.append("display_name is required.")
	if memory_images.is_empty():
		warnings.append("No memory images assigned; the cutscene will use visual placeholders.")
	return warnings
