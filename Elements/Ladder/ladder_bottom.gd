extends Area2D
class_name LadderBottom

var golden := false
var hide_on_gold := false

@onready var collision_box:CollisionShape2D = $CollisionShape2D

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.bottom_of_ladder = true
		runner.state = Runner.RunnerState.GROUND

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.bottom_of_ladder = false
	
