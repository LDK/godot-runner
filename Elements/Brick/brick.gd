extends Dissolvable
class_name Brick

func transition_dissolve() -> void:
	sprite.play("dissolve")
	await sprite.animation_finished
	state = BrickState.EMPTY

func transition_refill() -> void:
	sprite.play("refill")
	await sprite.animation_finished
	state = BrickState.NORMAL

func _on_kill_zone_body_entered(bdy: Node2D) -> void:
	if bdy is Hero:
		(bdy as Hero).die()
	elif bdy is Enemy:
		(bdy as Enemy).die()
