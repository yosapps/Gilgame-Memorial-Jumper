extends CanvasLayer

signal playback_finished
var playing := false
var skip_requested := false
var player: Node
var background: ColorRect
var image_rect: TextureRect
var subtitle: Label
var skip_label: Label
var audio: AudioStreamPlayer
var active_motion: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	background = ColorRect.new(); background.color = Color.BLACK; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	image_rect = TextureRect.new(); image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.add_child(image_rect)
	subtitle = Label.new(); subtitle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); subtitle.position = Vector2(-300, -100); subtitle.size = Vector2(600, 50); subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle.add_theme_font_size_override("font_size", 28); background.add_child(subtitle)
	skip_label = Label.new(); skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); skip_label.position = Vector2(-220, -45); skip_label.size = Vector2(200, 30); skip_label.text = "Enter  スキップ"; skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; background.add_child(skip_label)
	audio = AudioStreamPlayer.new(); add_child(audio)
	background.hide()

func _unhandled_input(event: InputEvent) -> void:
	if playing and event.is_action_pressed("ui_accept"):
		skip_requested = true
		get_viewport().set_input_as_handled()

func play_memory(data: MemoryCrystalData) -> void:
	await play_sequence(data, true)

func play_sequence(data: Resource, is_memory := false) -> void:
	if playing or data == null: return
	playing = true; skip_requested = false
	_reset_image()
	player = get_tree().get_first_node_in_group("player")
	_lock_player(true)
	GameTimeManager.pause_timer(&"memory_cutscene")
	if is_memory: MemoryManager.memory_sequence_started.emit(data)
	background.modulate.a = 0.0; background.show()
	if data.memory_music != null: audio.stream = data.memory_music; audio.play()
	await _fade(background, 1.0, data.transition_duration)
	for texture in data.memory_images:
		if skip_requested: break
		if texture == null:
			push_warning("Missing image in cinematic sequence."); continue
		image_rect.texture = texture; image_rect.modulate.a = 0.0; image_rect.scale = Vector2.ONE; image_rect.position = Vector2.ZERO
		subtitle.text = data.short_subtitle
		await _fade(image_rect, 1.0, data.transition_duration)
		active_motion = create_tween(); active_motion.set_parallel(true)
		active_motion.tween_property(image_rect, "scale", Vector2(1.04, 1.04), data.seconds_per_image).set_trans(Tween.TRANS_SINE)
		active_motion.tween_property(image_rect, "position", Vector2(-12, -7), data.seconds_per_image).set_trans(Tween.TRANS_SINE)
		await _wait_or_skip(data.seconds_per_image)
		if skip_requested: break
		await _fade(image_rect, 0.0, data.transition_duration)
	if active_motion != null and active_motion.is_valid(): active_motion.kill()
	active_motion = null
	_reset_image()
	audio.stop(); await _fade(background, 0.0, data.transition_duration)
	background.hide(); _lock_player(false)
	GameTimeManager.resume_timer(&"memory_cutscene")
	if is_memory: MemoryManager.memory_sequence_finished.emit(data)
	playing = false; playback_finished.emit()

func _fade(item: CanvasItem, alpha: float, duration: float) -> void:
	var tween := create_tween(); tween.tween_property(item, "modulate:a", alpha, duration)
	await tween.finished

func _wait_or_skip(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and not skip_requested:
		elapsed += get_process_delta_time()
		await get_tree().process_frame

func _reset_image() -> void:
	if image_rect == null: return
	image_rect.texture = null
	image_rect.modulate.a = 0.0
	image_rect.scale = Vector2.ONE
	image_rect.position = Vector2.ZERO
	if subtitle != null: subtitle.text = ""

func _lock_player(lock: bool) -> void:
	if player == null: return
	player.is_can_move = not lock
	if lock:
		player.velocity = Vector2.ZERO; player.jump_mode = false; player.jump_force = 0
		var bar := player.get_node_or_null("JumpBar"); if bar: bar.hide()
