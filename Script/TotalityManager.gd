extends Node2D

const MAP_DATA = preload("res://Script/Data/Map_data.tres")


@onready var dungeon_logic: DungeonLogic = %DungeonLogic
@onready var obstatic_logic: ObstacleLogic = $"../ObstaticNode"
@onready var obstacle_manager: Obstacle_manager = %ObstacleManager
@onready var room_data_manager: RoomDataManager = %RoomDataManager

var World_obstacle: Dictionary = {}
var World_wall: Dictionary = {}
var World_corridor: Dictionary = {}
var World_gap: Dictionary = {}
var World_room: Dictionary = {}
var leaf_node: Array[BSPNode] = []


func _ready() -> void:
	room_data_manager.load_room_types(room_data_manager.csv_file_path)
	dungeon_logic.room_data_manager = room_data_manager
	
	dungeon_logic.World_leaf_node_change.connect(_on_dungeon_logic_world_leaf_node_change)
	dungeon_logic.WorldRoom_change.connect(_on_dungeon_logic_world_room_change)
	obstatic_logic.WorldObstacle_change.connect(_on_obstatic_node_world_obstacle_change)
	obstatic_logic.WorldGap_change.connect(_on_obstatic_node_world_gap_change)
	
	dungeon_logic.generate_dungeon(MAP_DATA)
	dungeon_logic.room_occupied(leaf_node)
	obstatic_logic.generate_obstacle(leaf_node, World_obstacle, World_corridor, World_wall, World_gap)


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
