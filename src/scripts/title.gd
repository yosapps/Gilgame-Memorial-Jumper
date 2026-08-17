extends Node2D

var stage_animation
var selected_stage
var selected_multiplayer = 0

var SELECTED_MODE = tr("normal-mode")

var GAME_ID = 1

func _ready():
	Bgm.play()
	Global.is_mobile_web = OS.has_feature("web_ios") || OS.has_feature("web_android")

func start_tutorial():
	if !ClickSound.playing: ClickSound.play()
	Bgm.stop()
	get_tree().change_scene_to_file("res://src/scenes/tutorial.tscn")

func donate():
	OS.shell_open("https://buymeacoffee.com/yosapps")

func homepage():
	OS.shell_open("https://www.yosapps.com")
			
func go_download():
	if !ClickSound.playing: ClickSound.play()
	get_tree().change_scene_to_file("res://src/scenes/mobile.tscn")
