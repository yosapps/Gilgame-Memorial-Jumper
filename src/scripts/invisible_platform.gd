extends StaticBody2D
class_name InvisiblePlatform

@export_range(0.0, 0.5, 0.01) var hidden_alpha := 0.0
@export_range(0.05, 1.0, 0.01) var reveal_min_alpha := 0.18
@export_range(0.05, 1.0, 0.01) var reveal_max_alpha := 0.62
@export_range(0.5, 15.0, 0.1) var blink_speed := 5.5
@export_range(0.05, 2.0, 0.05) var fade_out_duration := 0.3

@onready var visual: CanvasItem = $Visual

var _reveal_remaining := 0.0
var _fade_remaining := 0.0
var _phase := 0.0

func _ready() -> void:
	add_to_group(&"revealable_platforms")
	_set_visual_alpha(hidden_alpha)
	set_process(false)

func reveal(duration: float) -> void:
	_reveal_remaining = maxf(duration, 0.1)
	_fade_remaining = fade_out_duration
	_phase = 0.0
	set_process(true)

func _process(delta: float) -> void:
	if _reveal_remaining > 0.0:
		_reveal_remaining = maxf(_reveal_remaining - delta, 0.0)
		_phase += delta * blink_speed * TAU
		var pulse := (sin(_phase) + 1.0) * 0.5
		_set_visual_alpha(lerpf(reveal_min_alpha, reveal_max_alpha, pulse))
		return
	if _fade_remaining > 0.0:
		_fade_remaining = maxf(_fade_remaining - delta, 0.0)
		var weight := 1.0 - (_fade_remaining / maxf(fade_out_duration, 0.001))
		_set_visual_alpha(lerpf(reveal_min_alpha, hidden_alpha, weight))
		return
	_set_visual_alpha(hidden_alpha)
	set_process(false)

func _set_visual_alpha(alpha: float) -> void:
	visual.modulate.a = clampf(alpha, 0.0, 1.0)

