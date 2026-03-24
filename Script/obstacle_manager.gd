#障碍物生成管理器

extends Node2D

class_name ObstacleManager

@export var obstacle_configs: Array[ObstacleData]
@export var min_gap: int = 2

#获取随机障碍物
func get_obstacle() -> ObstacleData:
	#初始化临时总权重
	var total_weight = 0
	#加权
	for config in obstacle_configs:
		total_weight += config.Weight
	
	var roll = randi_range(0, total_weight)
	var current_weight = 0
	for config in obstacle_configs:
		current_weight += config.Weight
		if roll < current_weight:
			return config
		
	return obstacle_configs[0]
