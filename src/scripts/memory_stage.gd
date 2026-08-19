class_name MemoryStage
extends Node2D

const TILE_SIZE := 16
const STAGE_WIDTH_TILES := 72
const FLOOR_Y := 35
const TERRAIN_SOURCE := 0
const TERRAIN_TILES := [Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(7, 1), Vector2i(11, 1)]
const CRYSTAL_SCENE := preload("res://src/scenes/memory_crystal.tscn")
const WARP_SCENE := preload("res://src/scenes/stages/memory/memory_stage_warp.tscn")

@export_range(1, 10, 1) var stage_index := 1

var stage_id: StringName
var memory_id: StringName
var _top_position := Vector2.ZERO
var _warp: Node
var _platforms: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	stage_id = StringName("memory_stage_%02d" % stage_index)
	memory_id = StringName("memory_%02d" % stage_index)
	_rng.seed = 7301 + stage_index * 1009
	_build_stage()
	_configure_player_and_camera()
	_create_crystal_and_warp()
	MemoryManager.memory_collected.connect(_on_memory_collected)
	GameTimeManager.start_run()
	$HUD/StageLabel.text = "MEMORY STAGE %02d  —  %s" % [stage_index, _stage_title()]
	$HUD/StageLabel.modulate = _theme_color().lightened(0.35)
	$BackgroundLayer/WorldBackground.color = _theme_color().darkened(0.82)
	var entrance := create_tween()
	entrance.tween_property($TransitionLayer/Fade, "modulate:a", 0.0, 0.65)
	if not Global.is_mobile_web:
		$HUD/Joystick.hide()
		$HUD/Jump.hide()
	_validate_stage()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		get_tree().paused = true
		$TimeUI.show_pause()
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	var profile := _profile()
	var terrain: TileMapLayer = $Terrain
	var tile: Vector2i = TERRAIN_TILES[(stage_index - 1) % TERRAIN_TILES.size()]
	_add_platform(terrain, 6, FLOOR_Y, STAGE_WIDTH_TILES - 12, tile)
	var platform_count := int(profile.count)
	var current_y := FLOOR_Y - 6
	var current_x := STAGE_WIDTH_TILES / 2
	var previous_x := current_x
	for index in platform_count:
		var gap := _rng.randi_range(int(profile.gap_min), int(profile.gap_max))
		current_y -= gap
		current_x = _next_platform_x(index, current_x, int(profile.shift))
		var is_rest := index % 8 == 7
		var width := 16 if is_rest else _rng.randi_range(int(profile.width_min), int(profile.width_max))
		var left := clampi(current_x - width / 2, 3, STAGE_WIDTH_TILES - width - 3)
		_add_platform(terrain, left, current_y, width, tile)
		_platforms.append({"center": Vector2((left + width * 0.5) * TILE_SIZE, current_y * TILE_SIZE), "width": width, "rest": is_rest})
		if index % int(profile.recovery_rate) == 2:
			var recovery_width := maxi(width + 3, 8)
			var recovery_center := (current_x + previous_x) / 2
			_add_platform(terrain, clampi(recovery_center - recovery_width / 2, 3, STAGE_WIDTH_TILES - recovery_width - 3), current_y + 3, recovery_width, tile)
		if index % 10 == 8:
			_add_landmark(terrain, left, current_y, width, tile)
		previous_x = current_x
	var top_y := current_y - 6
	var top_center := clampi(36, current_x - int(profile.shift), current_x + int(profile.shift))
	_add_platform(terrain, clampi(top_center - 12, 2, STAGE_WIDTH_TILES - 26), top_y, 24, tile)
	_platforms.append({"center": Vector2(top_center * TILE_SIZE, top_y * TILE_SIZE), "width": 24, "rest": true})
	_top_position = Vector2(top_center * TILE_SIZE, top_y * TILE_SIZE - 34)
	for y in range(top_y - 12, FLOOR_Y + 1):
		terrain.set_cell(Vector2i(0, y), TERRAIN_SOURCE, tile, 0)
		terrain.set_cell(Vector2i(STAGE_WIDTH_TILES - 1, y), TERRAIN_SOURCE, tile, 0)

func _next_platform_x(index: int, current_x: int, max_shift: int) -> int:
	var section := (index / 8 + stage_index) % 5
	var target := current_x
	match section:
		0: target += (-1 if index % 2 == 0 else 1) * _rng.randi_range(7, max_shift)
		1: target = (18 if (index / 4) % 2 == 0 else 54) + _rng.randi_range(-3, 3)
		2: target += (-1 if index % 2 == 0 else 1) * max_shift
		3: target = 36 + int(sin(float(index + stage_index) * 0.9) * float(max_shift))
		_: target += _rng.randi_range(-max_shift / 2, max_shift / 2)
	target = clampi(target, 7, STAGE_WIDTH_TILES - 8)
	return clampi(target, current_x - max_shift, current_x + max_shift)

func _add_platform(layer: TileMapLayer, left: int, y: int, width: int, tile: Vector2i) -> void:
	for x in range(left, left + width): layer.set_cell(Vector2i(x, y), TERRAIN_SOURCE, tile, 0)

func _add_landmark(layer: TileMapLayer, left: int, y: int, width: int, tile: Vector2i) -> void:
	for depth in 4:
		layer.set_cell(Vector2i(left, y + depth + 1), TERRAIN_SOURCE, tile, 0)
		layer.set_cell(Vector2i(left + width - 1, y + depth + 1), TERRAIN_SOURCE, tile, 0)

func _configure_player_and_camera() -> void:
	$Player.position = Vector2(36 * TILE_SIZE, FLOOR_Y * TILE_SIZE - 28)
	$Player/Camera2D.limit_left = 0
	$Player/Camera2D.limit_right = STAGE_WIDTH_TILES * TILE_SIZE
	$Player/Camera2D.limit_top = int(_top_position.y - 180.0)
	$Player/Camera2D.limit_bottom = 648

func _create_crystal_and_warp() -> void:
	var data := MemoryManager.get_memory_by_index(stage_index)
	if data == null:
		push_error("%s has no MemoryCrystalData for index %d." % [stage_id, stage_index])
		return
	var crystal := CRYSTAL_SCENE.instantiate()
	crystal.name = "MemoryCrystal%02d" % stage_index
	crystal.data = data
	crystal.position = _top_position
	add_child(crystal)
	_warp = WARP_SCENE.instantiate()
	_warp.name = "StageWarp"
	_warp.position = _top_position + Vector2(88 if _top_position.x < STAGE_WIDTH_TILES * TILE_SIZE * 0.62 else -88, 0)
	_warp.is_final_warp = stage_index == 10
	if stage_index < 10:
		_warp.destination_scene = "res://src/scenes/stages/memory/memory_stage_%02d.tscn" % (stage_index + 1)
	add_child(_warp)
	if MemoryManager.is_collected(memory_id):
		SaveManager.unlock_stage(stage_index)
		get_tree().create_timer(0.35).timeout.connect(_warp.activate)

func _on_memory_collected(data: MemoryCrystalData) -> void:
	if data.crystal_id != memory_id: return
	SaveManager.complete_stage(stage_id, mini(stage_index + 1, 10))
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(_warp): _warp.activate()

func _profile() -> Dictionary:
	return {
		"count": 32 + stage_index * 2,
		"gap_min": 5 + int(stage_index >= 5),
		"gap_max": 7 + int(stage_index >= 4) + int(stage_index >= 8),
		"width_min": maxi(3, 8 - stage_index / 2),
		"width_max": maxi(6, 13 - stage_index / 2),
		"shift": 9 + stage_index / 2,
		"recovery_rate": 4 + stage_index / 3,
	}

func _theme_color() -> Color:
	var colors := [Color("18344f"), Color("294762"), Color("315949"), Color("295e58"), Color("52633e"), Color("8a542e"), Color("463b4f"), Color("572f3b"), Color("382b52"), Color("26204f")]
	return colors[stage_index - 1]

func _stage_title() -> String:
	var titles := ["FIRST ENCOUNTER", "KINDNESS", "FIRST HAPPINESS", "TRUST", "FRIENDSHIP", "SUNSET", "RUMORS", "DISCOVERED", "ESCAPE", "THE TRUTH"]
	return titles[stage_index - 1]

func _validate_stage() -> void:
	if $Player == null: push_error("%s: Player is missing." % stage_id)
	if _warp == null: push_error("%s: Warp is missing." % stage_id)
	if _platforms.size() < 30: push_warning("%s is shorter than intended." % stage_id)
	if stage_index < 10 and (_warp == null or _warp.destination_scene.is_empty()): push_error("%s: next stage is missing." % stage_id)
	if stage_index == 10 and (_warp == null or not _warp.is_final_warp): push_error("Stage 10 must use the ending warp.")
	for index in range(1, _platforms.size()):
		var previous: Vector2 = _platforms[index - 1].center
		var current: Vector2 = _platforms[index].center
		if previous.y - current.y > 150.0: push_warning("%s platform %d exceeds vertical reach." % [stage_id, index])
		if absf(previous.x - current.x) > 290.0: push_warning("%s platform %d exceeds horizontal design limit." % [stage_id, index])

func debug_teleport_to_top() -> void:
	if OS.is_debug_build():
		$Player.global_position = _top_position + Vector2(0, -50)
		$Player.velocity = Vector2.ZERO

func debug_spawn_warp() -> void:
	if OS.is_debug_build() and is_instance_valid(_warp): _warp.activate()
