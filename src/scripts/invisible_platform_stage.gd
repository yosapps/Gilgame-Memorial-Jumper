extends Node2D

const GAMEPLAY_MENU_BUTTON := preload("res://src/scripts/ui/gameplay_menu_button.gd")

@export_range(0.5, 10.0, 0.1) var reveal_duration := 3.0
@export_range(0.0, 200.0, 1.0) var screen_margin := 48.0

@onready var time_ui: CanvasLayer = $TimeUI
@onready var reveal_flash: RevealFlashEffect = $Player/RevealFlash

func _ready() -> void:
	GameTimeManager.start_run()
	var menu_font := load("res://assets/fonts/rounded-mplus-1p-bold.ttf") as Font
	GAMEPLAY_MENU_BUTTON.decorate($HUD/MenuBtn, menu_font)
	if not Global.is_mobile_web:
		$HUD/Joystick.hide()
		$HUD/Joystick.process_mode = Node.PROCESS_MODE_DISABLED
		$HUD/Jump.hide()
		$HUD/Jump.process_mode = Node.PROCESS_MODE_DISABLED
	$HUD/RevealHint.show()
	var fade := create_tween()
	fade.tween_property($HUD/EntryFade, "modulate:a", 0.0, 0.8)
	fade.finished.connect($HUD/EntryFade.hide)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_event()
	elif event.is_action_pressed("reveal_platforms") and not event.is_echo():
		_reveal_platforms_in_view()
		get_viewport().set_input_as_handled()

func _reveal_platforms_in_view() -> void:
	reveal_flash.play_flash()
	var viewport_rect := get_viewport().get_visible_rect().grow(screen_margin)
	var canvas_transform := get_viewport().get_canvas_transform()
	for node in get_tree().get_nodes_in_group(&"revealable_platforms"):
		var platform := node as InvisiblePlatform
		if platform == null:
			continue
		var screen_position := canvas_transform * platform.global_position
		if viewport_rect.has_point(screen_position):
			platform.reveal(reveal_duration)

func pause_event() -> void:
	if get_tree().is_paused():
		return
	get_tree().paused = true
	time_ui.show_pause()

