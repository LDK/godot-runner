extends Area2D
class_name ZipLine

@export var is_left: bool = false

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
		runner.add_zipline(self)

func _on_area_exited(area: Area2D) -> void:
	pass
	#if area is RunnerClimbZone:
		#var runner = area.runner as Runner
		#if runner.bars_touched.has(self):
			#runner.remove_bar(self)
