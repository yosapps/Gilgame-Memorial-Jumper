extends CanvasLayer

signal playback_finished

const WATERCOLOR_SHADER := preload("res://src/shaders/memory/memory_watercolor_reveal.gdshader")
const PAPER_SHADER := preload("res://src/shaders/memory/memory_paper.gdshader")

@export_category("Watercolor Memory Effect")
@export var use_watercolor_memory_effect := true
@export_range(0.1, 6.0, 0.1) var first_brush_reveal_duration := 2.8
@export_range(0.1, 6.0, 0.1) var following_brush_reveal_duration := 1.8
@export_range(0.1, 6.0, 0.1) var wash_out_duration := 0.9
@export_range(0.001, 0.25, 0.001) var reveal_softness := 0.055
@export_range(0.0, 0.5, 0.01) var noise_strength := 0.18
@export_range(0.5, 16.0, 0.1) var noise_scale := 4.0
@export_range(0.0, 0.4, 0.01) var wet_edge_strength := 0.12
@export_range(0.0, 1.0, 0.01) var watercolor_strength := 0.32
@export var reveal_direction := Vector2(1.0, 1.0)
@export var paper_color := Color("fffdf7")

@export_category("Scene Fade")
@export_range(0.0, 3.0, 0.05) var fade_in_duration := 0.55
@export_range(0.0, 3.0, 0.05) var fade_out_duration := 0.55

var playing := false
var skip_requested := false
var player: Node
var background: ColorRect
var image_rect: TextureRect
var subtitle: Label
var skip_label: Label
var audio: AudioStreamPlayer
var active_motion: Tween
var watercolor_material: ShaderMaterial
var fade_overlay: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	background = ColorRect.new(); background.color = paper_color; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var paper_material := ShaderMaterial.new()
	paper_material.shader = PAPER_SHADER
	paper_material.set_shader_parameter("paper_color", paper_color)
	background.material = paper_material
	image_rect = TextureRect.new(); image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.add_child(image_rect)
	watercolor_material = ShaderMaterial.new()
	watercolor_material.shader = WATERCOLOR_SHADER
	_apply_watercolor_parameters()
	subtitle = Label.new(); subtitle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); subtitle.position = Vector2(-300, -100); subtitle.size = Vector2(600, 50); subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle.add_theme_font_size_override("font_size", 28); background.add_child(subtitle)
	skip_label = Label.new(); skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); skip_label.position = Vector2(-220, -45); skip_label.size = Vector2(200, 30); skip_label.text = "Enter  スキップ"; skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; background.add_child(skip_label)
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.modulate.a = 0.0
	fade_overlay.hide()
	add_child(fade_overlay)
	audio = AudioStreamPlayer.new(); add_child(audio)
	background.hide()

func _unhandled_input(event: InputEvent) -> void:
	if playing and event.is_action_pressed("ui_accept"):
		skip_requested = true
		get_viewport().set_input_as_handled()

func play_memory(data: MemoryCrystalData) -> void:
	await play_sequence(data, true)

func debug_play_memory(memory_index: int) -> void:
	if not OS.is_debug_build():
		return
	if memory_index not in [1, 6, 10]:
		push_warning("Watercolor debug playback is limited to Memory 01, 06, and 10.")
		return
	var path := "res://src/resources/memories/memory_%02d.tres" % memory_index
	var data := load(path) as MemoryCrystalData
	if data == null:
		push_warning("Could not load debug memory: %s" % path)
		return
	await play_memory(data)

func play_sequence(data: Resource, is_memory := false) -> void:
	if playing or data == null: return
	playing = true; skip_requested = false
	_reset_image()
	player = get_tree().get_first_node_in_group("player")
	_lock_player(true)
	GameTimeManager.pause_timer(&"memory_cutscene")
	if is_memory: MemoryManager.memory_sequence_started.emit(data)
	await _enter_memory_fade()
	if data.memory_music != null: audio.stream = data.memory_music; audio.play()
	var playback_images: Array[Texture2D] = data.get_active_images() if data is MemoryCrystalData else data.memory_images
	for image_index in range(playback_images.size()):
		var texture := playback_images[image_index]
		if skip_requested: break
		if texture == null:
			push_warning("Missing image in cinematic sequence."); continue
		image_rect.texture = texture; image_rect.modulate.a = 1.0 if use_watercolor_memory_effect else 0.0; image_rect.scale = Vector2.ONE; image_rect.position = Vector2.ZERO
		subtitle.text = data.short_subtitle
		if use_watercolor_memory_effect:
			image_rect.material = watercolor_material
			var reveal_duration := first_brush_reveal_duration if image_index == 0 else following_brush_reveal_duration
			if data is MemoryCrystalData and data.memory_index == 10 and image_index == playback_images.size() - 1:
				reveal_duration = maxf(reveal_duration, 3.5)
			await _animate_reveal(0.0, 1.0, reveal_duration)
		else:
			image_rect.material = null
			await _fade(image_rect, 1.0, data.transition_duration)
		if skip_requested: break
		active_motion = create_tween(); active_motion.set_parallel(true)
		active_motion.tween_property(image_rect, "scale", Vector2(1.04, 1.04), data.seconds_per_image).set_trans(Tween.TRANS_SINE)
		active_motion.tween_property(image_rect, "position", Vector2(-12, -7), data.seconds_per_image).set_trans(Tween.TRANS_SINE)
		var hold_duration: float = data.seconds_per_image
		if data is MemoryCrystalData and data.memory_index == 10 and image_index == playback_images.size() - 1:
			hold_duration += 1.0
		await _wait_or_skip(hold_duration)
		if skip_requested: break
		if use_watercolor_memory_effect:
			await _animate_reveal(1.0, 0.0, wash_out_duration)
		else:
			await _fade(image_rect, 0.0, data.transition_duration)
	if active_motion != null and active_motion.is_valid(): active_motion.kill()
	active_motion = null
	_reset_image()
	audio.stop()
	await _exit_memory_fade()
	_lock_player(false)
	GameTimeManager.resume_timer(&"memory_cutscene")
	if is_memory: MemoryManager.memory_sequence_finished.emit(data)
	playing = false; playback_finished.emit()

func _fade(item: CanvasItem, alpha: float, duration: float) -> void:
	if duration <= 0.0:
		item.modulate.a = alpha
		return
	var tween := create_tween(); tween.tween_property(item, "modulate:a", alpha, duration)
	await tween.finished

func _enter_memory_fade() -> void:
	fade_overlay.modulate.a = 0.0
	fade_overlay.show()
	await _fade(fade_overlay, 1.0, fade_in_duration)
	background.modulate.a = 1.0
	background.show()
	await _fade(fade_overlay, 0.0, fade_in_duration)
	fade_overlay.hide()

func _exit_memory_fade() -> void:
	fade_overlay.modulate.a = 0.0
	fade_overlay.show()
	await _fade(fade_overlay, 1.0, fade_out_duration)
	background.hide()
	await _fade(fade_overlay, 0.0, fade_out_duration)
	fade_overlay.hide()

func _apply_watercolor_parameters() -> void:
	watercolor_material.set_shader_parameter("reveal_softness", reveal_softness)
	watercolor_material.set_shader_parameter("noise_strength", noise_strength)
	watercolor_material.set_shader_parameter("noise_scale", noise_scale)
	watercolor_material.set_shader_parameter("wet_edge_strength", wet_edge_strength)
	watercolor_material.set_shader_parameter("watercolor_strength", watercolor_strength)
	watercolor_material.set_shader_parameter("reveal_direction", reveal_direction)

func _animate_reveal(from: float, to: float, duration: float) -> void:
	watercolor_material.set_shader_parameter("reveal_progress", from)
	var elapsed := 0.0
	while elapsed < duration and not skip_requested:
		elapsed += get_process_delta_time()
		var progress := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		progress = ease(progress, -1.5)
		watercolor_material.set_shader_parameter("reveal_progress", lerpf(from, to, progress))
		await get_tree().process_frame
	watercolor_material.set_shader_parameter("reveal_progress", to if not skip_requested else from)

func _wait_or_skip(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and not skip_requested:
		elapsed += get_process_delta_time()
		await get_tree().process_frame

func _reset_image() -> void:
	if image_rect == null: return
	image_rect.texture = null
	image_rect.material = null
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
