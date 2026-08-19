extends Area2D

@export_range(0.2, 3.0, 0.05) var warp_duration := 1.1
@export var warp_color := Color(0.35, 0.9, 1.0, 0.9)
@export_file("*.tscn") var destination_scene := ""
@export var is_final_goal := true
@export_range(0, 10, 1) var unlock_stage_index := 0
var _phase := 0.0
var _warping := false

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU)
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(_phase * 2.0) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, 25.0 + pulse * 4.0, Color(warp_color, 0.12 + pulse * 0.08))
	for i in 3:
		var radius := 24.0 + i * 9.0 + pulse * 3.0
		var start := _phase * (1.0 if i % 2 == 0 else -1.0) + i
		draw_arc(Vector2.ZERO, radius, start, start + PI * 1.45, 40, Color(warp_color, 0.75 - i * 0.16), 2.5)
	for i in 6:
		var angle := _phase * 0.7 + TAU * float(i) / 6.0
		var point := Vector2.from_angle(angle) * (34.0 + sin(_phase * 3.0 + i) * 5.0)
		draw_circle(point, 2.0, Color(warp_color, 0.85))

func _on_body_entered(body: Node2D) -> void:
	if _warping or not body.is_in_group("player"): return
	_warping = true
	monitoring = false
	body.is_can_move = false
	body.velocity = Vector2.ZERO
	body.jump_mode = false
	body.jump_force = 0
	if is_final_goal:
		GameTimeManager.stop_run()
		Global.pending_ending = EndingManager.trigger_ending()
	elif unlock_stage_index > 0:
		SaveManager.unlock_stage(unlock_stage_index)
	var flash := ColorRect.new()
	flash.color = Color(0.72, 0.95, 1.0, 1.0)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	get_tree().current_scene.add_child(overlay)
	overlay.add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "global_position", global_position, warp_duration)
	tween.tween_property(body, "scale", Vector2.ZERO, warp_duration)
	tween.tween_property(body, "rotation", body.rotation + TAU * 2.0, warp_duration)
	tween.tween_property(body, "modulate:a", 0.0, warp_duration * 0.85)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), warp_duration)
	tween.tween_property(flash, "modulate:a", 1.0, warp_duration)
	await tween.finished
	if is_final_goal:
		get_tree().change_scene_to_file("res://src/scenes/ending_scene.tscn")
	elif not destination_scene.is_empty():
		get_tree().change_scene_to_file(destination_scene)
	else:
		push_error("Goal destination_scene is empty.")
