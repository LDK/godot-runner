extends Node2D
class_name Block

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is Hero:
		(body as Hero).die()
