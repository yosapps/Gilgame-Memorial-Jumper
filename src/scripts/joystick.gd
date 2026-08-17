extends Control


# ジョイスティック用のUI要素
@onready var base = $base
@onready var handle = $handle


# ジョイスティックのスケール（画面の高さに基づく）デフォルトは0.33（画面高さの33%）
@export_category("画面の高さに基づく")
@export_range(0,1) var joystick_scale:float = 0.33


# ジョイスティックの指のインデックス
# マルチタッチをサポートするため、画面上の指のインデックスまたはIDを追跡する必要があります
var joystick_finger_index = 0


# ジョイスティックUIのサイズ変数（_ready関数で設定）
var joystick_starting_size: float
var joystick_handle_starting_size: float


# タッチパッドの指のインデックス
# マルチタッチをサポートするため、画面上の指のインデックスまたはIDを追跡する必要があります
var touch_pad_finger_index = 0


# タッチパッド上の最後の位置を記録するベクトル
# 現在位置と最後の位置の差分がタッチパッドの出力になります
var touch_pad_last_position: Vector2 = Vector2.ZERO


# 正規化されたジョイスティックの最終出力（この値を読み取るには get_joystick() を使用）
var joystick: Vector2 = Vector2.ZERO


# タッチパッドの最終出力（この値を読み取るには get_touchpad_delta() を使用）
var touchpad_delta: Vector2 = Vector2.ZERO


# ウィンドウサイズ変数
var window_width = 0
var window_height = 0


func _ready():
	# 画面サイズの取得
	window_width = get_viewport().content_scale_size.x
	window_height = get_viewport().content_scale_size.y
	
	# ジョイスティックのベースとハンドルのサイズを画面の高さとスケールに基づいて設定
	joystick_starting_size = window_height * joystick_scale
	joystick_handle_starting_size = joystick_starting_size / 2
	
	# ジョイスティックのUI要素のサイズを設定
	base.size = Vector2(joystick_starting_size, joystick_starting_size)
	handle.size = Vector2(joystick_handle_starting_size, joystick_handle_starting_size)

func _input(event):
	# 入力がタッチかどうかを確認
	if event is InputEventScreenTouch:
		# タッチ開始時の処理
		if event.pressed:
			# タッチが画面の左側で、ジョイスティックがまだアクティブでない場合を確認
			if event.position.x * get_viewport().get_screen_transform().x.x < window_width / 2 and !joystick_finger_index:
				# ジョイスティックのタッチを開始
				base.show()
				handle.show()
				base.position = event.position - (base.size / 2)
				handle.position = event.position - (base.size / 2) + (handle.size / 2)
				joystick_finger_index = event.index
			else:
				# タッチパッドのタッチを開始
				touch_pad_last_position = event.position
				touch_pad_finger_index = event.index
		else:
			# タッチ終了時の処理
			if event.index == joystick_finger_index:
				# ジョイスティックタッチ終了時にUIを非表示にしてジョイスティックをリセット
				base.hide()
				handle.hide()
				joystick = Vector2.ZERO
				joystick_finger_index = null
			if event.index == touch_pad_finger_index:
				# タッチパッドのタッチ終了時
				touch_pad_finger_index = null
	# 入力がタッチドラッグかどうかを確認
	if event is InputEventScreenDrag:
		if event.index == joystick_finger_index:
			# ジョイスティックのドラッグ処理
			var handle_pos = event.position
			var handle_normalized = event.position
			
			handle_pos -= handle.size / 2
			
			handle_normalized -= (base.position + base.size / 2)
			handle_normalized = handle_normalized / (base.size / 2)
			
			joystick = handle_normalized / (base.size / 2)
			
			handle_normalized = handle_normalized.normalized()
			
			handle_normalized = handle_normalized * (base.size / 2)
			handle_normalized += (base.position + base.size / 2)
			handle_normalized -= handle.size / 2
			
			# タッチがジョイスティックのベース外に移動した場合、ハンドルの正規化された位置を使用
			# これにより、ジョイスティックのハンドルがベースの外に出ないようにする
			if event.position.distance_to(base.position + base.size / 2) < base.size.x / 2:
				handle.position = handle_pos
			else:
				handle.position = handle_normalized
			
		elif event.index == touch_pad_finger_index:
			# タッチパッドのドラッグ処理
			var movement = event.position - touch_pad_last_position
			touch_pad_last_position = event.position
			touchpad_delta += movement


# ジョイスティック値のゲッター
func get_joystick() -> Vector2:
	return joystick


# タッチパッド値のゲッター
# 重要: タッチパッド値を取得する際は必ず get_touchpad_delta 関数を使用
# 入力関数と更新関数が同期していない場合があるため、位置の変化を一時的に保存し、
# データが失われないようにする
func get_touchpad_delta() -> Vector2:
	var touchpad_delta_return = touchpad_delta
	touchpad_delta = Vector2.ZERO
	return touchpad_delta_return
