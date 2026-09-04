@tool
extends AnimatableBody2D
class_name SpecialPlatform

enum PlatformType {
	BOUNCE,
	CRUMBLE,
	VANISH_ON_TOUCH,
	BLINK,
	CONVEYOR,
	ROTATING,
}

const TYPE_NAMES := ["BOUNCE", "CRUMBLE", "VANISH", "BLINK", "CONVEYOR", "ROTATING"]
const TYPE_COLORS := [
	Color("4fc3f7"), Color("d79a59"), Color("a98de8"),
	Color("5fd3b3"), Color("edb84d"), Color("e67886"),
]

@export var platform_type := PlatformType.BOUNCE:
	set(value):
		platform_type = value
		_refresh_editor_preview()
@export var platform_size := Vector2(96.0, 16.0):
	set(value):
		platform_size = Vector2(maxf(value.x, 24.0), maxf(value.y, 8.0))
		_refresh_editor_preview()
@export var use_custom_color := false:
	set(value):
		use_custom_color = value
		_refresh_editor_preview()
@export var custom_color := Color("71b9dd"):
	set(value):
		custom_color = value
		_refresh_editor_preview()
@export var one_way_collision := true
@export var show_type_label := false:
	set(value):
		show_type_label = value
		_refresh_editor_preview()

@export_group("Trigger / Recovery")
@export_range(0.0, 5.0, 0.05) var trigger_delay := 0.35
@export_range(0.1, 20.0, 0.1) var recovery_time := 2.0
@export var recover_after_activation := true

@export_group("Bounce")
@export_range(100.0, 1500.0, 10.0) var bounce_velocity := 720.0

@export_group("Crumble")
@export_range(32.0, 2000.0, 8.0) var fall_distance := 420.0
@export_range(0.1, 5.0, 0.05) var fall_duration := 1.0
@export_range(0.0, 20.0, 0.5) var warning_shake_amount := 3.0

@export_group("Blink")
@export_range(0.1, 20.0, 0.1) var visible_time := 1.5
@export_range(0.1, 20.0, 0.1) var hidden_time := 1.0
@export_range(0.0, 5.0, 0.05) var blink_warning_time := 0.35

@export_group("Conveyor")
@export_range(-1000.0, 1000.0, 10.0) var conveyor_speed := 150.0

@export_group("Rotation")
@export_range(-360.0, 360.0, 5.0) var rotation_degrees_per_second := 35.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sensor_shape: CollisionShape2D = $Trigger/CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var shadow: Polygon2D = $Visual/Shadow
@onready var base: Polygon2D = $Visual/Base
@onready var top: Polygon2D = $Visual/Top
@onready var marking: Label = $Visual/Marking
@onready var type_label: Label = $TypeLabel

var _origin_position := Vector2.ZERO
var _origin_rotation := 0.0
var _activated := false
var _available := true

func _ready() -> void:
	_origin_position = position
	_origin_rotation = rotation
	_configure_nodes()
	if Engine.is_editor_hint():
		return
	$Trigger.body_entered.connect(_on_body_entered)
	if platform_type == PlatformType.BLINK:
		_run_blink_cycle()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if platform_type == PlatformType.ROTATING and _available:
		rotation += deg_to_rad(rotation_degrees_per_second) * delta

func _configure_nodes() -> void:
	if not is_node_ready():
		return
	var body_rectangle := RectangleShape2D.new()
	body_rectangle.size = platform_size
	collision_shape.shape = body_rectangle
	collision_shape.one_way_collision = one_way_collision
	var sensor_rectangle := RectangleShape2D.new()
	sensor_rectangle.size = Vector2(platform_size.x, platform_size.y + 12.0)
	sensor_shape.shape = sensor_rectangle
	sensor_shape.position.y = -6.0
	var half := platform_size * 0.5
	shadow.polygon = PackedVector2Array([
		Vector2(-half.x - 2.0, -half.y + 3.0), Vector2(half.x + 2.0, -half.y + 3.0),
		Vector2(half.x - 5.0, half.y + 5.0), Vector2(-half.x + 5.0, half.y + 5.0),
	])
	base.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x - 5.0, half.y), Vector2(-half.x + 5.0, half.y),
	])
	top.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x - 3.0, -half.y + 5.0), Vector2(-half.x + 3.0, -half.y + 5.0),
	])
	var color: Color = custom_color if use_custom_color else TYPE_COLORS[platform_type]
	base.color = color.darkened(0.35)
	top.color = color.lightened(0.18)
	marking.text = _get_marking()
	marking.position = Vector2(-half.x, -half.y - 1.0)
	marking.size = Vector2(platform_size.x, platform_size.y)
	type_label.text = TYPE_NAMES[platform_type]
	type_label.position = Vector2(-70.0, -half.y - 27.0)
	type_label.visible = show_type_label
	constant_linear_velocity = Vector2(conveyor_speed, 0.0) if platform_type == PlatformType.CONVEYOR else Vector2.ZERO

func _get_marking() -> String:
	match platform_type:
		PlatformType.BOUNCE: return "↑  ↑  ↑"
		PlatformType.CRUMBLE: return "◆  ◆  ◆"
		PlatformType.VANISH_ON_TOUCH: return "◇  ◇  ◇"
		PlatformType.BLINK: return "✦  ✦  ✦"
		PlatformType.CONVEYOR: return ">  >  >" if conveyor_speed >= 0.0 else "<  <  <"
		PlatformType.ROTATING: return "↻"
	return ""

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint() or not _available or not body.is_in_group("player"):
		return
	if body.global_position.y > global_position.y + platform_size.y:
		return
	match platform_type:
		PlatformType.BOUNCE:
			_bounce(body)
		PlatformType.CRUMBLE:
			_activate_crumble()
		PlatformType.VANISH_ON_TOUCH:
			_activate_vanish()

func _bounce(body: Node2D) -> void:
	var character := body as CharacterBody2D
	if character == null:
		return
	character.velocity.y = -bounce_velocity
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.08, 0.55), 0.07)
	tween.tween_property(visual, "scale", Vector2(0.94, 1.25), 0.1)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE)

func _activate_crumble() -> void:
	if _activated:
		return
	_activated = true
	_available = false
	await _play_warning()
	_set_platform_enabled(false)
	var fall := create_tween().set_parallel(true)
	fall.tween_property(self, "position:y", _origin_position.y + fall_distance, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(visual, "modulate:a", 0.0, fall_duration * 0.75).set_delay(fall_duration * 0.25)
	await fall.finished
	await _recover_or_remain_hidden()

func _activate_vanish() -> void:
	if _activated:
		return
	_activated = true
	_available = false
	await _play_warning()
	var fade := create_tween()
	fade.tween_property(visual, "modulate:a", 0.0, 0.22)
	await fade.finished
	_set_platform_enabled(false)
	await _recover_or_remain_hidden()

func _run_blink_cycle() -> void:
	while is_inside_tree() and platform_type == PlatformType.BLINK:
		await get_tree().create_timer(visible_time).timeout
		if not is_inside_tree(): return
		_available = false
		await _play_warning(blink_warning_time)
		_set_platform_enabled(false)
		await get_tree().create_timer(hidden_time).timeout
		if not is_inside_tree(): return
		_set_platform_enabled(true)
		_available = true

func _play_warning(duration := -1.0) -> void:
	var actual_duration := trigger_delay if duration < 0.0 else duration
	if actual_duration <= 0.0:
		return
	var start_x := visual.position.x
	var shake := create_tween().set_loops(maxi(1, int(actual_duration / 0.08)))
	shake.tween_property(visual, "position:x", start_x + warning_shake_amount, 0.04)
	shake.tween_property(visual, "position:x", start_x - warning_shake_amount, 0.04)
	await shake.finished
	visual.position.x = start_x

func _recover_or_remain_hidden() -> void:
	if not recover_after_activation:
		return
	await get_tree().create_timer(recovery_time).timeout
	position = _origin_position
	rotation = _origin_rotation
	visual.modulate.a = 0.0
	_set_platform_enabled(true)
	var appear := create_tween()
	appear.tween_property(visual, "modulate:a", 1.0, 0.3)
	await appear.finished
	_available = true
	_activated = false

func _set_platform_enabled(enabled: bool) -> void:
	collision_shape.set_deferred("disabled", not enabled)
	visual.visible = enabled
	$Trigger.set_deferred("monitoring", enabled)

func _refresh_editor_preview() -> void:
	if is_inside_tree():
		call_deferred("_configure_nodes")
