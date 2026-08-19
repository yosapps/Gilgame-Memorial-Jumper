class_name TitleMenuButton
extends Button

const ANIMATION_SECONDS := 0.2

var selection_amount := 0.0
var selection_tween: Tween

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_focus_from_mouse)
	focus_entered.connect(_show_selection)
	focus_exited.connect(_hide_selection)
	resized.connect(queue_redraw)
	var selected_text_color := Color(0.22, 0.12, 0.045, 1.0)
	add_theme_color_override("font_hover_color", selected_text_color)
	add_theme_color_override("font_focus_color", selected_text_color)
	add_theme_color_override("font_pressed_color", selected_text_color)

func _focus_from_mouse() -> void:
	if not disabled:
		grab_focus()

func _show_selection() -> void:
	_animate_selection(1.0)

func _hide_selection() -> void:
	_animate_selection(0.0)

func _animate_selection(target: float) -> void:
	if selection_tween != null:
		selection_tween.kill()
	selection_tween = create_tween()
	selection_tween.tween_method(_set_selection_amount, selection_amount, target, ANIMATION_SECONDS).set_trans(Tween.TRANS_SINE)

func _set_selection_amount(value: float) -> void:
	selection_amount = value
	queue_redraw()

func _draw() -> void:
	if selection_amount <= 0.001:
		return
	var color := Color(0.62, 0.36, 0.1, selection_amount)
	var center_y := size.y * 0.5
	var inward := 8.0 * selection_amount
	_draw_ornament(Vector2(-34.0 + inward, center_y), 1.0, color)
	_draw_ornament(Vector2(size.x + 34.0 - inward, center_y), -1.0, color)

func _draw_ornament(origin: Vector2, direction: float, color: Color) -> void:
	var tip := origin + Vector2(15.0 * direction, 0.0)
	draw_line(origin - Vector2(13.0 * direction, 0.0), tip, color, 2.0, true)
	draw_polyline(PackedVector2Array([
		tip - Vector2(8.0 * direction, 6.0), tip,
		tip - Vector2(8.0 * direction, -6.0)
	]), color, 2.0, true)
	draw_circle(origin - Vector2(14.0 * direction, 0.0), 2.5, color)
	draw_set_transform(origin - Vector2(5.0 * direction, 0.0), 0.0, Vector2(1.0, 0.65))
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, color, 1.2, true)
	draw_set_transform(Vector2.ZERO)
