extends Node2D
class_name ScreenElements
@onready var circle_wipe:CircleWipe = $CircleWipe

func _on_player_wins() -> void:
	circle_wipe.close()
