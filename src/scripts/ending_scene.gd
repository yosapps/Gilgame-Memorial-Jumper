extends Node2D

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
	_show_result(ending)

func _show_result(ending: StringName) -> void:
	var content: Array = stories.get(ending, stories[&"incomplete_memory"])
	var bg := ColorRect.new(); bg.color = Color(0.025, 0.04, 0.08); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); $UI.add_child(bg)
	var title := Label.new(); title.text = content[0]; title.position = Vector2(176, 120); title.size = Vector2(800, 80); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 44); bg.add_child(title)
	var text := Label.new(); text.text = content[1]; text.position = Vector2(176, 245); text.size = Vector2(800, 180); text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; text.add_theme_font_size_override("font_size", 22); bg.add_child(text)
	var time := Label.new(); time.text = "CLEAR TIME  " + GameTimeManager.get_formatted_time(); time.position = Vector2(376, 445); time.size = Vector2(400, 40); time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bg.add_child(time)
	var button := Button.new(); button.text = "タイトルへ"; button.position = Vector2(476, 525); button.size = Vector2(200, 48); button.pressed.connect(_go_title); bg.add_child(button)
	button.grab_focus()

func _go_title() -> void:
	Global.pending_ending = &""
	get_tree().change_scene_to_file("res://src/scenes/title.tscn")
