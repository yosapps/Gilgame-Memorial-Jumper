extends Node2D

const ITEM_SCENE := preload("res://src/scenes/memory_gallery_item.tscn")
const ITEMS_PER_SPREAD := 4
const ITEMS_PER_PAGE := 2

@export_range(0.1, 2.0, 0.05) var entrance_fade_duration := 0.55
@export_range(0.1, 2.0, 0.05) var exit_fade_duration := 0.55
@export_range(0.1, 2.0, 0.05) var book_open_duration := 0.75
@export_range(0.1, 1.5, 0.05) var page_turn_duration := 0.42

@onready var ui: CanvasLayer = $UI
@onready var book: Control = $UI/Book
@onready var spread: Control = $UI/Book/Spread
@onready var cover: PanelContainer = $UI/Book/Cover
@onready var left_grid: GridContainer = $UI/Book/Spread/LeftPage/LeftGrid
@onready var right_grid: GridContainer = $UI/Book/Spread/RightPage/RightGrid
@onready var left_page_number: Label = $UI/Book/Spread/LeftPage/PageNumber
@onready var right_page_number: Label = $UI/Book/Spread/RightPage/PageNumber
@onready var previous_button: Button = $UI/Book/Spread/PreviousButton
@onready var next_button: Button = $UI/Book/Spread/NextButton
@onready var page_turn: Panel = $UI/Book/PageTurn
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var cutscene: CanvasLayer = $MemoryCutscene

var entries: Array[Dictionary] = []
var spread_index := 0
var spread_count := 1
var animating := true
var selected_item: Control

func _ready() -> void:
	GameTimeManager.stop_run()
	_build_entries()
	spread_count = maxi(1, ceili(float(entries.size()) / ITEMS_PER_SPREAD))
	_prepare_initial_state()
	await _play_entrance()
	_render_spread()
	await _open_book()
	animating = false
	_focus_first_available()

func _build_entries() -> void:
	entries.clear()
	for data in MemoryManager.get_all_memories():
		entries.append({
			"data": data,
			"unlocked": MemoryManager.is_collected(data.crystal_id),
			"label": "%02d" % data.memory_index,
			"ending": false,
		})
	for data in EndingManager.get_gallery_endings():
		entries.append({
			"data": data,
			"unlocked": EndingManager.is_ending_unlocked(data.ending_id),
			"label": data.gallery_label,
			"ending": true,
		})

func _prepare_initial_state() -> void:
	fade_overlay.show()
	fade_overlay.modulate.a = 1.0
	spread.modulate.a = 0.0
	spread.scale = Vector2(0.04, 0.96)
	cover.show()
	cover.modulate.a = 1.0
	cover.scale = Vector2(0.82, 0.88)
	page_turn.hide()
	_set_navigation_enabled(false)

func _play_entrance() -> void:
	var fade := create_tween()
	fade.tween_property(fade_overlay, "modulate:a", 0.0, entrance_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade.finished
	fade_overlay.hide()

func _open_book() -> void:
	var settle := create_tween().set_parallel(true)
	settle.tween_property(cover, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(cover, "rotation", deg_to_rad(-1.2), 0.28)
	await settle.finished
	var opening := create_tween().set_parallel(true)
	opening.tween_property(cover, "scale:x", 0.04, book_open_duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	opening.tween_property(cover, "modulate:a", 0.0, book_open_duration * 0.42).set_delay(book_open_duration * 0.18)
	opening.tween_property(spread, "scale", Vector2.ONE, book_open_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(book_open_duration * 0.25)
	opening.tween_property(spread, "modulate:a", 1.0, book_open_duration * 0.55).set_delay(book_open_duration * 0.25)
	await opening.finished
	cover.hide()
	_set_navigation_enabled(true)

func _render_spread() -> void:
	_clear_grid(left_grid)
	_clear_grid(right_grid)
	var start := spread_index * ITEMS_PER_SPREAD
	for local_index in ITEMS_PER_SPREAD:
		var entry_index := start + local_index
		if entry_index >= entries.size():
			break
		var target_grid := left_grid if local_index < ITEMS_PER_PAGE else right_grid
		_add_entry(target_grid, entries[entry_index])
	left_page_number.text = "%d" % (spread_index * 2 + 1)
	right_page_number.text = "%d" % (spread_index * 2 + 2)
	previous_button.visible = spread_index > 0
	next_button.visible = spread_index < spread_count - 1

func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

func _add_entry(grid: GridContainer, entry: Dictionary) -> void:
	var item := ITEM_SCENE.instantiate() as MemoryGalleryItem
	grid.add_child(item)
	item.custom_minimum_size = Vector2(350.0, 158.0)
	item.setup(entry.data, bool(entry.unlocked), String(entry.label))
	if bool(entry.ending):
		item.memory_selected.connect(_play_ending.bind(item))
	else:
		item.memory_selected.connect(_play_memory.bind(item))

func next_spread() -> void:
	if animating or spread_index >= spread_count - 1:
		return
	_play_click()
	await _turn_page(1)

func previous_spread() -> void:
	if animating or spread_index <= 0:
		return
	_play_click()
	await _turn_page(-1)

func _turn_page(direction: int) -> void:
	animating = true
	_set_navigation_enabled(false)
	page_turn.show()
	page_turn.modulate.a = 0.96
	page_turn.pivot_offset = Vector2(0.0 if direction > 0 else page_turn.size.x, page_turn.size.y * 0.5)
	page_turn.scale = Vector2.ONE
	page_turn.position.x = 502.0 if direction > 0 else 32.0
	var fold := create_tween().set_parallel(true)
	fold.tween_property(page_turn, "scale:x", 0.04, page_turn_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fold.tween_property(spread, "modulate", Color(0.82, 0.75, 0.64, 1.0), page_turn_duration * 0.5)
	await fold.finished
	spread_index += direction
	_render_spread()
	page_turn.position.x = 32.0 if direction > 0 else 502.0
	page_turn.pivot_offset = Vector2(page_turn.size.x if direction > 0 else 0.0, page_turn.size.y * 0.5)
	page_turn.scale.x = 0.04
	var unfold := create_tween().set_parallel(true)
	unfold.tween_property(page_turn, "scale:x", 1.0, page_turn_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	unfold.tween_property(page_turn, "modulate:a", 0.0, page_turn_duration * 0.5)
	unfold.tween_property(spread, "modulate", Color.WHITE, page_turn_duration * 0.5)
	await unfold.finished
	page_turn.hide()
	animating = false
	_set_navigation_enabled(true)
	_focus_first_available()

func _play_memory(data: MemoryCrystalData, item: Control) -> void:
	if animating: return
	selected_item = item
	ui.hide()
	await cutscene.play_memory(data)
	ui.show()
	if is_instance_valid(selected_item): selected_item.grab_focus()

func _play_ending(data: EndingData, item: Control) -> void:
	if animating: return
	selected_item = item
	ui.hide()
	await cutscene.play_sequence(data, false)
	ui.show()
	if is_instance_valid(selected_item): selected_item.grab_focus()

func _set_navigation_enabled(enabled: bool) -> void:
	previous_button.disabled = not enabled
	next_button.disabled = not enabled
	$UI/BackButton.disabled = not enabled

func _focus_first_available() -> void:
	for grid in [left_grid, right_grid]:
		for child in grid.get_children():
			if child is Button and not child.disabled:
				child.grab_focus()
				return
	if next_button.visible: next_button.grab_focus()
	elif previous_button.visible: previous_button.grab_focus()
	else: $UI/BackButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if cutscene.playing or animating:
		return
	if event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") and next_button.visible:
		next_spread()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") and previous_button.visible:
		previous_spread()
		get_viewport().set_input_as_handled()

func go_back() -> void:
	if animating: return
	animating = true
	_set_navigation_enabled(false)
	_play_click()
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_overlay.show()
	var fade := create_tween()
	fade.tween_property(fade_overlay, "modulate:a", 1.0, exit_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade.finished
	Global.request_title_without_fade()
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")

func _play_click() -> void:
	if not ClickSound.playing:
		ClickSound.play()
