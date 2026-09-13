extends Area2D
class_name LadderZone

@onready var collision_box:CollisionShape2D = $CollisionShape2D

var entity_id: int

func _on_body_entered(body: Node2D) -> void:
	if !entity_id:
		print("No entity id")
		return

	if body is Runner:
		print("Hello")
		(body as Runner).on_ladder = entity_id
	else:
		if entity_id == 8:
			print("Other body: ", body.name)

func _on_body_exited(body: Node2D) -> void:
	if !entity_id:
		return

	if body is Runner:
		var runner = body as Runner
		if runner.on_ladder == entity_id:
			runner.on_ladder = null
