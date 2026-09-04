extends Control

signal cutscene_finished

const GILGAME_FRAMES := preload("res://assets/sprites/player/player.tres")
const EXPECTED_CRYSTAL_COUNT := 10

@export var scatter_times := PackedFloat32Array([1.0, 1.55, 2.3, 2.72, 3.08, 4.05, 4.43, 5.2, 6.05, 6.9])
@export_range(0.5, 4.0, 0.1) var crystal_travel_min := 1.65
@export_range(0.5, 4.0, 0.1) var crystal_travel_max := 2.35
@export_range(0.1, 3.0, 0.1) var final_pause := 0.75
@export_range(0.1, 3.0, 0.1) var fade_duration := 1.0

var _rng := RandomNumberGenerator.new()
var _completed_crystals := 0
var _gilgame: AnimatedSprite2D
var _fall_particles: CPUParticles2D

func _ready() -> void:
	_rng.seed = 0x47494C47414D45
	if scatter_times.size() != EXPECTED_CRYSTAL_COUNT:
		push_warning("Opening requires exactly 10 scatter timings; using safe defaults.")
		scatter_times = PackedFloat32Array([1.0, 1.55, 2.3, 2.72, 3.08, 4.05, 4.43, 5.2, 6.05, 6.9])
	_build_gilgame()
	_build_falling_particles()
	resized.connect(_layout_visuals)
	_layout_visuals()
	await get_tree().process_frame
	_play_opening()

func _build_gilgame() -> void:
	_gilgame = AnimatedSprite2D.new()
	_gilgame.name = "GilgameVisual"
	_gilgame.sprite_frames = GILGAME_FRAMES
	_gilgame.animation = &"falling"
	_gilgame.scale = Vector2(4.0, 4.0)
	_gilgame.modulate.a = 0.0
	$GilgameContainer.add_child(_gilgame)
	_gilgame.play()

func _build_falling_particles() -> void:
	_fall_particles = CPUParticles2D.new()
	_fall_particles.name = "FallingParticles"
	_fall_particles.amount = 42
	_fall_particles.lifetime = 1.6
	_fall_particles.randomness = 0.65
	_fall_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fall_particles.gravity = Vector2(0.0, -330.0)
	_fall_particles.initial_velocity_min = 45.0
	_fall_particles.initial_velocity_max = 90.0
	_fall_particles.scale_amount_min = 0.6
	_fall_particles.scale_amount_max = 1.7
	_fall_particles.color = Color(0.45, 0.82, 1.0, 0.42)
	$FallingParticleLayer.add_child(_fall_particles)
	_fall_particles.emitting = true

func _layout_visuals() -> void:
	var center := size * Vector2(0.5, 0.47)
	$GilgameContainer.position = center
	if _fall_particles != null:
		_fall_particles.position = size * 0.5
		_fall_particles.emission_rect_extents = size * Vector2(0.44, 0.48)

func _play_opening() -> void:
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property($FadeOverlay, "modulate:a", 0.0, 0.75)
	reveal.tween_property(_gilgame, "modulate:a", 1.0, 0.75)
	_start_falling_motion()
	for index in EXPECTED_CRYSTAL_COUNT:
		var wait_time := scatter_times[index] if index == 0 else scatter_times[index] - scatter_times[index - 1]
		await get_tree().create_timer(wait_time).timeout
		_scatter_crystal(index)
	while _completed_crystals < EXPECTED_CRYSTAL_COUNT:
		await get_tree().process_frame
	assert(_completed_crystals == EXPECTED_CRYSTAL_COUNT)
	await get_tree().create_timer(final_pause).timeout
	_fall_particles.emitting = false
	var finish := create_tween().set_parallel(true)
	finish.tween_property(_gilgame, "modulate:a", 0.0, fade_duration)
	finish.tween_property(_gilgame, "scale", Vector2(3.25, 3.25), fade_duration)
	finish.tween_property($FadeOverlay, "modulate:a", 1.0, fade_duration)
	await finish.finished
	cutscene_finished.emit()
	SaveManager.mark_opening_seen()
	get_tree().change_scene_to_file(SaveManager.get_gameplay_start_scene())

func _start_falling_motion() -> void:
	_gilgame.rotation = PI
	var drift := create_tween().set_loops()
	drift.tween_property($GilgameContainer, "position:x", size.x * 0.5 - 16.0, 1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.parallel().tween_property(_gilgame, "rotation", 3.0, 1.35).set_trans(Tween.TRANS_SINE)
	drift.tween_property($GilgameContainer, "position:x", size.x * 0.5 + 16.0, 1.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.parallel().tween_property(_gilgame, "rotation", 3.2, 1.55).set_trans(Tween.TRANS_SINE)

func _scatter_crystal(index: int) -> void:
	var crystal := _create_crystal(index == EXPECTED_CRYSTAL_COUNT - 1)
	$CrystalLayer.add_child(crystal)
	var center := size * Vector2(0.5, 0.47)
	crystal.position = center + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-22.0, 14.0))
	var destinations := [
		Vector2(0.12, 0.12), Vector2(0.86, 0.16), Vector2(0.07, 0.43), Vector2(0.93, 0.38),
		Vector2(0.2, 0.72), Vector2(0.8, 0.68), Vector2(0.32, 0.08), Vector2(0.68, 0.1),
		Vector2(0.04, 0.76), Vector2(0.94, 0.72)
	]
	var destination: Vector2 = size * destinations[index]
	destination += Vector2(_rng.randf_range(-24.0, 24.0), _rng.randf_range(-18.0, 18.0))
	var bend := Vector2(_rng.randf_range(-65.0, 65.0), _rng.randf_range(-75.0, -20.0))
	var midpoint := crystal.position.lerp(destination, 0.42) + bend
	var duration := _rng.randf_range(crystal_travel_min, crystal_travel_max)
	if index == EXPECTED_CRYSTAL_COUNT - 1: duration += 0.35
	var motion := create_tween()
	motion.tween_property(crystal, "position", midpoint, duration * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_property(crystal, "position", destination, duration * 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var appearance := create_tween().set_parallel(true)
	appearance.tween_property(crystal, "rotation", _rng.randf_range(-PI * 2.0, PI * 2.0), duration)
	appearance.tween_property(crystal, "scale", Vector2(0.18, 0.18), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	appearance.tween_property(crystal, "modulate:a", 0.0, duration).set_delay(duration * 0.55)
	await motion.finished
	_completed_crystals += 1
	crystal.queue_free()

func _create_crystal(is_final: bool) -> Node2D:
	var visual := Node2D.new()
	visual.scale = Vector2.ONE * (0.72 if not is_final else 0.84)
	var glow := PointLight2D.new()
	glow.color = Color(0.35, 0.8, 1.0)
	glow.energy = 1.7 if not is_final else 2.3
	glow.texture_scale = 1.2
	visual.add_child(glow)
	var shell := Polygon2D.new()
	shell.polygon = PackedVector2Array([Vector2(0, -18), Vector2(10, -6), Vector2(7, 14), Vector2(0, 19), Vector2(-7, 14), Vector2(-10, -6)])
	shell.color = Color(0.25, 0.82, 1.0, 0.96)
	visual.add_child(shell)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -13), Vector2(4, -4), Vector2(3, 10), Vector2(0, 13), Vector2(-3, 8), Vector2(-4, -4)])
	core.color = Color(0.86, 0.98, 1.0, 0.92)
	visual.add_child(core)
	var dust := CPUParticles2D.new()
	dust.amount = 9 if not is_final else 13
	dust.lifetime = 0.65
	dust.local_coords = false
	dust.randomness = 0.7
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 7.0
	dust.gravity = Vector2(0, 12)
	dust.initial_velocity_min = 5.0
	dust.initial_velocity_max = 18.0
	dust.scale_amount_min = 0.7
	dust.scale_amount_max = 1.7
	dust.color = Color(0.55, 0.92, 1.0, 0.78)
	visual.add_child(dust)
	dust.emitting = true
	return visual
