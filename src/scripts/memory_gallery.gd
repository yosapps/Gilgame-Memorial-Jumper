extends Node2D

const ITEM_SCENE := preload("res://src/scenes/memory_gallery_item.tscn")
@onready var grid: GridContainer = $UI/Margin/Panel/VBox/Grid
@onready var counter: Label = $UI/Margin/Panel/VBox/Counter
@onready var ending_grid: GridContainer = $UI/Margin/Panel/VBox/EndingGrid
@onready var back_button: Button = $UI/Margin/Panel/VBox/BackButton
@onready var cutscene: CanvasLayer = $MemoryCutscene
var selected_item: Control

func _ready() -> void:
	GameTimeManager.stop_run()
	_build_gallery()
	var gallery_items := grid.get_children() + ending_grid.get_children()
	var first_unlocked := gallery_items.filter(func(item: Control) -> bool: return not item.disabled)
	if first_unlocked.is_empty(): back_button.grab_focus()
	else: first_unlocked[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not cutscene.playing:
		_go_back(); get_viewport().set_input_as_handled()

func _build_gallery() -> void:
	for child in grid.get_children(): child.queue_free()
	var memories := MemoryManager.get_all_memories()
	# counter.text = "%d / %d Memories" % [MemoryManager.get_collected_count(), MemoryManager.get_total_count()]
	for data in memories:
		var item := ITEM_SCENE.instantiate() as MemoryGalleryItem
		grid.add_child(item)
		item.setup(data, MemoryManager.is_collected(data.crystal_id))
		item.memory_selected.connect(_play_memory.bind(item))
	for child in ending_grid.get_children(): child.queue_free()
	for data in EndingManager.get_gallery_endings():
		var item := ITEM_SCENE.instantiate() as MemoryGalleryItem
		ending_grid.add_child(item)
		item.setup(data, EndingManager.is_ending_unlocked(data.ending_id), data.gallery_label)
		item.memory_selected.connect(_play_ending.bind(item))

func _play_memory(data: MemoryCrystalData, item: Control) -> void:
	selected_item = item
	$UI.hide()
	await cutscene.play_memory(data)
	$UI.show()
	if is_instance_valid(selected_item): selected_item.grab_focus()

func _play_ending(data: EndingData, item: Control) -> void:
	selected_item = item
	$UI.hide()
	await cutscene.play_sequence(data, false)
	$UI.show()
	if is_instance_valid(selected_item): selected_item.grab_focus()

func _go_back() -> void:
	if !ClickSound.playing: ClickSound.play()
	Global.request_title_without_fade()
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")
