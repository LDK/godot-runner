extends Area2D
class_name LadderZone

@onready var collision_box:CollisionShape2D = $CollisionShape2D

var entity_id: int

func _on_body_entered(body: Node2D) -> void:
	if !entity_id:
		return

	if body is Runner:
		(body as Runner).on_ladder = entity_id

func _on_body_exited(body: Node2D) -> void:
	if !entity_id:
		return

	if body is Runner:
		var runner = body as Runner
		if runner.on_ladder == entity_id:
			runner.on_ladder = null
