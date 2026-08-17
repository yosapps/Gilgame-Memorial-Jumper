extends Node2D

func go_back():
	if !ClickSound.playing: ClickSound.play()
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")

func download_ios():
	OS.shell_open("https://apps.apple.com/app/ギルガメジャンパー/id6566179334")

func download_android():
	OS.shell_open("https://play.google.com/store/apps/details?id=com.yosapps.gilgamejumper")
