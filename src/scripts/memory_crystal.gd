extends Area2D

@export var data: MemoryCrystalData
@export var bob_height := 6.0
@export var bob_speed := 2.0
@export_range(0.1, 3.0, 0.05) var collection_fade_duration := 0.8
@export var warp: Area2D
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
	if MemoryManager.is_collected(data.crystal_id):
		warp.show()
		queue_free()
	else:
		warp.hide()

func _process(_delta: float) -> void:
	$Visual.position.y = sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height
	$Visual.rotation = sin(Time.get_ticks_msec() * 0.0007) * 0.08
	if active and player != null:
		var closeness := 1.0 - clampf(global_position.distance_to(player.global_position) / 180.0, 0.0, 1.0)
		$Visual/Glow.energy = lerpf(0.7, 2.0, closeness)
		$Visual.modulate = Color(1.0, 1.0, 1.0, lerpf(0.72, 1.0, closeness))
		if ambient_player.stream != null: ambient_player.volume_db = lerpf(-30.0, -8.0, closeness)

func _on_body_entered(body: Node2D) -> void:
	if not active or not body.is_in_group("player") or data == null: return
	if not MemoryManager.can_collect(data.crystal_id): return
	active = false; monitoring = false
	if collection_player.stream != null: collection_player.play()
	_lock_player(body, true)
	$Visual/Particles.emitting = false
	var vanish := create_tween().set_parallel(true)
	vanish.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	vanish.tween_property($Visual, "modulate:a", 0.0, collection_fade_duration)
	vanish.tween_property($Visual, "scale", Vector2(1.35, 1.35), collection_fade_duration)
	vanish.tween_property($Visual/Glow, "energy", 0.0, collection_fade_duration)
	await vanish.finished
	var cutscene := get_tree().get_first_node_in_group("memory_cutscene")
	if cutscene == null:
		push_warning("MemoryCutscene is missing; collecting without playback.")
		_lock_player(body, false)
	else: await cutscene.play_memory(data)
	MemoryManager.collect_memory(data.crystal_id)
	warp.show()
	queue_free()

func _lock_player(target: Node, lock: bool) -> void:
	if target == null: return
	target.is_can_move = not lock
	if lock:
		target.velocity = Vector2.ZERO
		target.jump_mode = false
		target.jump_force = 0
