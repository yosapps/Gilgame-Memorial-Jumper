extends Node2D

const GAMEPLAY_MENU_BUTTON := preload("res://src/scripts/ui/gameplay_menu_button.gd")

@export var darkness_color := Color(0.025, 0.035, 0.065, 1.0)
@export_range(0.1, 4.0, 0.05) var player_light_energy := 1.35
@export_range(0.2, 4.0, 0.05) var player_light_scale := 1.15
@export var player_light_color := Color(1.0, 0.82, 0.58, 1.0)

@onready var time_ui: CanvasLayer = $TimeUI
@onready var darkness: CanvasModulate = $Darkness
@onready var player_light: PointLight2D = $Player/PlayerLight

func _ready() -> void:
	GameTimeManager.start_run()
	darkness.color = darkness_color
	player_light.energy = player_light_energy
	player_light.texture_scale = player_light_scale
	player_light.color = player_light_color
	var menu_font := load("res://assets/fonts/rounded-mplus-1p-bold.ttf") as Font
	GAMEPLAY_MENU_BUTTON.decorate($HUD/MenuBtn, menu_font)
	if not Global.is_mobile_web:
		$HUD/Joystick.hide()
		$HUD/Joystick.process_mode = Node.PROCESS_MODE_DISABLED
		$HUD/Jump.hide()
		$HUD/Jump.process_mode = Node.PROCESS_MODE_DISABLED
	var fade := create_tween()
	fade.tween_property($HUD/EntryFade, "modulate:a", 0.0, 0.8)
	fade.finished.connect($HUD/EntryFade.hide)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_event()

func pause_event() -> void:
	if get_tree().is_paused():
		return
	get_tree().paused = true
	time_ui.show_pause()

