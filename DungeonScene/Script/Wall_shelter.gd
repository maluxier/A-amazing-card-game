extends Area2D

@export var shelter_alpha = 0.6
@export var normal_alpha = 1.0
var target: CanvasItem

func _ready() -> void:
	target = get_parent().get_node("TileMapLayer")
	


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		fade_in()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		fade_out()


func fade_to(alpha: float):
	var tween = create_tween()
	tween.tween_property(target, "modulate:a", alpha, 0.1)


func fade_out():
	fade_to(normal_alpha)


func fade_in():
	fade_to(shelter_alpha)
