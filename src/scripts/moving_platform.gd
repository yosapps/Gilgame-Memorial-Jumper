@tool
extends AnimatableBody2D

enum MovementMode { PING_PONG, ONE_WAY }

## 開始位置から見た行先。Xで横、Yで縦、両方で斜め移動します。
@export var destination_offset := Vector2(160.0, 0.0):
	set(value):
		destination_offset = value
		queue_redraw()
## 1秒間に移動するピクセル数。
@export_range(1.0, 1000.0, 1.0, "or_greater") var move_speed := 80.0
## PING_PONGは往復、ONE_WAYは行先で停止します。
@export var movement_mode := MovementMode.PING_PONG
## 始点・終点に着いたとき停止する秒数。
@export_range(0.0, 10.0, 0.1, "or_greater") var wait_time := 0.5
## 有効にすると行先側から動き始めます。
@export var start_at_destination := false

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var moving_to_end := true
var wait_remaining := 0.0
var stopped := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	start_position = position
	end_position = start_position + destination_offset
	if start_at_destination:
		position = end_position
		moving_to_end = false

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or stopped:
		return
	if wait_remaining > 0.0:
		wait_remaining = maxf(wait_remaining - delta, 0.0)
		return
	var target := end_position if moving_to_end else start_position
	position = position.move_toward(target, move_speed * delta)
	if position.is_equal_approx(target):
		position = target
		if movement_mode == MovementMode.ONE_WAY:
			stopped = true
		else:
			moving_to_end = not moving_to_end
			wait_remaining = wait_time

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_dashed_line(Vector2.ZERO, destination_offset, Color(0.2, 0.85, 1.0, 0.9), 2.0, 8.0)
	draw_circle(destination_offset, 5.0, Color(0.2, 0.85, 1.0, 0.9))
