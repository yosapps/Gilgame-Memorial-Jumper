class_name NpcDialogueProfile
extends Resource

@export_category("Identity")
@export var profile_id: StringName
@export var display_name := ""
@export var thumbnail: Texture2D

@export_category("Dialogue")
## Empty means that the dialogue set directly on the NPC instance is used.
@export_multiline var dialogue: Array[String] = []

@export_category("Portrait Display")
@export var portrait_size := Vector2(420.0, 420.0)
@export var portrait_screen_offset := Vector2(0.0, -28.0)
@export var portrait_modulate := Color.WHITE

@export_category("Development")
@export_multiline var developer_description := ""
