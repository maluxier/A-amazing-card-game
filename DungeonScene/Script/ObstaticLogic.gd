#障碍物生成器

extends Node2D
class_name ObstacleLogic

var mySeed: RandomNumberGenerator

signal WorldObstacle_change(new_obstacle_occ: Dictionary)
signal WorldGap_change(new_gap_occ: Dictionary)

@export var obstaclemap: TileMapLayer

var directions = [
	Vector2i(1,0), Vector2i(-1,0),
Vector2i(0,1), Vector2i(0,-1), 
Vector2i(1,1), Vector2i(-1,-1),
Vector2i(1,-1), Vector2i(-1,1)]

@export var test_obstacle: Array[Resource]

#根据种子需求重写的pick_random()方法
func pick_random_with_seed(array: Array, rng: RandomNumberGenerator):
	if array.is_empty(): return null
	
	var random_index = rng.randi_range(0, array.size() - 1)
	return array[random_index]


func generate_obstacle(leaf_node: Array[BSPNode], world_obstacle: Dictionary, world_corridor: Dictionary, world_wall: Dictionary, world_gap: Dictionary):
	for node in leaf_node:
		var rect = get_room(node)
		var place_times = 0
		var try_times = 0
		while place_times < 10 and try_times < 50:
			try_times += 1
			var obstacle_data = pick_random_with_seed(test_obstacle, mySeed)
			var place_coords = Vector2i(mySeed.randi_range(rect.position.x, rect.end.x), mySeed.randi_range(rect.position.y, rect.end.y))
			if obstacle_occupied(place_coords, obstacle_data, world_obstacle, world_wall, world_corridor, world_gap):
				place_times += 1


func get_room(node:BSPNode) -> Rect2i:
	if node.room.has_area():
		return node.room
	return Rect2i()


func obstacle_occupied(place_pos: Vector2i, obstacle_data: Resource, Obstacle_occ: Dictionary, Wall_occ: Dictionary, Corridor_occ: Dictionary, Gap_occ: Dictionary) -> bool:
	var temp_obstacle_coords = {}
	temp_obstacle_coords.clear()
	
	if obstacle_data.offset == null:
		print("障碍物生成器：没有障碍物数据")
		return false
	for v1 in obstacle_data.offset:
		var obstacle_world_coords = place_pos + v1
		while Obstacle_occ.has(obstacle_world_coords) or Wall_occ.has(obstacle_world_coords):
			temp_obstacle_coords.clear()
			return false
		
		if not temp_obstacle_coords.has(obstacle_world_coords):
			temp_obstacle_coords[obstacle_world_coords] = true
		
		
	var temp_gap_coords = {}
	temp_gap_coords.clear()
	
	var temp_obstacle_coords_keys = temp_obstacle_coords.keys()
	temp_obstacle_coords_keys.sort()
	
	for v1 in temp_obstacle_coords_keys:
		for v2 in directions:
			var gap_world_coords = v1 + v2
			while Obstacle_occ.has(gap_world_coords) or Corridor_occ.has(gap_world_coords):
				temp_gap_coords.clear()
				return false
			if not temp_gap_coords.has(gap_world_coords):
				if not temp_obstacle_coords.has(gap_world_coords):
					temp_gap_coords[gap_world_coords] = true
				else:
					continue
			
			
	WorldObstacle_change.emit(temp_obstacle_coords)
	print("障碍物生成器：障碍物已占位")
		
	WorldGap_change.emit(temp_gap_coords)
	print("障碍物生成器：间隔已占位")
		
	place_obstacle(place_pos, obstacle_data.obstacle_scene)
	return true


func place_obstacle(obstacle_place_coord:Vector2i, obstacle_ins_scene: PackedScene):
	var instance = obstacle_ins_scene.instantiate()
	var local_pos = obstaclemap.map_to_local(obstacle_place_coord)
	var offset = Vector2(obstaclemap.tile_set.tile_size)/2.0
	instance.position = local_pos - offset
	obstaclemap.add_child(instance)
	print("障碍物生成器：障碍物已生成")
	pass
