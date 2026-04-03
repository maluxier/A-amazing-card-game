extends Node2D

@export var map_size := Vector2i(100, 100)
@export var min_split_size := 15#最小切割块
@export var min_room_size := 6#最小房间块
@export var room_padding := 2#房间与切割块之间的距离

@onready var tilemap = $TileMapLayer # 确保你的场景里有 TileMap 或 TileMapLayer

# 预加载怪物/物品场景
@export var goblin_scene: PackedScene
@export var skeleton_scene: PackedScene
@export var boss_scene: PackedScene
@export var chest_scene: PackedScene

var root_node: BSPNode
var leaf_nodes: Array[BSPNode] = []
var corridors: Array[Rect2i] = []

func _ready():
	generate_dungeon()

func generate_dungeon():
	# 1. 初始化根节点
	root_node = BSPNode.new(Rect2i(0, 0, map_size.x, map_size.y))
	leaf_nodes.clear()
	corridors.clear()
	
	# 2. 递归分割空间
	_split_tree(root_node, 5) # 限制最大深度为5
	
	# 3. 生成房间
	root_node.create_rooms(min_room_size, room_padding)
	
	# 4. 提取所有的叶子节点 (包含房间的节点)
	_collect_leaf_nodes(root_node)
	
	# 5. 生成走廊
	_generate_corridors(root_node)
	
	# 6. 分配房间类型
	_assign_room_types()
	
	# 7. 绘制地图
	_draw_dungeon()
	
	# 8. 刷怪
	_spawn_entities()

# 递归分割
func _split_tree(node: BSPNode, depth: int):
	if depth == 0: return
	if node.split(min_split_size):
		_split_tree(node.left_child, depth - 1)
		_split_tree(node.right_child, depth - 1)


# 收集所有包含房间的叶子节点
func _collect_leaf_nodes(node: BSPNode):
	if node.left_child == null and node.right_child == null:
		leaf_nodes.append(node)
	else:
		if node.left_child: _collect_leaf_nodes(node.left_child)
		if node.right_child: _collect_leaf_nodes(node.right_child)


# 生成走廊 (连接兄弟节点)
func _generate_corridors(node: BSPNode):
	if node.left_child == null or node.right_child == null:
		return#return之后跳到上一级的_generate_corridors
	
	_generate_corridors(node.left_child)
	_generate_corridors(node.right_child)
	
	var center1 = _get_node_center(node.left_child)
	var center2 = _get_node_center(node.right_child)
	
	# 绘制L型走廊以确保走廊是直角
	if randf() > 0.5:
		_create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center2.x, center1.y))
		_create_corridor_rect(Vector2i(center2.x, center1.y), Vector2i(center2.x, center2.y))
	else:
		_create_corridor_rect(Vector2i(center1.x, center1.y), Vector2i(center1.x, center2.y))
		_create_corridor_rect(Vector2i(center1.x, center2.y), Vector2i(center2.x, center2.y))


#找到两个房间的中心点
func _get_node_center(node: BSPNode) -> Vector2i:
	if node.room.has_area():#如果返回true说明该分割块是最小单位，有房间，直接返回房间中心点
		return node.room.get_center()
	if randf() > 0.5:
		return _get_node_center(node.left_child)
	else:
		return _get_node_center(node.right_child)


func _create_corridor_rect(start: Vector2i, end: Vector2i):
	var rect = Rect2i()
	rect.position.x = min(start.x, end.x)
	rect.position.y = min(start.y, end.y)
	rect.size.x = abs(start.x - end.x) + 1 # 走廊宽度设为1或2
	rect.size.y = abs(start.y - end.y) + 1
	
	# 加宽走廊，确保玩家能通过
	if rect.size.x == 1: rect.size.x = 2
	if rect.size.y == 1: rect.size.y = 2
	
	corridors.append(rect)


func _assign_room_types():
	# 1. 随机选择一个出生点
	var start_node = leaf_nodes.pick_random()
	start_node.room_type = BSPNode.RoomType.START
	
	# 2. 找到距离出生点最远的房间作为 BOSS 房
	var start_center = start_node.room.get_center()
	var max_dist = 0.0
	var boss_node: BSPNode = null
	
	for node in leaf_nodes:
		if node.room_type == BSPNode.RoomType.START:
			continue
		var dist = start_center.distance_to(node.room.get_center())
		if dist > max_dist:
			max_dist = dist
			boss_node = node
			
	if boss_node:
		boss_node.room_type = BSPNode.RoomType.BOSS

	# 3. 剩下的房间分配为 普通 和 宝藏 房间#多个房间可能需要换成加权随机
	for node in leaf_nodes:
		if node.room_type != BSPNode.RoomType.NONE:
			continue # 跳过 START 和 BOSS
			
		if randf() < 0.15: # 15% 概率是宝藏房#可以加个房间类型限制，可能会需要循环限制
			node.room_type = BSPNode.RoomType.TREASURE
		else:
			node.room_type = BSPNode.RoomType.NORMAL


func _draw_dungeon():
	tilemap.clear()
	# 假设你的 TileMap 中: 0 是地面, 1 是墙壁
	var floor_source_id = 0
	var floor_atlas_coords = Vector2i(0, 0)#可能需要不同房间有不同地面和墙壁
		
	# 绘制房间
	for node in leaf_nodes:
		var r = node.room
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				tilemap.set_cell(Vector2i(x, y), floor_source_id, floor_atlas_coords)
				
	# 绘制走廊
	for c in corridors:
		for x in range(c.position.x, c.end.x):
			for y in range(c.position.y, c.end.y):
				tilemap.set_cell(Vector2i(x, y), floor_source_id, floor_atlas_coords)
				
	# 提示：你可以在这里加上外围包围墙壁的逻辑（遍历所有地面，发现周围是空的就放墙壁格子）


func _spawn_entities():
	for node in leaf_nodes:
		var r = node.room
		var tile_size = 16 # 根据你的TileMap实际大小修改 (通常是16或32)
		var center_pos = Vector2(r.get_center().x * tile_size, r.get_center().y * tile_size)
		
		match node.room_type:
			BSPNode.RoomType.START:
				# 可以在这里把玩家角色移动到 center_pos
				print("Start Room Generated")
				
			BSPNode.RoomType.BOSS:
				if boss_scene:
					var boss = boss_scene.instantiate()
					boss.position = center_pos
					add_child(boss)
					
			BSPNode.RoomType.TREASURE:
				if chest_scene:
					var chest = chest_scene.instantiate()
					chest.position = center_pos
					add_child(chest)
					
			BSPNode.RoomType.NORMAL:
				# 普通房间刷 1-3 只随机怪物
				var enemy_count = randi_range(1, 3)
				for i in range(enemy_count):
					# 随机在房间内挑个点
					var spawn_x = randi_range(r.position.x + 1, r.end.x - 2) * tile_size
					var spawn_y = randi_range(r.position.y + 1, r.end.y - 2) * tile_size
					
					var enemy: Node2D
					if randf() > 0.5 and goblin_scene:
						enemy = goblin_scene.instantiate()
					elif skeleton_scene:
						enemy = skeleton_scene.instantiate()
						
					if enemy:
						enemy.position = Vector2(spawn_x, spawn_y)
						add_child(enemy)
						print("enemy seied")
