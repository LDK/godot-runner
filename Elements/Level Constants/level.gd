extends Node2D
class_name Level
@onready var hud = $HUD

@export var hero: Hero
@export var level_number: int = 0
@export var map: LevelMap
@onready var circle_wipe:CircleWipe = $CircleWipe

var gold_count: int = 0:
	set(value):
		if value != gold_count:
			gold_count = value

var gold_collected: int = 0:
	set(value):
		if value != gold_collected:
			gold_collected = value
			if value == gold_count:
				all_gold_collected.emit()

signal all_gold_collected()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if hero is Hero:
		hud.hero = hero
		hero.connect("gold_collected", _on_hero_gold_collected)

	if map is LevelMap:
		map.connect("player_wins", _on_player_wins)

	var root_children := get_tree().root.get_child(0).get_children()

	gold_count = 0

	for child in root_children:
		#print("Child name: ", child.name)
		if child.name == 'Golds':
			var golds = child.get_children()
			gold_count += golds.size()
		
		if child.name == 'Enemies':
			for enemy in child.get_children():
				if (enemy as Enemy).has_gold:
					gold_count += 1

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('reset'):
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_hero_gold_collected() -> void:
	gold_collected = gold_collected + 1

func _on_player_wins() -> void:
	circle_wipe.close()
