#地牢生成逻辑
#作用：连接房间生成走廊、绘制基础地形、生成障碍物、生成墙壁
extends Node2D
class_name DungeonLogic

var map_size: Vector2i#单层地图尺寸
var min_splite_size = 0#最小分割块
var min_room_size = 0#最小房间块
var room_padding = 0#房间块与分割块之间的距离
var corridor_height = 0#走廊宽度
var split_depth = 0#BSP分割深度

@onready var tilemap: TileMapLayer = $TileMapLayer#地形瓦片地图

@onready var room_data_manager: RoomDataManager = %RoomDataManager


@onready var obstacle_manager: ObstacleManager = %ObstacleManager
@onready var obstacle_layer: TileMapLayer = $"../ObstaticNode/ObstacleLayer"#障碍物瓦片地图
@export var obstacle_parent: Node2D#每一个障碍物挂载的父级对象
var min_gap#障碍物间的最小间隔

var root_node: BSPNode#起始分割块
var leaf_node: Array[BSPNode] = []#子分割块
var corridors: Array[Rect2i] = []#走廊占用的瓦片范围


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
	root_node.create_room(min_room_size, room_padding)
	collect_room_leaf(root_node)
	generate_corridors(root_node)
	set_room_type()
	draw_tilemap()
	print("地牢生成逻辑：地牢生成完成")

#递归分割
func split_tree(node: BSPNode, depth: int):
	#判断是否需要分割
	if depth == 0: return
	#分割
	if node.split(min_room_size):
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


#寻找房间之间的中心点
func get_room_center(node:BSPNode) -> Vector2i:
	#如果房间是矩形，返回房间中心点
	if node.room.has_area():
		return node.room.get_center()
	print("地牢生成逻辑：已找到房间中心点")
	if randf() > 0.5:
		return get_room_center(node.left_child)
	else:
		return get_room_center(node.right_child)


#走廊占位
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
	print("地牢生成逻辑：已完成走廊占位")


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
	if randf() > 0.5:
		create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center2.x, center1.y), corridor_height)
		create_corridor_rect(Vector2i(center2.x, center1.y), Vector2i(center2.x, center2.y), corridor_height)
	else:
		create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center1.x, center2.y), corridor_height)
		create_corridor_rect(Vector2i(center1.x, center2.y), Vector2i(center2.x, center2.y), corridor_height)
	print("地牢生成逻辑：已配置走廊")


#分配房间类型
func set_room_type():
	#房间列表随机一个出生点
	var start_node = leaf_node.pick_random()
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
	
	var current_source_id = 0
	var current_atlas_coords = Vector2i(16, 10)
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
				current_source_id = 0
				current_atlas_coords = Vector2i(6, 4)
			1:
				current_source_id = 0
				current_atlas_coords = Vector2i(4, 4)
			2:
				current_source_id = 0
				current_atlas_coords = Vector2i(16, 10)
			3:
				current_source_id = 0
				current_atlas_coords = Vector2i(10, 2)
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				tilemap.set_cell(Vector2i(x, y), current_source_id, current_atlas_coords)
		
	print("地牢生成逻辑:已绘制瓦片")




#障碍物生成总方法
func generate_obstacle():
	min_gap = obstacle_manager.min_gap
	var occupied = {}
	
	for node in leaf_node:
		var rect = get_room_rect(node)
		for i in range(800):
			var data = obstacle_manager.get_obstacle()
			var pos = Vector2i(randi_range(rect.position.x, rect.end.x - data.Size.x), randi_range(rect.position.y, rect.end.y - data.Size.y))
			
			if can_place(pos, data.Size, occupied, rect):
				place_obstacle(pos, data, occupied)

#获取房间的rect
func get_room_rect(node: BSPNode) -> Rect2i:
	if node.room.has_area():
		return node.room
	return Rect2i()

#检查障碍物是否可放置
func can_place(pos:Vector2i, size: Vector2i, occupied: Dictionary, room_rect: Rect2i) -> bool:
	#设置表示障碍物范围的检测框
	var cheak_rect = Rect2i(pos.x - min_gap, pos.y - min_gap, size.x + min_gap*2, size.y + min_gap*2)
	#检测障碍物检测框是否超出房间范围
	if not room_rect.encloses(Rect2i(pos, size)):
		return false
	#检测坐标是否已经被占用
	for x in range(cheak_rect.position.x, cheak_rect.end.x):
		for y in range(cheak_rect.position.y, cheak_rect.end.y):
			if occupied.has(Vector2i(x, y)):
				return false
	
	return true

func tile_to_world_center(pos: Vector2i, size: Vector2i) -> Vector2:
	var pos_v2 = Vector2(pos)
	var size_v2 = Vector2(size)
	
	var center_offset = size_v2/2.0
	var bottom_fix = Vector2(0, 0.5)
	return obstacle_layer.map_to_local(pos_v2 + center_offset - bottom_fix)

#实例化障碍物
func place_obstacle(pos:Vector2i, data:ObstacleData, occupied: Dictionary):
	if data == null:
		print("传入的data是空的")
		return
	
	for x in range(pos.x, pos.x + data.Size.x):
		for y in range(pos.y, pos.y + data.Size.y):
			occupied[Vector2i(x, y)] = true
			
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(4,4))
	#print("正在检查data", data)
	#print("正在检查data.scenes", data.Scene)
	var instance = data.Scene.instantiate()
	obstacle_parent.add_child(instance)
	#instance.position = obstacle_layer.map_to_local(pos)
	instance.position = tile_to_world_center(pos, data.Size)
	instance.z_index = int(instance.position.y)

func wall_set():
	var used_cell = tilemap.get_used_cells()
	
	pass
