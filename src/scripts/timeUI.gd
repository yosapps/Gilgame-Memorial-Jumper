extends CanvasLayer

@export var showTimer = false
@onready var label = $Label
@onready var timer = $Timer
@onready var pauseUI = $Pause

var time = 0

func _ready():
	timer.start()
	label.visible = showTimer
		
func hide_timer():
	$Label.hide()

func _on_timer_timeout():
	time += 1
	label.text = str(time)

func pauseTimer():
	timer.stop()
	
func startTimer():
	timer.start()
	
func resetTimer():
	timer.stop()
	time= 0
	label.text = "0"
	timer.start()

func isPaused():
	return timer.is_stopped()

func show_pause():
	if !ClickSound.playing: ClickSound.play()
	pauseUI.visible = true

func _on_start_pressed():
	if !ClickSound.playing: ClickSound.play()
	pauseUI.visible = false
	get_tree().paused = false

func _on_go_to_menu_pressed():
	if !ClickSound.playing: ClickSound.play()
	pauseUI.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")

func _on_restart_pressed():
	if !ClickSound.playing: ClickSound.play()
	pauseUI.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()
