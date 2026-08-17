extends CharacterBody2D

# プレイヤーの移動速度とジャンプの速度を設定
@export var SPEED = 300
@export var JUMP_VELOCITY = -500

# 入力用のUIコントロール（ジョイスティックとジャンプボタン）
@export var joystick:Control
@export var jump_touch:TouchScreenButton

# デフォルトの2D物理重力を取得
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 一時的な速度の保存用変数
var temp_velocity = Vector2.ZERO

# ジャンプ関連の状態フラグと値
var jump_mode = false
var jump_force = 0

# アニメーション状態と移動方向を追跡
var player_anim = "idle"
var direction = 0

# プレイヤーの最後のY位置とその更新状態
var last_pos_y = -99999
var is_last_posY = true

# 移動可能かどうかを制御するフラグ
var is_can_move = true

# ジャンプタイマーとスライドモードのフラグ
var jump_timer = false
var slide_mode = false

# 毎フレームの物理処理
func _physics_process(delta):
	# ジャンプモード中の処理
	if jump_mode:
		last_pos_y = position.y
		jump_force += delta
		$JumpBar.value = jump_force  # ジャンプバーの値を増加

	# 地面にいない場合は重力を適用
	if not is_on_floor():
		if is_last_posY:
			last_pos_y = position.y
			is_last_posY = false
		velocity.y += gravity * delta

	# ジャンプの入力処理
	if Input.is_action_just_pressed("jump") and is_on_floor() and is_can_move:
		jump_mode = true
		if Global.show_jump_bar:
			$JumpBar.show()

	# ジャンプ終了時の処理
	if Input.is_action_just_released("jump") and is_on_floor():
		if jump_force > 1.2:
			jump_force = 1.2  # ジャンプ力の最大値を制限
		velocity.y = JUMP_VELOCITY * jump_force
		if jump_force > 0:
			$JumpSe.playing = true  # ジャンプ音を再生
		jump_mode = false
		jump_timer = true
		$JumpTimer.start()
		$JumpBar.hide()
		jump_force = 0

	# 移動方向の取得
	direction = 0
	if is_on_floor() and is_can_move:
		direction = Input.get_axis("left", "right")  # キー入力で方向を設定
		if joystick.get_joystick().x > 0.005: # ジョイスティック入力で方向を設定
			direction = 1
		elif joystick.get_joystick().x < -0.005:
			direction = -1

	# ジャンプタイマー中の処理
	if jump_timer and $JumpBar.value > 0 and is_can_move:
		$JumpBar.value = 0
		if $AnimatedSprite2D.flip_h:
			direction = -1
		else:
			direction = 1

	# 水平方向の速度設定
	if direction and not jump_mode:
		velocity.x = direction * SPEED
		last_pos_y = position.y
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)  # 停止時に速度を減少

	# 衝突処理用の速度保存
	temp_velocity = velocity

	# 速度を適用してスライド移動
	move_and_slide()

	# アニメーションの更新
	update_animation()

	# 衝突処理（空中での壁への接触時）
	if get_slide_collision_count() > 0 and not is_on_floor() and not slide_mode:
		var collision = get_slide_collision(0)
		if collision != null:
			velocity = temp_velocity.bounce(collision.get_normal())  # 壁で跳ね返る
			$HitSe.playing = true  # 衝突音を再生

# プレイヤーのアニメーションを更新
func update_animation():
	if is_on_floor():
		if jump_mode:
			$Dust.emitting = false
			$AnimatedSprite2D.play("prepare")
		elif direction:
			$Dust.emitting = true
			$AnimatedSprite2D.play("run")
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.flip_h = direction < 0
		elif position.y > (last_pos_y + 300):
			$AnimatedSprite2D.play("down")
			$Dust.emitting = false
		else:
			$AnimatedSprite2D.play("idle")
			$Dust.emitting = false
	else:
		if velocity.x != 0:
			$AnimatedSprite2D.flip_v = false
			if not slide_mode:
				$AnimatedSprite2D.flip_h = velocity.x < 0
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump-up")
		else:
			$AnimatedSprite2D.play("jump-down")
		$Dust.emitting = false

# ジャンプバーを非表示にする
func hide_jumpbar():
	Global.show_jump_bar = false

# ジャンプを開始する
func start_jump():
	if not jump_mode and is_on_floor():
		jump_mode = true
		if Global.show_jump_bar:
			$JumpBar.show()

# ジャンプを終了する
func end_jump():
	if jump_mode and is_on_floor():
		if jump_force > 1.2:
			jump_force = 1.2
		velocity.y = JUMP_VELOCITY * jump_force
		if jump_force > 0:
			$JumpSe.playing = true
		jump_mode = false
		jump_timer = true
		$JumpTimer.start()
		$JumpBar.hide()
		jump_force = 0

# ジャンプタイマーのタイムアウト処理
func _on_jump_timer_timeout():
	jump_timer = false

# プレイヤーの向きを設定
func flip_player(flip):
	$AnimatedSprite2D.flip_v = false
	$AnimatedSprite2D.flip_h = flip
