extends CanvasLayer

@export var show_timer := false

@onready var timer_background: PanelContainer = $TimerBackground
@onready var timer_label: Label = $TimerBackground/Label
@onready var pause_ui: Control = $Pause
@onready var resume_button: Button = $Pause/Panel/Content/Buttons/Resume
@onready var title_button: Button = $Pause/Panel/Content/Buttons/GoToMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer_background.visible = show_timer
	_setup_focus_neighbors()

func _process(_delta: float) -> void:
	if show_timer:
		timer_label.text = GameTimeManager.get_formatted_time()

func hide_timer() -> void:
	timer_background.hide()

func show_pause() -> void:
	_play_click()
	pause_ui.show()
	resume_button.grab_focus.call_deferred()

func _on_resume_pressed() -> void:
	_play_click()
	pause_ui.hide()
	get_tree().paused = false

func _on_go_to_menu_pressed() -> void:
	_play_click()
	pause_ui.hide()
	get_tree().paused = false
	GameTimeManager.stop_run()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")

func _setup_focus_neighbors() -> void:
	resume_button.focus_neighbor_top = resume_button.get_path_to(title_button)
	resume_button.focus_neighbor_bottom = resume_button.get_path_to(title_button)
	resume_button.focus_previous = resume_button.get_path_to(title_button)
	resume_button.focus_next = resume_button.get_path_to(title_button)
	title_button.focus_neighbor_top = title_button.get_path_to(resume_button)
	title_button.focus_neighbor_bottom = title_button.get_path_to(resume_button)
	title_button.focus_previous = title_button.get_path_to(resume_button)
	title_button.focus_next = title_button.get_path_to(resume_button)

func _play_click() -> void:
	if not ClickSound.playing:
		ClickSound.play()
