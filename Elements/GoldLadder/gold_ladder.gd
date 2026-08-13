extends Ladder
class_name GoldLadder

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var climb_zone: LadderClimbZone = $ClimbZone

var level: Level:
	set(value):
		if value != level:
			level = value

		if value:
			(value as Level).connect("all_gold_collected", _on_level_gold_collected)

var map: LevelMap:
	set(value):
		if value != map:
			map = value

var active: bool = false:
	set(value):
		if value != active:
			active = value

		if value:
			sprite.visible = true
			climb_zone.monitoring = true

func _ready() -> void:
	var parent = get_parent()
	if parent is LevelMap:
		map = parent
	
	var root_children := get_tree().root.get_child(0).get_children()
	
	for child in root_children:
		if child is Level:
			level = child as Level

func _on_level_gold_collected() -> void:
	active = true
