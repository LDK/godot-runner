extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.on_bar = false
		
		if runner.is_on_floor():
			runner.state = Runner.RunnerState.GROUND
		elif runner.on_ladder:
			runner.state = Runner.RunnerState.CLIMBING
		else:
			runner.state = Runner.RunnerState.FALLING
