extends Node2D

# シーン内のノードの参照を取得
@onready var transition = $HUB/Transition
@onready var color_rect = $HUB/Transition/ColorRect
@onready var time_ui = $TimeUI
var isPaused = false

func _ready():
	# 画面遷移のフェードインを実行
	color_rect.visible = true
	transition.play("fade_in")
	# モバイル環境でなければジョイスティックとジャンプボタンを非表示にする
	if !Global.is_mobile_web:
		$HUB/Joystick.hide()
		$HUB/Joystick.process_mode = Node.PROCESS_MODE_DISABLED
		$HUB/Jump.hide()
		$HUB/Jump.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	# ポーズボタンが押されたときの処理
	if event.is_action_pressed("pause"):
		if !ClickSound.playing: ClickSound.play() # クリック音を再生
		pause_event()

func pause_event():
	# ゲームをポーズする処理
	if not get_tree().is_paused():
		if !ClickSound.playing: ClickSound.play() # クリック音を再生
		get_tree().paused = true
		$TimeUI.show_pause() # ポーズ画面を表示

func go_title():
	# タイトル画面に戻る処理
	get_tree().paused = false # ポーズを解除
	get_tree().change_scene_to_file("res://src/scenes/title.tscn") # タイトルシーンへ移動

func reset():
	# 現在のシーンをリロードする処理
	get_tree().paused = false # ポーズを解除
	get_tree().reload_current_scene() # シーンを再読み込み
