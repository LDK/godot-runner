extends Area2D
class_name ZipLine

@export var is_left: bool = false

signal zipline_entered(zipline_tile: ZipLine, runner: Runner)

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
	
		zipline_entered.emit(self, runner)

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
		if runner.ziplines_touched.has(self):
			runner.remove_zipline(self)
