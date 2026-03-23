extends RefCounted

class_name BSPNode

var bounds: Rect2i # 当前节点的边界
var left_child: BSPNode
var right_child: BSPNode
var room: Rect2i   # 实际生成的房间区域

# 房间类型枚举
enum RoomType { NONE, START, NORMAL, TREASURE, BOSS }
var room_type: RoomType = RoomType.NONE

func _init(rect: Rect2i):
	bounds = rect

# 分割空间
func split(min_size: int) -> bool:
	if left_child != null or right_child != null:
		return false # 已经分割过了
	
	# 决定横向还是纵向分割 (长宽比例悬殊时强制某种方向以防生成细长条)
	var split_horizontally = randf() > 0.5#随机分割方向
	if bounds.size.x > bounds.size.y * 1.25:#如果当前块的宽大于高的1.25倍
		split_horizontally = false
	elif bounds.size.y > bounds.size.x * 1.25:
		split_horizontally = true
		
	var max_split = (bounds.size.y if split_horizontally else bounds.size.x) - min_size#宽或高-最小切割块的大小（正方形）
	if max_split <= min_size:#小于等于说明切完一定有一块小于最小切割块
		return false # 空间太小，不能分割
	
	var split_point = randi_range(min_size, max_split)
	
	if split_horizontally:
		left_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y, bounds.size.x, split_point))
		right_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y + split_point, bounds.size.x, bounds.size.y - split_point))
	else:
		left_child = BSPNode.new(Rect2i(bounds.position.x, bounds.position.y, split_point, bounds.size.y))
		right_child = BSPNode.new(Rect2i(bounds.position.x + split_point, bounds.position.y, bounds.size.x - split_point, bounds.size.y))
		
	return true

# 递归在叶子节点创建房间
func create_rooms(min_room_size: int, padding: int):
	if left_child != null or right_child != null:
		if left_child: left_child.create_rooms(min_room_size, padding)
		if right_child: right_child.create_rooms(min_room_size, padding)
	else:
		# 这是叶子节点，在这里生成房间
		var room_w = randi_range(min_room_size, bounds.size.x - padding * 2)
		var room_h = randi_range(min_room_size, bounds.size.y - padding * 2)
		var room_x = bounds.position.x + randi_range(padding, bounds.size.x - room_w - padding)
		var room_y = bounds.position.y + randi_range(padding, bounds.size.y - room_h - padding)
		room = Rect2i(room_x, room_y, room_w, room_h)
