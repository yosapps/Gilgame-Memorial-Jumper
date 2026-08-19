extends Node2D

const POPUP_ANIMATION_SECONDS := 0.2

@onready var menu: VBoxContainer = $HUB/Layout/Menu
@onready var start_button: Button = $HUB/Layout/Menu/StartBtn
@onready var hard_mode_button: Button = $HUB/Layout/Menu/HardModeBtn
@onready var gallery_button: Button = $HUB/Layout/Menu/GalleryBtn
@onready var clear_time_button: Button = $HUB/Layout/Menu/ClearTimeBtn
@onready var options_button: Button = $HUB/Layout/Menu/OptionsBtn
@onready var popup_layer: Control = $HUB/PopupLayer
@onready var popup_dim: ColorRect = $HUB/PopupLayer/Dim
@onready var clear_time_popup: PanelContainer = $HUB/PopupLayer/ClearTimePopup
@onready var options_popup: PanelContainer = $HUB/PopupLayer/OptionsPopup
@onready var bgm_slider: HSlider = $HUB/PopupLayer/OptionsPopup/Content/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $HUB/PopupLayer/OptionsPopup/Content/SfxRow/SfxSlider

var active_popup: Control
var popup_tween: Tween
var previous_focus: Control

func _ready() -> void:
	SaveManager.activate_game_mode(Global.GameMode.NORMAL)
	GameTimeManager.stop_run()
	SaveManager.apply_audio_settings()
	Bgm.play()
	Global.is_mobile_web = OS.has_feature("web_ios") or OS.has_feature("web_android")
	$HUB/DevResetBtn.visible = _is_editor_runtime()
	hard_mode_button.visible = SaveManager.is_hard_mode_unlocked()
	_update_clear_time_popup()
	_setup_audio_controls()
	_setup_focus_neighbors()
	popup_layer.show()
	popup_dim.hide()
	clear_time_popup.hide()
	options_popup.hide()
	$HUB/Toast.hide()
	start_button.grab_focus()

func start_tutorial() -> void:
	_start_game(Global.GameMode.NORMAL)

func start_hard_mode() -> void:
	if SaveManager.is_hard_mode_unlocked():
		_start_game(Global.GameMode.HARD)

func _start_game(mode: Global.GameMode) -> void:
	_play_click()
	Bgm.stop()
	SaveManager.activate_game_mode(mode)
	GameTimeManager.reset_timer()
	if SaveManager.has_seen_opening():
		get_tree().change_scene_to_file(SaveManager.get_gameplay_start_scene())
	else:
		get_tree().change_scene_to_file("res://src/scenes/opening_fall_cutscene.tscn")

func open_memory_gallery() -> void:
	_play_click()
	get_tree().change_scene_to_file("res://src/scenes/memory_gallery.tscn")

func open_clear_time_popup() -> void:
	_update_clear_time_popup()
	_open_popup(clear_time_popup, clear_time_button, $HUB/PopupLayer/ClearTimePopup/Content/CloseBtn)

func open_options_popup() -> void:
	bgm_slider.value = SaveManager.get_bgm_volume() * 100.0
	sfx_slider.value = SaveManager.get_sfx_volume() * 100.0
	_update_volume_labels()
	_open_popup(options_popup, options_button, bgm_slider)

func close_active_popup() -> void:
	if active_popup == null:
		return
	_play_click()
	if popup_tween != null:
		popup_tween.kill()
	var closing := active_popup
	popup_tween = create_tween().set_parallel(true)
	popup_tween.tween_property(closing, "modulate:a", 0.0, POPUP_ANIMATION_SECONDS)
	popup_tween.tween_property(closing, "scale", Vector2(0.97, 0.97), POPUP_ANIMATION_SECONDS).set_trans(Tween.TRANS_SINE)
	popup_tween.tween_property(popup_dim, "modulate:a", 0.0, POPUP_ANIMATION_SECONDS)
	await popup_tween.finished
	closing.hide()
	popup_dim.hide()
	active_popup = null
	_set_menu_enabled(true)
	if previous_focus != null and is_instance_valid(previous_focus):
		previous_focus.grab_focus()

func _open_popup(popup: Control, opener: Control, initial_focus: Control) -> void:
	if active_popup != null:
		return
	_play_click()
	previous_focus = opener
	active_popup = popup
	_set_menu_enabled(false)
	popup_dim.show()
	popup.show()
	popup_dim.modulate.a = 0.0
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.97, 0.97)
	await get_tree().process_frame
	popup.pivot_offset = popup.size * 0.5
	popup_tween = create_tween().set_parallel(true)
	popup_tween.tween_property(popup_dim, "modulate:a", 1.0, POPUP_ANIMATION_SECONDS)
	popup_tween.tween_property(popup, "modulate:a", 1.0, POPUP_ANIMATION_SECONDS)
	popup_tween.tween_property(popup, "scale", Vector2.ONE, POPUP_ANIMATION_SECONDS).set_trans(Tween.TRANS_SINE)
	initial_focus.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if active_popup != null and event.is_action_pressed("ui_cancel"):
		close_active_popup()
		get_viewport().set_input_as_handled()

func _setup_audio_controls() -> void:
	bgm_slider.value = SaveManager.get_bgm_volume() * 100.0
	sfx_slider.value = SaveManager.get_sfx_volume() * 100.0
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	_update_volume_labels()

func _on_bgm_volume_changed(value: float) -> void:
	SaveManager.set_bgm_volume(value / 100.0)
	_update_volume_labels()

func _on_sfx_volume_changed(value: float) -> void:
	SaveManager.set_sfx_volume(value / 100.0)
	_update_volume_labels()

func _on_sfx_drag_ended(value_changed: bool) -> void:
	if value_changed:
		_play_click()

func _update_volume_labels() -> void:
	$HUB/PopupLayer/OptionsPopup/Content/BgmRow/Value.text = "%d%%" % roundi(bgm_slider.value)
	$HUB/PopupLayer/OptionsPopup/Content/SfxRow/Value.text = "%d%%" % roundi(sfx_slider.value)

func _update_clear_time_popup() -> void:
	var normal_time := SaveManager.get_normal_best_time()
	var hard_time := SaveManager.get_hard_best_time()
	$HUB/PopupLayer/ClearTimePopup/Content/NormalTime.text = _format_best_time(normal_time)
	$HUB/PopupLayer/ClearTimePopup/Content/HardTime.text = _format_best_time(hard_time)
	var valid_times: Array[float] = []
	if normal_time >= 0.0: valid_times.append(normal_time)
	if hard_time >= 0.0: valid_times.append(hard_time)
	$HUB/PopupLayer/ClearTimePopup/Content/OverallTime.text = _format_best_time(valid_times.min() if not valid_times.is_empty() else -1.0)

func _format_best_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--:--.--"
	var centiseconds := int(seconds * 100.0)
	var total_seconds := centiseconds / 100
	return "%02d:%02d:%02d.%02d" % [total_seconds / 3600, (total_seconds % 3600) / 60, total_seconds % 60, centiseconds % 100]

func _setup_focus_neighbors() -> void:
	var buttons: Array[Control] = []
	for child in menu.get_children():
		if child is Button and child.visible:
			buttons.append(child)
	for index in buttons.size():
		var current := buttons[index]
		var previous := buttons[(index - 1 + buttons.size()) % buttons.size()]
		var next := buttons[(index + 1) % buttons.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)

func _set_menu_enabled(enabled: bool) -> void:
	for child in menu.get_children():
		if child is Button:
			child.disabled = not enabled

func exit_game() -> void:
	SaveManager.save_game()
	get_tree().quit()

func request_dev_reset() -> void:
	if _is_editor_runtime():
		$HUB/ResetConfirmation.popup_centered()

func confirm_dev_reset() -> void:
	if not _is_editor_runtime():
		return
	SaveManager.reset_all_data()
	hard_mode_button.hide()
	_update_clear_time_popup()
	_setup_focus_neighbors()
	$HUB/Toast.text = "データをリセットしました"
	$HUB/Toast.show()
	get_tree().create_timer(2.5).timeout.connect($HUB/Toast.hide)

func _play_click() -> void:
	if not ClickSound.playing:
		ClickSound.play()

func _is_editor_runtime() -> bool:
	return OS.has_feature("editor")
