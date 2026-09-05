extends Node2D
class_name GameContainer

@export var starting_scene: PackedScene

@onready var hud: HUD = $HUD
@onready var level_container = $LevelContainer
@onready var screen_elements = $ScreenElements

var level: Level:
	set(value):
		if value != level:
			level = value
			value.hero.map = value.map
			hud.hero = value.hero
			
			value.map.connect("player_wins", _on_player_wins)
			
			for enemy in value.enemies.get_children():
				(enemy as Enemy).target = value.hero

func _on_player_wins() -> void:
	screen_elements.circle_wipe.close()
	screen_elements.win_sound.play(0.0)
	if level.next_scene and level.next_scene is PackedScene:
		load_scene(level.next_scene, true)
	
	screen_elements.circle_wipe.open()

func load_scene(packed: PackedScene, defer: bool = false) -> void:
	for child_level in level_container.get_children():
		child_level.queue_free()

	var scene = packed.instantiate()

	if defer:
		level_container.call_deferred("add_child", scene)
	else:
		level_container.add_child(scene)
	if defer:
		await scene.ready
	level = scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_scene(starting_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Pause and unpause
	if Input.is_action_just_pressed('pause'):
		toggle_pause_game()

	# Reset button
	if Input.is_action_just_pressed('reset'):
		get_tree().paused = false
		get_tree().reload_current_scene()

func toggle_pause_game() -> void:
	var tree = get_tree()
	tree.paused = !tree.paused
