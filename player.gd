extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * SPEED
	var updown = Input.get_axis("up", "down")
	velocity.y = updown * SPEED

	move_and_slide()
