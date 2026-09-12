extends Area2D
class_name LadderClimbZone
@onready var ladder = get_parent()
@onready var collision_box = $CollisionShape2D

var golden := false
