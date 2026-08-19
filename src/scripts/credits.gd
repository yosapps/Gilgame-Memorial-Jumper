extends Control

const CREDITS_DATA: CreditsData = preload("res://src/resources/credits/default_credits.tres")
const HARD_MODE_POPUP_SCENE := preload("res://src/scenes/ui/hard_mode_unlock_popup.tscn")

var image_a: TextureRect
var image_b: TextureRect
var current_image: TextureRect
var next_image: TextureRect
var roll: RichTextLabel
var fade_overlay: ColorRect
var skip_requested := false
var credits_running := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameTimeManager.stop_run()
	_build_ui()
	var images := _build_background_sequence()
	_background_loop(images)
	await get_tree().process_frame
	await _scroll_credits()
	credits_running = false
	await _fade_to_black()
	var completed_full_ending := Global.pending_ending in [&"ending_a", &"ending_b", &"ending_c"]
	var newly_unlocked := completed_full_ending and not SaveManager.is_hard_mode_unlocked()
	if newly_unlocked:
		SaveManager.unlock_hard_mode()
		await _show_hard_mode_popup()
	_return_to_title()

func _unhandled_input(event: InputEvent) -> void:
	if credits_running and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		skip_requested = true
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	image_a = _make_background_image()
	image_b = _make_background_image()
	add_child(image_a)
	add_child(image_b)
	current_image = image_a
	next_image = image_b
	var dark := ColorRect.new()
	dark.color = Color(0.015, 0.025, 0.05, 0.58)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)
	roll = RichTextLabel.new()
	roll.bbcode_enabled = true
	roll.fit_content = true
	roll.scroll_active = false
	roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll.position = Vector2(size.x * 0.17, size.y + CREDITS_DATA.starting_offset)
	roll.size = Vector2(size.x * 0.66, 100.0)
	roll.text = _build_credit_text()
	add_child(roll)
	var skip := Label.new()
	skip.text = "Enter / Esc  スキップ"
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.position = Vector2(-230, -42)
	skip.size = Vector2(210, 28)
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(skip)
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 0.0
	add_child(fade_overlay)
	var music := AudioStreamPlayer.new()
	music.stream = CREDITS_DATA.credits_music
	music.bus = &"BGM"
	add_child(music)
	if music.stream != null: music.play()

func _make_background_image() -> TextureRect:
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _build_credit_text() -> String:
	var text := "[center][font_size=%d]%s[/font_size]\n\n\n" % [CREDITS_DATA.title_font_size, CREDITS_DATA.title]
	for section in CREDITS_DATA.sections:
		text += "[font_size=%d][color=#b9d8ff]%s[/color][/font_size]\n" % [CREDITS_DATA.font_size - 3, section.role]
		for person in section.names:
			text += "[font_size=%d]%s[/font_size]\n" % [CREDITS_DATA.font_size, person]
		text += "\n\n"
	for line in CREDITS_DATA.closing_lines:
		text += "\n[font_size=%d]%s[/font_size]\n" % [CREDITS_DATA.font_size + 3, line]
	return text + "[/center]"

func _build_background_sequence() -> Array[Texture2D]:
	var images: Array[Texture2D] = []
	for memory in MemoryManager.get_all_memories():
		for texture in memory.get_active_images():
			if texture != null: images.append(texture)
	var ending := EndingManager.get_ending_data(Global.pending_ending)
	if ending != null:
		for texture in ending.memory_images:
			if texture != null: images.append(texture)
	return images

func _background_loop(images: Array[Texture2D]) -> void:
	if images.is_empty(): return
	current_image.texture = images[0]
	current_image.modulate.a = 1.0
	var index := 1
	while credits_running:
		await get_tree().create_timer(CREDITS_DATA.background_image_seconds, true).timeout
		if not credits_running: return
		next_image.texture = images[index % images.size()]
		next_image.modulate.a = 0.0
		next_image.scale = Vector2(1.025, 1.025)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(next_image, "modulate:a", 1.0, CREDITS_DATA.background_crossfade_duration)
		tween.tween_property(current_image, "modulate:a", 0.0, CREDITS_DATA.background_crossfade_duration)
		tween.tween_property(next_image, "scale", Vector2.ONE, CREDITS_DATA.background_image_seconds).set_trans(Tween.TRANS_SINE)
		await tween.finished
		var swap := current_image
		current_image = next_image
		next_image = swap
		index += 1

func _scroll_credits() -> void:
	await get_tree().process_frame
	while roll.position.y + roll.size.y > CREDITS_DATA.ending_offset and not skip_requested:
		roll.position.y -= CREDITS_DATA.scroll_speed * get_process_delta_time()
		await get_tree().process_frame
	if not skip_requested:
		await get_tree().create_timer(1.5, true).timeout

func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.8)
	await tween.finished

func _show_hard_mode_popup() -> void:
	var popup := HARD_MODE_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.show_popup()
	await popup.dismissed
	popup.queue_free()

func _return_to_title() -> void:
	Global.pending_ending = &""
	SaveManager.prepare_active_mode_for_new_run()
	SaveManager.activate_game_mode(Global.GameMode.NORMAL)
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")
