extends Area2D

@export var data: MemoryCrystalData
@export var bob_height := 6.0
@export var bob_speed := 2.0
var origin_y := 0.0
var active := true
var player: Node2D
var ambient_player: AudioStreamPlayer2D
var collection_player: AudioStreamPlayer2D

func _ready() -> void:
	origin_y = position.y
	player = get_tree().get_first_node_in_group("player") as Node2D
	ambient_player = AudioStreamPlayer2D.new(); add_child(ambient_player)
	collection_player = AudioStreamPlayer2D.new(); add_child(collection_player)
	if data == null:
		push_warning("Memory Crystal has no data."); active = false; return
	ambient_player.stream = data.ambient_sound
	if ambient_player.stream != null: ambient_player.play()
	collection_player.stream = data.collection_sound
	if MemoryManager.is_collected(data.crystal_id): queue_free()

func _process(_delta: float) -> void:
	$Visual.position.y = sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height
	$Visual.rotation = sin(Time.get_ticks_msec() * 0.0007) * 0.08
	if player != null:
		var closeness := 1.0 - clampf(global_position.distance_to(player.global_position) / 180.0, 0.0, 1.0)
		$Visual/Glow.energy = lerpf(0.7, 2.0, closeness)
		$Visual.modulate = Color(1.0, 1.0, 1.0, lerpf(0.72, 1.0, closeness))
		if ambient_player.stream != null: ambient_player.volume_db = lerpf(-30.0, -8.0, closeness)

func _on_body_entered(body: Node2D) -> void:
	if not active or not body.is_in_group("player") or data == null: return
	if not MemoryManager.can_collect(data.crystal_id): return
	active = false; monitoring = false
	if collection_player.stream != null: collection_player.play()
	var cutscene := get_tree().get_first_node_in_group("memory_cutscene")
	if cutscene == null:
		push_warning("MemoryCutscene is missing; collecting without playback.")
	else: await cutscene.play_memory(data)
	MemoryManager.collect_memory(data.crystal_id)
	queue_free()
