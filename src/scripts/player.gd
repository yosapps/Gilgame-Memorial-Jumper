extends CharacterBody2D

const MAX_JUMP_FORCE := 1.2
const JOYSTICK_DEAD_ZONE := 0.005
const LARGE_FALL_DISTANCE := 300.0
const LANDING_ANIMATION_DURATION := 0.18

@export var SPEED := 300.0
@export var JUMP_VELOCITY := -500.0
@export var joystick: Control
@export var jump_touch: TouchScreenButton

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dust: CPUParticles2D = $Dust
@onready var jump_bar: ProgressBar = $JumpBar
@onready var jump_timer_node: Timer = $JumpTimer
@onready var jump_sound: AudioStreamPlayer2D = $JumpSe
@onready var hit_sound: AudioStreamPlayer2D = $HitSe

var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var temp_velocity := Vector2.ZERO

# These names remain public because cutscenes and level components control them.
var jump_mode := false
var jump_force := 0.0
var direction := 0.0
var is_can_move := true
var jump_timer := false
var slide_mode := false

var _fall_start_y := 0.0
var _was_on_floor := false
var _landing_animation_left := 0.0

func _ready() -> void:
	_was_on_floor = is_on_floor()
	_fall_start_y = global_position.y
	_play_animation(&"idle")

func _physics_process(delta: float) -> void:
	_update_jump_charge(delta)
	_handle_keyboard_jump()
	_apply_gravity(delta)
	direction = _get_movement_direction()
	_apply_jump_takeoff_direction()
	_apply_horizontal_velocity()

	temp_velocity = velocity
	var was_on_floor := is_on_floor()
	move_and_slide()
	_handle_landing(was_on_floor)
	_handle_air_collision()
	_update_animation(delta)
	_was_on_floor = is_on_floor()

func _update_jump_charge(delta: float) -> void:
	if not jump_mode: return
	jump_force = minf(jump_force + delta, MAX_JUMP_FORCE)
	jump_bar.value = jump_force

func _handle_keyboard_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_begin_jump()
	if Input.is_action_just_released("jump"):
		_release_jump()

func _begin_jump() -> void:
	if jump_mode or not is_on_floor() or not is_can_move: return
	jump_mode = true
	jump_force = 0.0
	jump_bar.value = 0.0
	if Global.show_jump_bar: jump_bar.show()

func _release_jump() -> void:
	if not jump_mode or not is_on_floor(): return
	jump_force = minf(jump_force, MAX_JUMP_FORCE)
	if jump_force > 0.0:
		velocity.y = JUMP_VELOCITY * jump_force
		jump_sound.play()
	jump_mode = false
	jump_timer = true
	jump_timer_node.start()
	jump_bar.hide()
	jump_force = 0.0

func _apply_gravity(delta: float) -> void:
	if is_on_floor(): return
	if _was_on_floor: _fall_start_y = global_position.y
	velocity.y += gravity * delta

func _get_movement_direction() -> float:
	if not is_on_floor() or not is_can_move: return 0.0
	var input_direction := Input.get_axis("left", "right")
	if joystick != null and joystick.has_method("get_joystick"):
		var joystick_x := float(joystick.get_joystick().x)
		if absf(joystick_x) > JOYSTICK_DEAD_ZONE:
			input_direction = signf(joystick_x)
	return input_direction

func _apply_jump_takeoff_direction() -> void:
	if not jump_timer or jump_bar.value <= 0.0 or not is_can_move: return
	jump_bar.value = 0.0
	direction = -1.0 if animated_sprite.flip_h else 1.0

func _apply_horizontal_velocity() -> void:
	if not is_can_move:
		velocity.x = 0.0
		return
	if direction != 0.0 and not jump_mode:
		velocity.x = direction * SPEED
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

func _handle_landing(was_on_floor: bool) -> void:
	if was_on_floor or not is_on_floor(): return
	var fall_distance := global_position.y - _fall_start_y
	if fall_distance > LARGE_FALL_DISTANCE:
		_landing_animation_left = LANDING_ANIMATION_DURATION
	_fall_start_y = global_position.y

func _handle_air_collision() -> void:
	if get_slide_collision_count() <= 0 or is_on_floor() or slide_mode: return
	var collision := get_slide_collision(0)
	if collision == null: return
	velocity = temp_velocity.bounce(collision.get_normal())
	hit_sound.play()

func _update_animation(delta: float) -> void:
	_landing_animation_left = maxf(_landing_animation_left - delta, 0.0)
	if is_on_floor():
		_update_ground_animation()
	else:
		_update_air_animation()

func _update_ground_animation() -> void:
	if jump_mode:
		dust.emitting = false
		_play_animation(&"prepare")
	elif direction != 0.0:
		dust.emitting = true
		animated_sprite.flip_v = false
		animated_sprite.flip_h = direction < 0.0
		_play_animation(&"run")
	elif _landing_animation_left > 0.0:
		dust.emitting = false
		_play_animation(&"down")
	else:
		dust.emitting = false
		_play_animation(&"idle")

func _update_air_animation() -> void:
	dust.emitting = false
	if not is_zero_approx(velocity.x):
		animated_sprite.flip_v = false
		if not slide_mode: animated_sprite.flip_h = velocity.x < 0.0
	_play_animation(&"jump-up" if velocity.y < 0.0 else &"jump-down")

func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)

func hide_jumpbar() -> void:
	Global.show_jump_bar = false
	jump_bar.hide()

func start_jump() -> void:
	_begin_jump()

func end_jump() -> void:
	_release_jump()

func _on_jump_timer_timeout() -> void:
	jump_timer = false

func flip_player(flip: bool) -> void:
	animated_sprite.flip_v = false
	animated_sprite.flip_h = flip
