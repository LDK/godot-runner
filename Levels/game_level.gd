extends Node2D
class_name Level

@onready var hero: Hero = $Hero
@onready var map: LevelMap = $Map
@onready var golds:Node2D = $Golds
@onready var enemies:Node2D = $Enemies

@export var next_scene:PackedScene

var gold_count: int = 0:
	set(value):
		if value != gold_count:
			gold_count = value

var gold_collected: int = 0:
	set(value):
		if value != gold_collected:
			gold_collected = value
			
			print("Gold collected: ", gold_collected, " of ", gold_count)
			
			if value == gold_count:
				all_gold_collected.emit()

				for child in map.get_children():
					if child is LadderBottom or child is LadderTop:
						var ladder_zone = child
						if ladder_zone.golden:
							ladder_zone.collision_box.set_deferred("disabled", false)

signal all_gold_collected()

func _on_hero_gold_collected() -> void:
	gold_collected = gold_collected + 1

func _ready() -> void:
	print("do I have a map: ", map)
	gold_count = golds.get_children().size()

	for enemy in enemies.get_children():
		enemy.map = map
		if (enemy as Enemy).has_gold:
			gold_count += 1

	hero.map = map
	hero.level = self
	hero.connect("gold_collected", _on_hero_gold_collected)
	
