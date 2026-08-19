class_name MemoryGalleryItem
extends Button


signal memory_selected(data: Resource)

var memory_data: Resource
@onready var thumbnail: TextureRect = $Thumbnail
@onready var locked_overlay: ColorRect = $LockedOverlay
@onready var question_mark: Label = $LockedOverlay/QuestionMark
@onready var number_label: Label = $Number

func _ready() -> void:
	pressed.connect(_on_pressed)
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_focus_from_mouse)

func _focus_from_mouse() -> void:
	if not disabled:
		grab_focus()

func setup(data: Resource, unlocked: bool, label_override := "") -> void:
	memory_data = data
	number_label.text = label_override if not label_override.is_empty() else "%02d" % data.memory_index
	locked_overlay.visible = not unlocked
	disabled = not unlocked
	thumbnail.texture = null
	if unlocked:
		var images: Array[Texture2D] = data.get_active_images() if data is MemoryCrystalData else data.memory_images
		if images.is_empty() or images[0] == null:
			push_warning("Gallery thumbnail is missing.")
			locked_overlay.visible = true
			question_mark.text = "?"
		else:
			thumbnail.texture = images[0]

func _on_pressed() -> void:
	if not disabled and memory_data != null: memory_selected.emit(memory_data)
