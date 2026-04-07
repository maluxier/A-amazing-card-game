#墙壁生成器
extends Node2D

class_name wallSetLogic

@export var wallLayer: TileMapLayer
@export var basicTerrainLayer: TileMapLayer

signal WorldWall_change(new_wall_occ: Dictionary)

func wall_occ(world_room: Dictionary, world_corridor: Dictionary):
	var used_cells = basicTerrainLayer.get_used_cells()
	if used_cells.is_empty():
		print("地牢生成逻辑：墙壁方法获取地图数据为空")
		return
	
	var direction = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1), 
		Vector2i(1,1), Vector2i(-1,-1),
		Vector2i(1,-1), Vector2i(-1,1)]
	
	var temp_wall_corrds = {}
	for cell in used_cells:
		for v1 in direction:
			var check_pos = cell + v1
			if not world_room.has(check_pos) and not world_corridor.has(check_pos):
				if not temp_wall_corrds.has(check_pos):
					temp_wall_corrds[check_pos] = true
			else:
				continue
		
	WorldWall_change.emit(temp_wall_corrds)
	print("地牢生成逻辑：已完成墙壁占位")


func set_wall(world_wall_occ: Dictionary, wall: PackedScene):
	if world_wall_occ.is_empty(): return
	if wall == null: return
	for wall_coord in world_wall_occ:
		var instance = wall.instantiate()
		var local_pos = wallLayer.map_to_local(wall_coord)
		var offset = Vector2(wallLayer.tile_set.tile_size)/2.0
		instance.position = local_pos - offset
		wallLayer.add_child(instance)
