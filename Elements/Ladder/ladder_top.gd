extends Area2D
class_name LadderTop

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = true

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = false
		runner.velocity.y = 0
