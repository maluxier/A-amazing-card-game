#障碍物信息
#作用：储存障碍物信息，包括：名字、场景、大小、权重


extends Resource

class_name ObstacleData

@export var ObstacleName: String
@export var Scene: PackedScene
@export var Size: Vector2i
@export var Weight: int
