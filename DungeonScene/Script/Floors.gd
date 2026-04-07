extends Node2D

@export var dungeon_scene: PackedScene
@export var total_floors: int
@export var master_seed: int

func _ready() -> void:
	generate_all_floors()


func generate_all_floors():
	var rng = RandomNumberGenerator.new()
	rng.seed = master_seed
	
	for i in total_floors:
		var new_dungeon = dungeon_scene.instantiate()
		add_child(new_dungeon)
		new_dungeon.position.y = i * 5000
		var floor_seed = rng.randi()
		
		var manager = new_dungeon.get_node("TotalityManager")
		manager.setup_and_generate(floor_seed)
		
		
