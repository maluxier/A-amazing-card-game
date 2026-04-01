@tool
extends Resource
class_name ObstacleHub

@export var obstacle_scene: PackedScene
@export var offset: Array[Vector2i]
@export var back_offset_button: bool:
	set(value):
		if value:
			back_offset()
			back_offset_button = false

#获取障碍物每一格的偏移量
func back_offset():
	if obstacle_scene == null: return
	
	var instance = obstacle_scene.instantiate()
	var tilemap: TileMapLayer = instance.get_node("TileMapLayer")
	if tilemap == null: return
	var used_cells = tilemap.get_used_cells()
	if used_cells.is_empty(): return
	
	#获取左上角的格子
	var min_x = used_cells[0].x
	var min_y = used_cells[0].y
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		
	var origin = Vector2i(min_x, min_y)
	offset.clear()
	#计算偏移量并添加
	for cell in used_cells:
		offset.append(cell - origin)
