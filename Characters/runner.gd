extends CharacterBody2D
class_name Runner

enum RunnerState { GROUND, HANGING, FALLING, CLIMBING, STUCK, DEAD, RECOVERING, RESPAWNING, FLUNG, ZIPPING }
var stateNames:Array[String] = ['Ground', 'Hanging', 'Falling', 'Climbing', 'Stuck', 'Dead', 'Recovering', 'Respawning', 'Flung', 'Zipping']

@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_box:CollisionShape2D = $CollisionShape2D

@export var walk_speed: float = 125.0
@export var climb_speed: float = 110.0
@export var zip_speed: float = 70.0
var zip_horiz_offset: float = 0.9

var level: Level:
	set(value):
		if value != level:
			level = value
			if level.map:
				map = level.map

var map: LevelMap:
	set(value):
		if value != map:
			map = value
			_on_set_map(map)

func center_runner_on_cell() -> void:
	var coords := my_coords()
	global_position = map.get_cell_center_global(coords)

func center_runner_vertically_on_cell() -> void:
	var coords := my_coords()
	global_position.y = map.get_cell_center_global(coords).y

func center_runner_horizontally_on_cell() -> void:
	var coords := my_coords()
	global_position.x = map.get_cell_center_global(coords).x

func _ready() -> void:
	await get_parent().ready

	if self is Hero:
		level = get_parent() as Level
	elif self is Enemy:
		level = get_parent().get_parent() as Level

	if level and level is Level:
		map = level.map
	pass

func my_coords() -> Vector2i:
	#print("my coords called")
	var local_pos = map.to_local(global_position)
	var cell_coords = map.local_to_map(local_pos)
	
	return cell_coords

#TODO: This function is ugly and stank. Clean it up.
func my_area() -> Variant:
	var cell_coords = my_coords()

	var state: RunnerState

	if self is Enemy:
		state = (self as Enemy).state
	elif self is Hero:
		state = (self as Hero).state

	var b = map.bar_at(cell_coords)
	if b:
		return b

	if state == RunnerState.CLIMBING:
		var l = map.ladder_at(cell_coords)
		if l:
			return l

	else:
		var p = map.platform_at(Vector2i(cell_coords.x, cell_coords.y + 1))
		if p:
			return p


	if state == RunnerState.GROUND:
		# Check for platform one cell to the left or right... sometimes if a runner is just on the edge
		# of the platform, they register as being on top of a blank space
		var p = map.platform_at(Vector2i(cell_coords.x - 1, cell_coords.y + 1))
		
		if !p:
			p = map.platform_at(Vector2i(cell_coords.x + 1, cell_coords.y + 1))
			
		if p:
			return p

	elif state == RunnerState.CLIMBING:
		# Check for ladder one cell down or up... sometimes if a runner is just on the edge of a ladder,
		# they register as being in a cell that does not contain the ladder.
		var l = map.ladder_at(Vector2i(cell_coords.x, cell_coords.y - 1))
		
		if !l:
			l = map.ladder_at(Vector2i(cell_coords.x, cell_coords.y + 1))

		if l:
			return l
	
	elif state == RunnerState.HANGING:
		# Check for bar one cell to the left or right... sometimes if a runner is just on the edge
		# of the bar, they register as being in a blank space
		b = map.bar_at(Vector2i(cell_coords.x - 1, cell_coords.y))
		
		if !b:
			b = map.bar_at(Vector2i(cell_coords.x + 1, cell_coords.y))

		if b:
			return b
	
	elif state == RunnerState.FALLING:
		# Check for where the runner will land.
		if map.level_drops.has(cell_coords):
			return map.level_drops[cell_coords]

	elif state == RunnerState.ZIPPING:
		var z = map.zipline_at(cell_coords)
		print("Z ", z, cell_coords)

		if z:
			return z

	else:
		var p = map.platform_at(Vector2i(cell_coords.x, cell_coords.y + 1))
		if p:
			return p

	return map.entity_at(cell_coords) # This will take one last pass at finding something or return null

func my_platform() -> Variant:
	var cell_coords = my_coords()

	for platform in map.platforms:
		if (platform.y == cell_coords.y + 1) and cell_coords.x >= platform.startX and cell_coords.x <= platform.endX:
			return platform
	
	return null

## LADDERS ##

var on_ladder := false
var top_of_ladder := false:
	set(value):
		if top_of_ladder != value:
			top_of_ladder = value

var bottom_of_ladder := false
var ladders_touched: Array[Ladder] = []

func add_ladder(ladder: Ladder) -> void:
	ladders_touched.push_front(ladder)
	_on_ladders_changed()

func remove_ladder(ladder: Ladder) -> void:
	if ladders_touched.has(ladder):
		ladders_touched.erase(ladder)
	_on_ladders_changed()

func _on_ladders_changed():
	var ladder_count = ladders_touched.size()
	on_ladder = ladder_count > 0

## BARS ##

var on_bar := false
var end_of_bar := false
var bars_touched: Array[Bar] = []

func add_bar(bar: Bar) -> void:
	bars_touched.push_front(bar)
	_on_bars_changed()

func remove_bar(bar: Bar) -> void:
	if bars_touched.has(bar):
		bars_touched.erase(bar)
	_on_bars_changed()

func _on_bars_changed():
	var bar_count = bars_touched.size()
	on_bar = bar_count > 0
	
## ZIPLINES ##

var on_zipline := false
var end_of_zipline := false
var ziplines_touched: Array[ZipLine] = []

var zipping_start: Variant = null
var zipping_end: Variant = null

func add_zipline(zipline: ZipLine) -> void:
	ziplines_touched.push_front(zipline)
	_on_ziplines_changed()

func remove_zipline(zipline: ZipLine) -> void:
	if ziplines_touched.has(zipline):
		ziplines_touched.erase(zipline)
	_on_ziplines_changed()

func _on_ziplines_changed():
	var zipline_count = ziplines_touched.size()
	on_zipline = zipline_count > 0
	
func _on_set_map(_map: LevelMap) -> void:
	pass
