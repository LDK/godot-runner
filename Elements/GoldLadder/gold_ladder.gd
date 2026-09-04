extends Ladder
class_name GoldLadder

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var level: Level:
	set(value):
		print("GL level set value: ", value)
		if value != level:
			level = value

		if value:
			print("go go go")
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
	climb_zone.golden = true
	climb_zone.monitoring = false
	var parent = get_parent()
	if parent is LevelMap:
		map = parent
	
	var root = get_tree().current_scene as GameContainer
	if root.level:
		level = root.level

	print("root.level: ", root.level)
func _on_level_gold_collected() -> void:
	print("Got all the gold")
	active = true
	map.call_deferred("activate_golden_ladder")
