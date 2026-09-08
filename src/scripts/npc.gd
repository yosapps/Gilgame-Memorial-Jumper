extends Area2D

@export var profile: NpcDialogueProfile
@export var npc_name: String
@export_multiline var dialogue: Array[String]

var player_is_near := false
var talking := false
var page := 0

@onready var player: Node = %Player
@onready var prompt: Label = $Prompt
@onready var dialogue_box: PanelContainer = %DialogueLayer/DialogueBox
@onready var dialogue_name: Label = %DialogueLayer/DialogueBox/Margin/VBox/DialogueName
@onready var dialogue_portrait: TextureRect = %DialogueLayer/DialoguePortrait
@onready var dialogue_text: Label = %DialogueLayer/DialogueBox/Margin/VBox/DialogueText
@onready var next_label: Label = %DialogueLayer/DialogueBox/Margin/VBox/Footer

var active_dialogue: Array[String] = []

func _ready() -> void:
	prompt.hide()
	dialogue_box.hide()
	dialogue_portrait.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") or event.is_echo():
		return
	if talking:
		advance_dialogue()
	elif player_is_near:
		start_dialogue()
	else:
		return
	get_viewport().set_input_as_handled()

func start_dialogue() -> void:
	if player == null:
		return
	active_dialogue = _get_active_dialogue()
	if active_dialogue.is_empty():
		push_warning("NPC has no dialogue configured: %s" % name)
		return
	talking = true
	page = 0
	player.is_can_move = false
	player.velocity = Vector2.ZERO
	player.jump_mode = false
	player.jump_force = 0
	dialogue_name.text = _get_display_name()
	_apply_portrait()
	player.get_node("JumpBar").hide()
	prompt.hide()
	dialogue_box.show()
	show_page()

func advance_dialogue() -> void:
	page += 1
	if page >= active_dialogue.size():
		finish_dialogue()
	else:
		show_page()

func show_page() -> void:
	dialogue_text.text = active_dialogue[page]
	next_label.text = "E / Enter  次へ  (%d/%d)" % [page + 1, active_dialogue.size()]

func _get_display_name() -> String:
	if profile != null and not profile.display_name.is_empty():
		return profile.display_name
	return npc_name

func _get_active_dialogue() -> Array[String]:
	if profile != null and not profile.dialogue.is_empty():
		return profile.dialogue.duplicate()
	return dialogue.duplicate()

func _apply_portrait() -> void:
	if profile == null or profile.thumbnail == null:
		dialogue_portrait.texture = null
		dialogue_portrait.hide()
		return
	dialogue_portrait.texture = profile.thumbnail
	dialogue_portrait.size = profile.portrait_size
	dialogue_portrait.position = (get_viewport_rect().size - profile.portrait_size) * 0.5 + profile.portrait_screen_offset
	dialogue_portrait.modulate = profile.portrait_modulate
	dialogue_portrait.show()

func finish_dialogue() -> void:
	talking = false
	dialogue_box.hide()
	dialogue_portrait.hide()
	if player != null:
		player.is_can_move = true
	if player_is_near:
		prompt.show()

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player_is_near = true
		if not talking:
			prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_is_near = false
		prompt.hide()

func _exit_tree() -> void:
	if dialogue_portrait != null:
		dialogue_portrait.hide()
	if talking and player != null:
		player.is_can_move = true
