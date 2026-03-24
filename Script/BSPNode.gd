#BSP算法类
#作用：分割地图、生成房间

extends RefCounted

class_name BSPNode

var bounds: Rect2i#当前分割块的边界
var left_child: BSPNode#分割后左边的子块
var right_child: BSPNode#分割后右边的子块
var room: Rect2i#分割块里的房间
var room_type:int = -1#-1为未分类，0为出生点，1为普通房


func _init(rect: Rect2i):
	bounds = rect


func split(min_split: int) -> bool:
	#判断是否已分割
	if left_child != null or right_child != null:
		return false
	#分割方向横or竖
	var split_horizontally = randf() > 0.5
	if bounds.size.x > bounds.size.y * 1:
		split_horizontally = false
	if bounds.size.y > bounds.size.x * 1:
		split_horizontally = true
	#判断能不能分割
	var max_split = (bounds.size.x if split_horizontally else bounds.size.y) - min_split
	if max_split <= min_split:
		return false
	#设置分割点
	var split_point = randi_range(min_split, max_split)
	#分割
	if split_horizontally:
		left_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y, bounds.size.x, split_point))
		right_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y + split_point, bounds.size.x, bounds.size.y - split_point))
	else:
		left_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y, split_point, bounds.size.y))
		right_child = BSPNode.new(Rect2i(bounds.position.x + split_point, bounds.position.y, bounds.size.x - split_point, bounds.size.y))
	return true

#分配房间
func create_room(min_room_size: int, padding: int):
	#递归
	if left_child != null or right_child != null:
		if left_child: left_child.create_room(min_room_size, padding)
		if right_child: right_child.create_room(min_room_size, padding)
	else:
		var max_w = bounds.size.x - padding * 2
		var max_h = bounds.size.y - padding * 2
		
		var safe_min_w = mini(min_room_size, max_w)
		var safe_min_h = mini(min_room_size, max_h)
		
		var room_w = randi_range(safe_min_w, max_w)#房间宽
		var room_h = randi_range(safe_min_h, max_h)#房间高
		
		#限制房间长宽比，防止出现面条房
		var max_ratio = 1.8
		if float(room_w) / float(room_h) > max_ratio:
			room_w = int(room_h * max_ratio)
		elif float(room_h) / float(room_w) > max_ratio:
			room_h = int(room_w * max_ratio)
		
		var max_x = maxi(padding, bounds.size.x - room_w - padding)
		var max_y = maxi(padding, bounds.size.y - room_h - padding)
		
		var room_pos_x = bounds.position.x + randi_range(padding, max_x)
		var room_pos_y = bounds.position.y + randi_range(padding, max_y)
		room = Rect2i(room_pos_x, room_pos_y, room_w, room_h)
