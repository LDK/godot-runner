extends Node2D
class_name Level
@onready var hud = $HUD

@export var hero: Hero
@export var level_number: int = 0
@export var map: LevelMap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if hero is Hero:
		hud.hero = hero

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('reset'):
		get_tree().reload_current_scene()
