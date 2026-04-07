extends Node2D
class_name totality_manager

@export var MAP_DATA = Resource
@export var Wall_scene: PackedScene

@export var dungeon_logic: DungeonLogic
@export var obstatic_logic: ObstacleLogic
@export var room_data_manager: RoomDataManager
@export var wall_set_logic: wallSetLogic

@export var test_tilemap: TileMapLayer



var World_obstacle: Dictionary = {}
var World_wall: Dictionary = {}
var World_corridor: Dictionary = {}
var World_gap: Dictionary = {}
var World_room: Dictionary = {}
var leaf_node: Array[BSPNode] = []


func setup_and_generate(seed_value: int):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	dungeon_logic.mySeed = rng
	obstatic_logic.mySeed = rng
	room_data_manager.mySeed = rng
	
	room_data_manager.load_room_types(room_data_manager.csv_file_path)
	dungeon_logic.room_data_manager = room_data_manager
	
	dungeon_logic.World_leaf_node_change.connect(_on_dungeon_logic_world_leaf_node_change)
	dungeon_logic.WorldRoom_change.connect(_on_dungeon_logic_world_room_change)
	dungeon_logic.WorldCorridor_change.connect(_on_dungeon_logic_world_corridor_change)
	wall_set_logic.WorldWall_change.connect(_on_wall_set_logic_world_wall_change)
	obstatic_logic.WorldObstacle_change.connect(_on_obstatic_node_world_obstacle_change)
	obstatic_logic.WorldGap_change.connect(_on_obstatic_node_world_gap_change)
	
	dungeon_logic.generate_dungeon(MAP_DATA)
	dungeon_logic.room_occupied(leaf_node)
	
	
	wall_set_logic.wall_occ(World_room, World_corridor)
	wall_set_logic.set_wall(World_wall, Wall_scene)
	
	obstatic_logic.generate_obstacle(leaf_node, World_obstacle, World_corridor, World_wall, World_gap)
	
	
	#test_set_tiles()
	#dungeon_logic.testSetTile(World_obstacle)
	#print(World_wall)
	#print(World_gap)
	#print(World_obstacle)
	#print(World_corridor)


func _on_obstatic_node_world_obstacle_change(new_obstacle_occ: Dictionary) -> void:
	for obstacle in new_obstacle_occ:
		if not World_obstacle.has(obstacle):
			World_obstacle[obstacle] = true


func _on_obstatic_node_world_gap_change(new_gap_occ: Dictionary) -> void:
	for gap in new_gap_occ:
		if not World_gap.has(gap):
			World_gap[gap] = true


func _on_dungeon_logic_world_leaf_node_change(new_leaf_node: Array[BSPNode]) -> void:
	leaf_node = new_leaf_node


func _on_dungeon_logic_world_room_change(new_room_occ: Dictionary) -> void:
	for room in new_room_occ:
		if not World_room.has(room):
			World_room[room] = true


func _on_wall_set_logic_world_wall_change(new_wall_occ: Dictionary) -> void:
	for wall in new_wall_occ:
		if not World_wall.has(wall):
			World_wall[wall] = true


func _on_dungeon_logic_world_corridor_change(new_corridor_occ: Dictionary) -> void:
	for corridor in new_corridor_occ:
		if not World_corridor.has(corridor) and not World_room.has(corridor):
			World_corridor[corridor] = true
		else:
			continue


#func test_set_tiles():
	#for obstacle in World_obstacle:
		#test_tilemap.set_cell(obstacle, 2, Vector2i(2, 10))
