extends Node2D
class_name ObstacleLogic


signal WorldObstacle_change(new_obstacle_occ: Dictionary)
signal WorldGap_change(new_gap_occ: Dictionary)

var directions = [
	Vector2i(1,0), Vector2i(-1,0),
Vector2i(0,1), Vector2i(0,-1), 
Vector2i(1,1), Vector2i(-1,-1),
Vector2i(1,-1), Vector2i(-1,1)]

@onready var obstacle_layer: TileMapLayer = $ObstacleLayer

func generate_obstacle(leaf_node: Array[BSPNode], world_obstacle: Dictionary, world_corridor: Dictionary, world_wall: Dictionary):
	for node in leaf_node:
		var rect = get_room(node)
		
		for i in range(200):
			var place_coords = Vector2i(randi_range(rect.position.x, rect.end.x), randi_range(rect.position.y, rect.end.y))
			
	pass

func get_room(node:BSPNode) -> Rect2i:
	if node.room.has_area():
		return node.room
	return Rect2i()


func obstacle_occupied(place_pos: Vector2i, obstacle_offset: Array[Vector2i], Obstacle_occ: Dictionary, Wall_occ: Dictionary, Corridor_occ: Dictionary, Gap_occ: Dictionary):
	var temp_obstacle_coords = {}
	temp_obstacle_coords.clear()
	for v1 in obstacle_offset:
		var obstacle_world_coords = place_pos + v1
		if Obstacle_occ.has(obstacle_world_coords) or Wall_occ.has(obstacle_world_coords) or Corridor_occ.has(obstacle_world_coords):
			temp_obstacle_coords.clear()
			return
		else:
			temp_obstacle_coords[obstacle_world_coords] = true
		
	var temp_gap_coords = {}
	temp_gap_coords.clear()
	for v1 in temp_obstacle_coords:
		for v2 in directions:
			var gap_world_coords = v1 + v2
			if Obstacle_occ.has(gap_world_coords) or Corridor_occ.has(gap_world_coords):
				temp_gap_coords.clear()
				return
			elif not temp_gap_coords.has(gap_world_coords):
				if not temp_obstacle_coords.has(gap_world_coords):
					temp_gap_coords[gap_world_coords] = true
				else:
					continue
			
		WorldObstacle_change.emit(temp_obstacle_coords)
				
		WorldGap_change.emit(temp_gap_coords)
		
		place_obstacle(place_pos)


func place_obstacle(obstacle_place_coord:Vector2i):
	pass
