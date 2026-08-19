extends Control

const MAIN_SCENE_PATH := "res://src/scenes/title.tscn"
const BASE_PRELOAD_PATHS := [
	MAIN_SCENE_PATH,
	"res://src/scenes/opening_fall_cutscene.tscn",
	"res://src/scenes/memory_gallery.tscn",
]

@export_range(0.5, 10.0, 0.1) var minimum_display_seconds := 2.8
@export_range(2.0, 30.0, 0.5) var loading_timeout_seconds := 15.0

@onready var logo_glow: TextureRect = $Center/LogoGlow
@onready var logo: TextureRect = $Center/Logo
@onready var tagline: Label = $Center/Tagline
@onready var loading_label: Label = $Bottom/LoadingLabel
@onready var progress_bar: ProgressBar = $Bottom/ProgressBar
@onready var fade_overlay: ColorRect = $FadeOverlay

var requested_paths: Array[String] = []
var elapsed := 0.0

func _ready() -> void:
	GameTimeManager.stop_run()
	Bgm.stop()
	_start_scene_loading()
	_start_ambient_animation()
	await _play_intro()
	await _wait_for_loading()
	await _transition_to_title()

func _process(delta: float) -> void:
	elapsed += delta
	var dot_count := int(elapsed * 2.5) % 4
	loading_label.text = "記憶を読み込んでいます" + ".".repeat(dot_count)

func _start_scene_loading() -> void:
	for path in BASE_PRELOAD_PATHS:
		_request_scene(path)
	var gameplay_scene := SaveManager.get_gameplay_start_scene()
	_request_scene(gameplay_scene)

func _request_scene(path: String) -> void:
	if path.is_empty() or requested_paths.has(path):
		return
	if not ResourceLoader.exists(path):
		push_warning("Startup preload scene is missing: %s" % path)
		return
	var error := ResourceLoader.load_threaded_request(path, "PackedScene", true)
	if error == OK:
		requested_paths.append(path)
	else:
		push_warning("Could not request startup scene: %s (error %d)" % [path, error])

func _wait_for_loading() -> void:
	while elapsed < minimum_display_seconds or not _collect_loaded_scenes():
		if elapsed >= loading_timeout_seconds:
			push_warning("Startup scene loading timed out; continuing with synchronous fallback.")
			break
		await get_tree().process_frame
	_collect_loaded_scenes()

func _collect_loaded_scenes() -> bool:
	if requested_paths.is_empty():
		progress_bar.value = 100.0
		return true
	var total_progress := 0.0
	var all_finished := true
	for path in requested_paths:
		if Global.startup_scene_cache.has(path):
			total_progress += 1.0
			continue
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			if resource != null:
				Global.startup_scene_cache[path] = resource
				total_progress += 1.0
			else:
				all_finished = false
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_warning("Startup preload failed: %s" % path)
			total_progress += 1.0
		else:
			all_finished = false
			total_progress += float(progress[0]) if not progress.is_empty() else 0.0
	progress_bar.value = total_progress / requested_paths.size() * 100.0
	return all_finished

func _play_intro() -> void:
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.86, 0.86)
	logo_glow.modulate.a = 0.0
	tagline.modulate.a = 0.0
	$Bottom.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, 0.75).set_delay(0.12)
	tween.tween_property(logo, "scale", Vector2.ONE, 0.95).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(logo_glow, "modulate:a", 0.42, 1.0).set_delay(0.2)
	tween.tween_property(tagline, "modulate:a", 1.0, 0.6).set_delay(0.65)
	tween.tween_property($Bottom, "modulate:a", 1.0, 0.5).set_delay(0.85)
	await tween.finished

func _start_ambient_animation() -> void:
	var glow_tween := create_tween().set_loops()
	glow_tween.tween_property(logo_glow, "modulate:a", 0.68, 1.3).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(logo_glow, "modulate:a", 0.38, 1.3).set_trans(Tween.TRANS_SINE)
	for index in $Sparkles.get_child_count():
		var sparkle := $Sparkles.get_child(index) as Label
		var sparkle_tween := sparkle.create_tween().set_loops()
		sparkle_tween.tween_property(sparkle, "modulate:a", 1.0, 0.55 + index * 0.08).set_delay(index * 0.12)
		sparkle_tween.tween_property(sparkle, "modulate:a", 0.18, 0.75 + index * 0.06)

func _transition_to_title() -> void:
	loading_label.text = "準備ができました"
	progress_bar.value = 100.0
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.55)
	await tween.finished
	var title_scene := Global.startup_scene_cache.get(MAIN_SCENE_PATH) as PackedScene
	if title_scene == null:
		title_scene = load(MAIN_SCENE_PATH) as PackedScene
	if title_scene != null:
		get_tree().change_scene_to_packed(title_scene)
	else:
		push_error("Title scene could not be loaded.")
