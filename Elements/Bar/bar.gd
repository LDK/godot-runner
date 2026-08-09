extends Area2D
class_name Bar

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
		runner.add_bar(self)

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
		if runner.bars_touched.has(self):
			runner.remove_bar(self)
