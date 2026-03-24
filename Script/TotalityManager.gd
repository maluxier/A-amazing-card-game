extends Node2D

@onready var room_data_manager: RoomDataManager = %RoomDataManager
@onready var dungeon_logic: DungeonLogic = $DungeonLogic
const MAP_DATA = preload("res://Script/Data/MapData.tres")

@onready var obstacle_manager: ObstacleManager = %ObstacleManager
@onready var obstatic_node: Node2D = $ObstaticNode

func _ready() -> void:
	room_data_manager.load_room_types(room_data_manager.csv_file_path)
	dungeon_logic.room_data_manager = room_data_manager
	dungeon_logic.generate_dungeon(MAP_DATA)
	obstacle_manager.get_obstacle()
	dungeon_logic.generate_obstacle()
