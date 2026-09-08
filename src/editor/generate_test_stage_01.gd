@tool
extends EditorScript

## Re-runnable generator for TestStage01. The output scene contains no handwritten
## tile_map_data; every cell is authored through TileMapLayer.set_cell().
const OUTPUT_PATH := "res://src/scenes/stages/test/TestStage01.tscn"
const WARP_SCENE_PATH := "res://src/scenes/goal_warp.tscn"
const TILE_SET_PATH := "res://assets/sprites/layers/main.tres"
const GENERATED_TILE_SET_PATH := "res://src/scenes/stages/test/test_stage_01_tileset.tres"
const PLAYER_SCENE := preload("res://src/scenes/player.tscn")
const NPC_SCENE := preload("res://src/scenes/npc.tscn")
const CRYSTAL_SCENE := preload("res://src/scenes/memory_crystal.tscn")
const DIALOGUE_SCENE := preload("res://src/scenes/dialogue_layer.tscn")
const CUTSCENE_SCENE := preload("res://src/scenes/memory_cutscene.tscn")
const MEMORY_DATA := preload("res://src/resources/memories/memory_01.tres")
const WARP_SCRIPT := preload("res://src/scripts/memory_stage_warp.gd")

const SOURCE_ID := 0
const GROUND_TILE := Vector2i(1, 1)
const ONE_WAY_TILE := Vector2i(9, 1)
const BACKGROUND_TILE := Vector2i(19, 2)
const DECORATION_TILE := Vector2i(1, 3)
const HAZARD_TILE := Vector2i(13, 13)

# Maximum charged jump: v=600 px/s, g=1000 px/s² -> 180 px rise,
# 1.2 s same-height flight and 360 px theoretical horizontal travel.
const MAX_JUMP_HEIGHT_PX := 180.0
const MAX_HORIZONTAL_DISTANCE_PX := 360.0
const REQUIRED_ROUTE := [
	Vector2i(8, 34), Vector2i(18, 28), Vector2i(10, 22),
	Vector2i(21, 16), Vector2i(13, 10), Vector2i(24, 4),
]


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	_create_warp_scene()
	var stage := Node2D.new()
	stage.name = "TestStage01"

	var tile_set := load(TILE_SET_PATH) as TileSet
	if tile_set == null or tile_set.get_source(SOURCE_ID) == null:
		push_error("TestStage01 generator: TileSet/source 0 is missing.")
		return
	if not _validate_tile_ids(tile_set):
		return
	tile_set = tile_set.duplicate(true) as TileSet
	var atlas := tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	var one_way_data := atlas.get_tile_data(ONE_WAY_TILE, 0)
	if one_way_data != null and one_way_data.get_collision_polygons_count(0) > 0:
		one_way_data.set_collision_polygon_one_way(0, 0, true)
	ResourceSaver.save(tile_set, GENERATED_TILE_SET_PATH)

	var background := _add_layer(stage, "Background", tile_set, -20, false)
	var decoration_back := _add_layer(stage, "DecorationBack", tile_set, -10, false)
	var ground := _add_layer(stage, "Ground", tile_set, 0, true)
	var one_way := _add_layer(stage, "OneWayPlatforms", tile_set, 1, true)
	var hazards := _add_layer(stage, "Hazards", tile_set, 2, false)
	var decoration_front := _add_layer(stage, "DecorationFront", tile_set, 10, false)

	_fill_rect(background, Rect2i(0, -2, 34, 39), BACKGROUND_TILE)
	_fill_rect(ground, Rect2i(2, 35, 30, 2), GROUND_TILE)
	_fill_rect(ground, Rect2i(0, -3, 2, 40), GROUND_TILE)
	_fill_rect(ground, Rect2i(32, -3, 2, 40), GROUND_TILE)
	for center in REQUIRED_ROUTE:
		_place_platform(one_way, center, 7, ONE_WAY_TILE)
	for x in range(12, 17):
		hazards.set_cell(Vector2i(x, 34), SOURCE_ID, HAZARD_TILE)
	for cell in [Vector2i(4, 31), Vector2i(28, 25), Vector2i(4, 18), Vector2i(29, 8)]:
		decoration_back.set_cell(cell, SOURCE_ID, DECORATION_TILE)
	for cell in [Vector2i(3, 34), Vector2i(30, 34), Vector2i(5, 11), Vector2i(28, 3)]:
		decoration_front.set_cell(cell, SOURCE_ID, DECORATION_TILE)

	var player := PLAYER_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	player.name = "Player"
	player.position = Vector2(8 * 16, 33 * 16)
	player.unique_name_in_owner = true
	_add_owned(stage, player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -64)
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	player.add_child(camera)
	camera.owner = stage

	var dialogue := DIALOGUE_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	dialogue.name = "DialogueLayer"
	dialogue.unique_name_in_owner = true
	_add_owned(stage, dialogue)
	_add_owned(stage, CUTSCENE_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE))

	var npc := NPC_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	npc.name = "NPC"
	npc.position = Vector2(5 * 16, 33 * 16)
	_add_owned(stage, npc)

	var warp_pack := ResourceLoader.load(WARP_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	var warp := warp_pack.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Area2D
	warp.name = "GoalWarp"
	warp.position = Vector2(24 * 16, 2 * 16)
	warp.set("destination_scene", "res://src/scenes/title.tscn")
	_add_owned(stage, warp)

	var crystal := CRYSTAL_SCENE.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	crystal.name = "MemoryCrystal"
	crystal.position = Vector2(24 * 16, 2 * 16)
	crystal.set("data", MEMORY_DATA)
	crystal.set("warp", warp)
	_add_owned(stage, crystal)

	_validate_route()
	var packed := PackedScene.new()
	var result := packed.pack(stage)
	if result != OK:
		push_error("TestStage01 generator: could not pack scene (%s)." % error_string(result))
		stage.free()
		return
	result = ResourceSaver.save(packed, OUTPUT_PATH)
	stage.free()
	if result != OK:
		push_error("TestStage01 generator: could not save scene (%s)." % error_string(result))
		return
	print("Generated %s" % OUTPUT_PATH)


func _create_warp_scene() -> void:
	var warp := Area2D.new()
	warp.name = "GoalWarp"
	warp.set_script(WARP_SCRIPT)
	warp.collision_layer = 0
	warp.collision_mask = 1
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	warp.add_child(shape)
	shape.owner = warp
	warp.body_entered.connect(Callable(warp, "_on_body_entered"))
	var packed := PackedScene.new()
	if packed.pack(warp) == OK:
		ResourceSaver.save(packed, WARP_SCENE_PATH)
		var warp_uid := ResourceUID.create_id()
		ResourceSaver.set_uid(WARP_SCENE_PATH, warp_uid)
		ResourceUID.add_id(warp_uid, WARP_SCENE_PATH)
	warp.free()


func _add_layer(root: Node2D, layer_name: String, tile_set: TileSet, z: int, collision: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.z_index = z
	layer.collision_enabled = collision
	_add_owned(root, layer)
	return layer


func _add_owned(root: Node, child: Node) -> void:
	root.add_child(child)
	child.owner = root


func _fill_rect(layer: TileMapLayer, rect: Rect2i, atlas: Vector2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			layer.set_cell(Vector2i(x, y), SOURCE_ID, atlas)


func _place_platform(layer: TileMapLayer, center: Vector2i, width: int, atlas: Vector2i) -> void:
	for x in range(center.x - width / 2, center.x + width / 2 + 1):
		layer.set_cell(Vector2i(x, center.y), SOURCE_ID, atlas)


func _validate_route() -> void:
	for index in range(REQUIRED_ROUTE.size() - 1):
		var from_px := Vector2(REQUIRED_ROUTE[index]) * 16.0
		var to_px := Vector2(REQUIRED_ROUTE[index + 1]) * 16.0
		var rise := from_px.y - to_px.y
		var horizontal := absf(from_px.x - to_px.x)
		if rise > MAX_JUMP_HEIGHT_PX or horizontal > MAX_HORIZONTAL_DISTANCE_PX:
			push_error("Unreachable required platform %d -> %d" % [index, index + 1])


func _validate_tile_ids(tile_set: TileSet) -> bool:
	var atlas := tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	for coords in [GROUND_TILE, ONE_WAY_TILE, BACKGROUND_TILE, DECORATION_TILE, HAZARD_TILE]:
		if not atlas.has_tile(coords) or not atlas.has_alternative_tile(coords, 0):
			push_error("TestStage01 generator: missing atlas tile %s on source %d." % [coords, SOURCE_ID])
			return false
	return true
