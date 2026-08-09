extends CanvasLayer
class_name HUD

@onready var score_label = $Control/Labels/Score
@onready var lives_label = $Control/Labels/Lives
@onready var level_label = $Control/Labels/Level

@onready var level:Level = get_parent()

@export var hero: Hero:
	set(value):
		if value is Hero:
			hero = value
			update_lives(hero.lives)
			hero.connect("lives_remaining", update_lives)		

func _ready() -> void:
	update_level(level.level_number)

func update_lives(val: int) -> void:
	lives_label.text = 'LIVES: ' + str(val)

func update_level(val: int) -> void:
	level_label.text = 'LEVEL: ' + str(val)
