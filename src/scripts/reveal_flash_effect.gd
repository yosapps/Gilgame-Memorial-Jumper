extends Node2D
class_name RevealFlashEffect

@export var flash_color := Color(0.42, 0.86, 1.0, 1.0)
@export_range(32.0, 600.0, 8.0) var maximum_radius := 260.0
@export_range(0.1, 2.0, 0.05) var duration := 0.65

var _radius := 0.0:
	set(value):
		_radius = value
		queue_redraw()
var _alpha := 0.0:
	set(value):
		_alpha = value
		queue_redraw()
var _flash_tween: Tween

func _ready() -> void:
	visible = false

func play_flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	visible = true
	_radius = 8.0
	_alpha = 0.9
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(self, "_radius", maximum_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(self, "_alpha", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _flash_tween.finished
	visible = false

func _draw() -> void:
	if _alpha <= 0.0:
		return
	draw_circle(Vector2.ZERO, _radius, Color(flash_color, _alpha * 0.055))
	for index in 3:
		var ring_radius := maxf(_radius - float(index) * 10.0, 1.0)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 96, Color(flash_color, _alpha * (0.62 - index * 0.14)), 2.5 - index * 0.5, true)
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var ray_start := Vector2.from_angle(angle) * (_radius * 0.72)
		var ray_end := Vector2.from_angle(angle) * _radius
		draw_line(ray_start, ray_end, Color(flash_color, _alpha * 0.35), 1.5, true)

