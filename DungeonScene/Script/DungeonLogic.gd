#地牢生成逻辑
#作用：连接房间生成走廊、绘制基础地形、生成障碍物、生成墙壁
extends Node2D
class_name DungeonLogic

var mySeed: RandomNumberGenerator

@export var tilemap: TileMapLayer
@export var room_data_manager: RoomDataManager

signal World_leaf_node_change(new_leaf_node: Array[BSPNode])
signal WorldRoom_change(new_room_occ: Dictionary)
signal WorldCorridor_change(new_corridor_occ: Dictionary)


var map_size: Vector2i#单层地图尺寸
var min_splite_size: int#最小分割块
var min_room_size: int#最小房间块
var room_padding: int#房间块与分割块之间的距离
var corridor_height: int#走廊宽度
var split_depth: int#BSP分割深度


var root_node: BSPNode#起始分割块
var leaf_node: Array[BSPNode] = []#子分割块
var corridors: Array[Rect2i] = []#走廊占用的瓦片范围


#根据种子需求重写的pick_random()方法
func pick_random_with_seed(array: Array, rng: RandomNumberGenerator):
	if array.is_empty(): return null
	
	var random_index = rng.randi_range(0, array.size() - 1)
	return array[random_index]

#接入数据，生成单层地牢
func generate_dungeon(data:map_data):
	#接入数据
	if data == null:
		print("no data!")
		return
	
	map_size = data.MapSize
	min_splite_size = data.MinSpliteSize
	min_room_size = data.MinRoomSize
	room_padding = data.RoomPadding
	corridor_height = data.CorridorHeight
	split_depth = data.SplitDepth
	
	
	#初始化根节点
	root_node = BSPNode.new(Rect2i(0, 0, map_size.x, map_size.y))
	leaf_node.clear()
	corridors.clear()
	tilemap.clear()
	
	split_tree(root_node, split_depth)
	root_node.create_room(min_room_size, room_padding, mySeed)
	
	collect_room_leaf(root_node)
	World_leaf_node_change.emit(leaf_node)
	
	generate_corridors(root_node)
	corridor_occ(corridors)
	
	set_room_type()
	draw_tilemap()
	print("地牢生成逻辑：地牢生成完成")

#递归分割
func split_tree(node: BSPNode, depth: int):
	#判断是否需要分割
	if depth == 0: return
	#分割
	if node.split(min_room_size, mySeed):
		split_tree(node.left_child, depth - 1)
		split_tree(node.right_child, depth - 1)
	print("地牢生成逻辑：已分割地图")


#递归提取包含房间的分割块
func collect_room_leaf(node:BSPNode):
	#判断是否为最小分割块是则提取
	if node.left_child == null and node.right_child == null:
		leaf_node.append(node)
	#否则继续递归
	else:
		if node.left_child: collect_room_leaf(node.left_child)
		if node.right_child: collect_room_leaf(node.right_child)
	print("地牢生成逻辑：已提取房间分割块")

#房间占位方法
func room_occupied(leaf_node: Array[BSPNode]):
	for node in leaf_node:
		var temp_room_occ = {}
		temp_room_occ.clear()
		
		for x in range(node.room.position.x, node.room.end.x):
			for y in range(node.room.position.y, node.room.end.y):
				var room_coords = Vector2i(x, y)
				if not temp_room_occ.has(room_coords):
					temp_room_occ[room_coords] = true
		WorldRoom_change.emit(temp_room_occ)


#寻找房间之间的中心点
func get_room_center(node:BSPNode) -> Vector2i:
	#如果房间是矩形，返回房间中心点
	if node.room.has_area():
		return node.room.get_center()
	print("地牢生成逻辑：已找到房间中心点")
	if mySeed.randf() > 0.5:
		return get_room_center(node.left_child)
	else:
		return get_room_center(node.right_child)


#走廊标记
func create_corridor_rect(start:Vector2i, end:Vector2i, corridor_height: int):
	#用rect2i连接两个中心点
	var rect = Rect2i()
	rect.position.x = mini(start.x, end.x)
	rect.position.y = mini(start.y, end.y)
	rect.size.x = abs(start.x - end.x) + 1
	rect.size.y = abs(start.y - end.y) + 1
	#若走廊宽度不足加宽走廊
	if rect.size.x < corridor_height:
		rect.size.x = corridor_height
		rect.size.y += 1
	if rect.size.y < corridor_height:
		rect.size.y = corridor_height
		rect.size.x += 1
	
	corridors.append(rect)
	print("地牢生成逻辑：走廊已标记")

#走廊占位
func corridor_occ(corridors: Array[Rect2i]):
	if corridors.is_empty():
		print("地牢生成逻辑：走廊数据为空")
		
	var temp_corridor_occ = {}
	for corridor_rect in corridors:
		for x in range(corridor_rect.position.x, corridor_rect.end.x):
			for y in range(corridor_rect.position.y, corridor_rect.end.y):
				var corridor_coords = Vector2i(x, y)
				if not temp_corridor_occ.has(corridor_coords):
					temp_corridor_occ[corridor_coords] = true
					
	WorldCorridor_change.emit(temp_corridor_occ)
	print("地牢生成逻辑：走廊占位已完成")


#走廊生成（连接同级房间节点）
func generate_corridors(node:BSPNode):
	#检测有无子分割块，无则返回上级递归
	if node.left_child == null and node.right_child == null:
		return
	#有则继续递归
	generate_corridors(node.left_child)
	generate_corridors(node.right_child)
	#获取房间中心点
	var center1 = get_room_center(node.left_child)
	var center2 = get_room_center(node.right_child)
	#随机决定先水平还是先竖直#连接走廊
	if mySeed.randf() > 0.5:
		create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center2.x, center1.y), corridor_height)
		create_corridor_rect(Vector2i(center2.x, center1.y), Vector2i(center2.x, center2.y), corridor_height)
	else:
		create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center1.x, center2.y), corridor_height)
		create_corridor_rect(Vector2i(center1.x, center2.y), Vector2i(center2.x, center2.y), corridor_height)
	print("地牢生成逻辑：已配置走廊")


#分配房间类型
func set_room_type():
	#房间列表随机一个出生点
	var start_node = pick_random_with_seed(leaf_node, mySeed)
	start_node.room_type = 0
	print(start_node.room_type)
		
	for node in leaf_node:
		if node == start_node:
			continue
		node.room_type = room_data_manager.get_random_room_type()
		print(node.room_type)
	print("地牢生成逻辑：已分配房间类型")


#绘制瓦片
func draw_tilemap():
	#清空当前地图
	tilemap.clear()
	
	var current_source_id = 2
	var current_atlas_coords = Vector2i(17, 1)
	#绘制走廊
	for c in corridors:
		for x in range(c.position.x, c.end.x):
			for y in range(c.position.y, c.end.y):
				tilemap.set_cell(Vector2i(x, y), current_source_id, current_atlas_coords)
	
	#绘制房间
	for node in leaf_node:
		var r = node.room
		match node.room_type:
			0:
				current_source_id = 1
				current_atlas_coords = Vector2i(8, 1)
			1:
				current_source_id = 1
				current_atlas_coords = Vector2i(5, 21)
			2:
				current_source_id = 1
				current_atlas_coords = Vector2i(5, 1)
			3:
				current_source_id = 1
				current_atlas_coords = Vector2i(1, 20)
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				tilemap.set_cell(Vector2i(x, y), current_source_id, current_atlas_coords)
		
	print("地牢生成逻辑:已绘制瓦片")
