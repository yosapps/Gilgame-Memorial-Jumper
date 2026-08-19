class_name HardModeUnlockPopup
extends Control

signal dismissed

@onready var panel: PanelContainer = $Panel
@onready var close_button: Button = $Panel/Content/CloseButton

var closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func show_popup() -> void:
	show()
	modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
	close_button.grab_focus()

func _on_close_button_pressed() -> void:
	if closing:
		return
	closing = true
	if not ClickSound.playing:
		ClickSound.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	dismissed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
