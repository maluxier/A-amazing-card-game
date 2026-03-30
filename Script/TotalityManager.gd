extends Node2D

@onready var room_data_manager: RoomDataManager = %RoomDataManager
@onready var dungeon_logic: DungeonLogic = $DungeonLogic
const MAP_DATA = preload("res://Script/Data/Map_data.tres")


@onready var obstatic_logic: ObstacleLogic = $"../ObstaticNode"
@onready var obstacle_manager: Obstacle_manager = %ObstacleManager


var World_obstacle: Dictionary
var World_wall: Dictionary
var World_corridor: Dictionary
var World_gap: Dictionary
var World_room: Dictionary

var leaf_node: Array[BSPNode]

var testint: int = 1

func _ready() -> void:
	obstatic_logic.WorldObstacle_change.connect(_on_obstatic_node_world_obstacle_change)
	obstatic_logic.WorldGap_change.connect(_on_obstatic_node_world_gap_change)
	
	room_data_manager.load_room_types(room_data_manager.csv_file_path)
	dungeon_logic.room_data_manager = room_data_manager
	dungeon_logic.generate_dungeon(MAP_DATA)
	obstatic_logic.generate_obstacle(leaf_node, World_obstacle, World_corridor, World_wall)
	obstacle_manager.test(testint)
	print(testint)


func _on_obstatic_node_world_obstacle_change(new_obstacle_occ: Dictionary) -> void:
	for obstacle in new_obstacle_occ:
		if not World_obstacle:
			World_obstacle[obstacle] = true


func _on_obstatic_node_world_gap_change(new_gap_occ: Dictionary) -> void:
	for gap in new_gap_occ:
		if not World_gap:
			World_gap[gap] = true
