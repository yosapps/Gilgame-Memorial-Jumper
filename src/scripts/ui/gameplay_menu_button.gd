class_name GameplayMenuButton
extends RefCounted

const NORMAL_TEXT := Color(0.22, 0.14, 0.07, 1.0)
const SELECTED_TEXT := Color(0.31, 0.17, 0.045, 1.0)

static func decorate(button: TextureButton, font: Font = null) -> void:
	if button.has_meta("storybook_decorated"):
		return
	button.set_meta("storybook_decorated", true)
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_ALL
	button.size = Vector2(154.0, 48.0)

	var panel := PanelContainer.new()
	panel.name = "StorybookPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_style(false))
	button.add_child(panel)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var crystal := Label.new()
	crystal.text = "♦"
	crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crystal.add_theme_color_override("font_color", Color(0.22, 0.61, 0.88, 1.0))
	crystal.add_theme_font_size_override("font_size", 21)
	if font != null: crystal.add_theme_font_override("font", font)
	row.add_child(crystal)

	var text := Label.new()
	text.text = "メニュー"
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_color_override("font_color", NORMAL_TEXT)
	text.add_theme_font_size_override("font_size", 18)
	if font != null: text.add_theme_font_override("font", font)
	row.add_child(text)

	button.mouse_entered.connect(_set_selected.bind(panel, text, true))
	button.mouse_exited.connect(func() -> void:
		if not button.has_focus():
			_set_selected(panel, text, false)
	)
	button.focus_entered.connect(_set_selected.bind(panel, text, true))
	button.focus_exited.connect(_set_selected.bind(panel, text, false))

static func _set_selected(panel: PanelContainer, text: Label, selected: bool) -> void:
	panel.add_theme_stylebox_override("panel", _make_style(selected))
	text.add_theme_color_override("font_color", SELECTED_TEXT if selected else NORMAL_TEXT)
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1.08, 1.04, 0.92, 1.0) if selected else Color.WHITE, 0.16)

static func _make_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.91, 0.7, 0.97) if selected else Color(0.92, 0.82, 0.62, 0.94)
	style.border_color = Color(0.75, 0.49, 0.15, 1.0) if selected else Color(0.5, 0.3, 0.11, 0.92)
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.16, 0.08, 0.02, 0.48)
	style.shadow_size = 6 if selected else 4
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	return style
