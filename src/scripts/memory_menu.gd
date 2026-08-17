extends CanvasLayer

var panel: PanelContainer
var list: VBoxContainer
var counter: Label

func _ready() -> void:
	layer = 40; process_mode = Node.PROCESS_MODE_ALWAYS
	counter = Label.new(); counter.position = Vector2(18, 52); counter.text = "MEMORIES  %d / 10   [M]" % MemoryManager.get_collected_count(); add_child(counter)
	panel = PanelContainer.new(); panel.set_anchors_preset(Control.PRESET_CENTER); panel.position = Vector2(-240, -270); panel.size = Vector2(480, 540); add_child(panel)
	var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 24); margin.add_theme_constant_override("margin_right", 24); margin.add_theme_constant_override("margin_top", 18); margin.add_theme_constant_override("margin_bottom", 18); panel.add_child(margin)
	list = VBoxContainer.new(); margin.add_child(list)
	panel.hide(); MemoryManager.memory_collected.connect(_on_memory_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		if panel.visible: close_menu()
		else: open_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	for child in list.get_children(): child.queue_free()
	var title := Label.new(); title.text = "MEMORIES     %d / 10" % MemoryManager.get_collected_count(); title.add_theme_font_size_override("font_size", 26); list.add_child(title)
	for index in range(1, 11):
		var data := MemoryManager.get_memory_by_index(index)
		var button := Button.new(); button.text = "%02d  %s" % [index, data.display_name if MemoryManager.is_collected(data.crystal_id) else "???"]
		button.disabled = not MemoryManager.is_collected(data.crystal_id)
		button.pressed.connect(_replay.bind(data)); list.add_child(button)
	panel.show(); GameTimeManager.pause_timer(&"memory_menu")

func close_menu() -> void:
	panel.hide(); GameTimeManager.resume_timer(&"memory_menu")

func _replay(data: MemoryCrystalData) -> void:
	close_menu(); var cutscene := get_tree().get_first_node_in_group("memory_cutscene")
	if cutscene: await cutscene.play_memory(data)

func _on_memory_collected(_data: MemoryCrystalData) -> void:
	counter.text = "MEMORIES  %d / 10   [M]" % MemoryManager.get_collected_count()
	if panel.visible: open_menu()
