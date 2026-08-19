extends Node2D

var stage_animation
var selected_stage
var selected_multiplayer = 0

var SELECTED_MODE = tr("normal-mode")

var GAME_ID = 1

func _ready():
	GameTimeManager.stop_run()
	Bgm.play()
	Global.is_mobile_web = OS.has_feature("web_ios") || OS.has_feature("web_android")
	$HUB/DevResetBtn.visible = _is_editor_runtime()
	$HUB/Toast.hide()

func start_tutorial():
	if !ClickSound.playing: ClickSound.play()
	Bgm.stop()
	GameTimeManager.reset_timer()
	if SaveManager.has_seen_opening():
		get_tree().change_scene_to_file(SaveManager.get_gameplay_start_scene())
	else:
		get_tree().change_scene_to_file("res://src/scenes/opening_fall_cutscene.tscn")

func open_memory_gallery() -> void:
	if !ClickSound.playing: ClickSound.play()
	get_tree().change_scene_to_file("res://src/scenes/memory_gallery.tscn")

func request_dev_reset() -> void:
	if not _is_editor_runtime(): return
	$HUB/ResetConfirmation.popup_centered()

func confirm_dev_reset() -> void:
	if not _is_editor_runtime(): return
	SaveManager.reset_all_data()
	$HUB/Toast.text = "データをリセットしました"
	$HUB/Toast.show()
	get_tree().create_timer(2.5).timeout.connect($HUB/Toast.hide)

func _is_editor_runtime() -> bool:
	return OS.has_feature("editor")
