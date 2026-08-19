class_name MemoryStageWarp
extends Area2D

@export_file("*.tscn") var destination_scene := ""
@export var is_final_warp := false
@export_range(0.2, 3.0, 0.05) var appearance_duration := 1.0
@export_range(0.2, 3.0, 0.05) var teleport_duration := 0.85

var active := false
var _transitioning := false
var _phase := 0.0

func _ready() -> void:
	monitoring = false
	scale = Vector2.ZERO
	modulate.a = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU)
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(_phase * 2.2) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, 27.0 + pulse * 3.0, Color(0.25, 0.25, 0.75, 0.2))
	for index in 3:
		var direction := 1.0 if index % 2 == 0 else -1.0
		var start := _phase * direction + index * 1.7
		draw_arc(Vector2.ZERO, 27.0 + index * 8.0, start, start + PI * 1.45, 40, Color(0.38, 0.78, 1.0, 0.85 - index * 0.16), 2.5)
	for index in 8:
		var angle := _phase * 0.65 + TAU * float(index) / 8.0
		draw_circle(Vector2.from_angle(angle) * (39.0 + sin(_phase * 3.0 + index) * 5.0), 2.0, Color(0.68, 0.9, 1.0, 0.8))

func activate() -> void:
	if active: return
	active = true
	show()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, appearance_duration)
	tween.tween_property(self, "modulate:a", 1.0, appearance_duration * 0.65)
	await tween.finished
	monitoring = true

func _on_body_entered(body: Node2D) -> void:
	if not active or _transitioning or not body.is_in_group("player"): return
	_transitioning = true
	monitoring = false
	body.is_can_move = false
	body.velocity = Vector2.ZERO
	body.jump_mode = false
	body.jump_force = 0.0
	var flash := _create_flash()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "global_position", global_position, teleport_duration)
	tween.tween_property(body, "scale", Vector2.ZERO, teleport_duration)
	tween.tween_property(body, "rotation", body.rotation + TAU * 1.5, teleport_duration)
	tween.tween_property(flash, "modulate:a", 1.0, teleport_duration)
	await tween.finished
	if is_final_warp:
		GameTimeManager.stop_run()
		Global.pending_ending = EndingManager.trigger_ending()
		get_tree().change_scene_to_file("res://src/scenes/ending_scene.tscn")
	elif destination_scene.is_empty():
		push_error("MemoryStageWarp has no destination scene.")
		_transitioning = false
	else:
		get_tree().change_scene_to_file(destination_scene)

func _create_flash() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 90
	get_tree().current_scene.add_child(layer)
	var flash := ColorRect.new()
	flash.color = Color(0.68, 0.88, 1.0)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)
	return flash
