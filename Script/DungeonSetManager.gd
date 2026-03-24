#房间数据管理器
#

extends Node2D

class_name RoomDataManager

@export var csv_file_path: String = "res://RoomType_and_Weight data.csv"
var room_types = []

func _ready() -> void:
	load_room_types(csv_file_path)

#获取数据
func load_room_types(path:String):

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("无法打开文件")
		return
	file.get_line() # 跳过表头

	while !file.eof_reached():
		var data = file.get_csv_line()
		if data.size() < 3:
			continue
			
		var room_data = {
			"ID": data[0],
			"RoomType": int(data[1]),
			"RoomWeight": int(data[2]),
			"TypeName": data[3]
		}

		room_types.append(room_data)
	print("房间数据管理器：已获取房间数据")

#给房间分类
func get_random_room_type():
	if room_types.is_empty():
		push_error("严重警告：room_types数组是空的！")
	
	var total_weigh = 0
	
	for r in room_types:
		total_weigh += int(r["RoomWeight"])
		
	if total_weigh <= 0:
		push_error("严重警告：总权重计算为0！")
		return 0
	
	var rand = randi_range(1, total_weigh)
	var sum = 0
		
	for r in room_types:
		var w = int(r["RoomWeight"])
		if w <= 0: continue
		
		sum += w
		if rand <= sum:
			#print("抽中房间：", r["RoomType"])
			return r["RoomType"]
	
	print("房间数据管理器：算法失败，触发兜底")
	return 0
	
