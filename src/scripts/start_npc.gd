extends Area2D

@export var npc_name: String
@export var dialogue: Array[String]

var player_is_near := false
var talking := false
var page := 0

@onready var player: Node = %Player
@onready var prompt: Label = $Prompt
@onready var dialogue_box: PanelContainer = %DialogueLayer/DialogueBox
@onready var dialogue_name: Label = %DialogueLayer/DialogueBox/Margin/VBox/DialogueName
@onready var dialogue_text: Label = %DialogueLayer/DialogueBox/Margin/VBox/DialogueText
@onready var next_label: Label = %DialogueLayer/DialogueBox/Margin/VBox/Footer

func _ready() -> void:
	prompt.hide()
	dialogue_box.hide()

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
	talking = true
	page = 0
	player.is_can_move = false
	player.velocity = Vector2.ZERO
	player.jump_mode = false
	player.jump_force = 0
	dialogue_name.text = npc_name
	player.get_node("JumpBar").hide()
	prompt.hide()
	dialogue_box.show()
	show_page()

func advance_dialogue() -> void:
	page += 1
	if page >= dialogue.size():
		finish_dialogue()
	else:
		show_page()

func show_page() -> void:
	dialogue_text.text = dialogue[page]
	next_label.text = "E / Enter  次へ  (%d/%d)" % [page + 1, dialogue.size()]

func finish_dialogue() -> void:
	talking = false
	dialogue_box.hide()
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
	if talking and player != null:
		player.is_can_move = true
