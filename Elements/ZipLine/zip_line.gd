extends Area2D
class_name ZipLine

@export var is_left: bool = false

signal zipline_entered(zipline_tile: ZipLine, runner: Runner)

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
	
		#print("zipline gp: ", global_position)
		zipline_entered.emit(self, runner)

		#if runner.state != Runner.RunnerState.GROUND:
			#runner.on_zipline = true
			#runner.add_zipline(self)
			#runner.zipping_start = 
			#runner.state = Runner.RunnerState.ZIPPING

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerClimbZone:
		var runner = area.runner as Runner
		if runner.ziplines_touched.has(self):
			runner.remove_zipline(self)
