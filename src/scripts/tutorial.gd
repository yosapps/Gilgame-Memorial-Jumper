extends Node2D

const GAMEPLAY_MENU_BUTTON := preload("res://src/scripts/ui/gameplay_menu_button.gd")

@onready var transition: AnimationPlayer = $HUB/Transition
@onready var color_rect: ColorRect = $HUB/Transition/ColorRect
@onready var time_ui: CanvasLayer = $TimeUI

func _ready() -> void:
	GameTimeManager.start_run()
	var menu_button := $HUB/MenuBtn as TextureButton
	var menu_font := load("res://assets/fonts/rounded-mplus-1p-bold.ttf") as Font
	GAMEPLAY_MENU_BUTTON.decorate(menu_button, menu_font)
	# 画面遷移のフェードインを実行
	color_rect.visible = true
	transition.play("fade_in")
	# モバイル環境でなければジョイスティックとジャンプボタンを非表示にする
	if !Global.is_mobile_web:
		$HUB/Joystick.hide()
		$HUB/Joystick.process_mode = Node.PROCESS_MODE_DISABLED
		$HUB/Jump.hide()
		$HUB/Jump.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_event()

func pause_event() -> void:
	if not get_tree().is_paused():
		get_tree().paused = true
		time_ui.show_pause()

func go_title() -> void:
	get_tree().paused = false
	GameTimeManager.stop_run()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")

## Kept for the stage-clear panel; the pause menu no longer exposes restart.
func reset() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
