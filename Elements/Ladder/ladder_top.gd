extends Area2D
class_name LadderTop
@onready var win_sound: AudioStreamPlayer = $WinSound

var golden := false
var hide_on_gold := false
signal player_wins()

var entity_id: int

@onready var collision_box:CollisionShape2D = $CollisionShape2D
@onready var lid:StaticBody2D = $Lid
@onready var lid_collision:CollisionShape2D = $Lid/CollisionShape2D

func brief_pass_through() -> void:
	print("bpt")
	lid_collision.disabled = true
	await get_tree().create_timer(1.0).timeout
	lid_collision.disabled = false
	
func _on_area_entered(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = true
		#runner.center_runner_vertically_on_cell()
		print("TOP OF LADDER")
		if entity_id and runner.above_ladder != entity_id:
			runner.above_ladder = entity_id
	
		if golden:
			win_sound.play(0.0)
			player_wins.emit()
			get_tree().paused = true

func _on_area_exited(area: Area2D) -> void:
	if area is RunnerFoot:
		var foot = area as RunnerFoot
		var runner = foot.runner
		runner.top_of_ladder = false
		runner.velocity.y = 0

		if entity_id and runner.above_ladder == entity_id:
			runner.above_ladder = null
