extends Node2D
class_name Spikes

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is Runner:
		var runner := body as Runner
		if runner.state != Runner.RunnerState.HANGING:
			runner.die()
