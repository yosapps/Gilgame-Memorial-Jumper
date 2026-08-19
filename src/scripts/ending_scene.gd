extends Node2D

@onready var result_panel: PanelContainer = $UI/ResultPanel
@onready var heading: Label = $UI/ResultPanel/Content/Heading
@onready var story: Label = $UI/ResultPanel/Content/Story
@onready var clear_time: Label = $UI/ResultPanel/Content/TimePanel/Time
@onready var credits_button: Button = $UI/ResultPanel/Content/CreditsButton
@onready var background_ending: TextureRect = $UI/Background

var stories := {
	&"ending_a": ["REUNION", "時空の外では、まだ短い時しか流れていなかった。\nガロードとギルガメは再び出会い、同じ夕焼けを眺めた。"],
	&"ending_b": ["THE LONG WAIT", "長い年月を越え、年老いたガロードは親友を見つけた。\n彼は生涯ずっと、ギルガメの帰りを信じていた。"],
	&"ending_c": ["MEMORY PASSED ON", "ガロードはもういない。けれど、その孫は小さな亀の親友の物語を知っていた。\n思い出は、時を越えて受け継がれていた。"],
	&"incomplete_memory": ["FRAGMENTS", "出口は開いた。けれど、大切な名前がまだ思い出せない。\n失われた記憶が、塔のどこかで待っている。"]
}

func _ready() -> void:
	GameTimeManager.stop_run()
	var ending := Global.pending_ending
	if ending.is_empty(): ending = EndingManager.determine_ending()
	var cinematic := EndingManager.get_ending_data(ending)
	if cinematic != null:
		await $MemoryCutscene.play_sequence(cinematic, false)
	if ending in [&"ending_a", &"ending_b", &"ending_c"]:
		SaveManager.mark_game_cleared()
	_show_result(ending)

func _show_result(ending: StringName) -> void:
	background_ending.show()
	var content: Array = stories.get(ending, stories[&"incomplete_memory"])
	heading.text = String(content[0])
	story.text = String(content[1])
	clear_time.text = "CLEAR TIME   %s" % GameTimeManager.get_formatted_time()
	result_panel.modulate.a = 0.0
	result_panel.scale = Vector2(0.97, 0.97)
	result_panel.show()
	await get_tree().process_frame
	result_panel.pivot_offset = result_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(result_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	credits_button.grab_focus()

func _go_credits() -> void:
	if not ClickSound.playing:
		ClickSound.play()
	get_tree().change_scene_to_file("res://src/scenes/credits.tscn")
