extends Area2D
class_name LadderTop
@onready var win_sound: AudioStreamPlayer = $WinSound

var golden := false
var hide_on_gold := false
signal player_wins()

@onready var collision_box:CollisionShape2D = $CollisionShape2D

func _on_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = true
	
		if golden:
			print("GOLDEN")
			win_sound.play(0.0)
			player_wins.emit()
			get_tree().paused = true

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = false
		runner.velocity.y = 0
