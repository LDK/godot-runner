extends Node2D
class_name Spikes

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is Hero:
		var hero := body as Hero
		if hero.state != Runner.RunnerState.HANGING:
			hero.die()
