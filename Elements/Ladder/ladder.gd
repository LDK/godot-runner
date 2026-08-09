extends Node2D
class_name Ladder
const LADDER_LANDING_MARGIN = 14

func _on_climb_zone_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		foot.runner.on_ladder = true
		foot.runner.add_ladder(self)

func _on_climb_zone_area_exited(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		if foot.runner.ladders_touched.has(self):
			foot.runner.remove_ladder(self)

func _on_climb_zone_body_entered(body: Node2D) -> void:
	if body is Runner:
		var runner = body as Runner
		runner.add_ladder(self)

		if runner.falling:
			print("Runner fell in")
			runner.falling = false
			runner.velocity.y = 0
			runner.position.y = position.y - LADDER_LANDING_MARGIN

func _on_climb_zone_body_exited(body: Node2D) -> void:
	if body is Runner:
		var runner = body as Runner
		if runner.ladders_touched.has(self):
			runner.remove_ladder(self)
