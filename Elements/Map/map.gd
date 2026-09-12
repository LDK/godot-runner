extends MapAnalyzer
class_name LevelMap

@onready var scene: Node2D = get_tree().current_scene
var entities: Dictionary = {}

func sort_dict_y_asc(a:Dictionary, b:Dictionary) -> bool:
	if a.y < b.y:
		return true
	return false

func sort_y_asc_x_asc(a:Vector2i, b:Vector2i) -> bool:
	if a.y < b.y:
		return true
	elif a.y == b.y:
		return a.x < b.x
	return false

func sort_x_asc_y_asc(a:Vector2i, b:Vector2i) -> bool:
	if a.x < b.x:
		return true
	elif a.x == b.x:
		return a.y < b.y
	return false

func activate_golden_ladder() -> void:
	for child in get_children():
		if child is LadderBottom and child.golden:
			child.collision_box.disabled = false
		elif child is LadderBottom and child.hide_on_gold:
			child.collision_box.disabled = true
		elif child is LadderTop and child.golden:
			child.collision_box.disabled = false
		elif child is LadderTop and child.hide_on_gold:
			child.collision_box.disabled = true

func create_entity(type: String, def: Dictionary) -> Variant:
	if type not in ['platform', 'bar', 'ladder', 'zipline']:
		return null
	
	if not def.has('entity_id'):
		return null
	
	var entity: Dictionary
	entity.id = def.entity_id
	entity.type = type
	var exits: Array[int] = []
	entity.exits = exits
	entity.def = def

	for lid in def.ladders:
		entity.exits.push_back(lid)
	
	for bid in def.bars:
		entity.exits.push_back(bid)
	
	for pid in def.platforms:
		entity.exits.push_back(pid)

	for zid in def.ziplines:
		entity.exits.push_back(zid)

	return entity

func build_entity_list() -> Dictionary:
	entities = {}

	for ladder in ladders:
		var entity: Dictionary = create_entity('ladder', ladder)
		entities[entity.id] = entity

	for platform in platforms:
		if platform.has('unwalkable'):
			print("unwalkable platform:")
			print(platform)
			continue
		var entity: Dictionary = create_entity('platform', platform)
		entities[entity.id] = entity

	for bar in bars:
		var entity: Dictionary = create_entity('bar', bar)
		entities[entity.id] = entity

	for zipline in ziplines:
		var entity: Dictionary = create_entity('zipline', zipline)
		entities[entity.id] = entity

	return entities

func findEntitiesInExactOrder() -> void:
	find_ladders()
	used_cells.sort_custom(sort_y_asc_x_asc)
	find_platforms()
	find_bars()
	find_ziplines()
	find_spikes()

func findPlatformTransfersInExactOrder() -> void:
	find_platform_bars()
	find_platform_ladders()
	find_platform_ziplines()
	find_platform_drops()

func findLadderTransfersInExactOrder() -> void:
	find_ladder_platforms()
	find_ladder_ladders()
	find_ladder_bars()
	find_ladder_ziplines()

func findBarTransfersInExactOrder() -> void:
	find_bars_drop_locations()
	find_bars_climb_locations()
	add_bar_drop_lists()

func findZiplineTransfersInExactOrder() -> void:
	find_zipline_landings()
	find_ziplines_drop_locations()
	add_zipline_drop_lists()

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	
	findEntitiesInExactOrder()
	findPlatformTransfersInExactOrder()
	findLadderTransfersInExactOrder()
	findBarTransfersInExactOrder()
	findZiplineTransfersInExactOrder()
	
	entities = build_entity_list()

	findLandingSpots()

	#print("ENTITIES:")
	#for entity in entities:
		#print(entities[entity])

	#print("landing spots", level_drops)

	#print("bars: ")
	#for bar in bars:
		#print(bar)
#
	#print("ladders: ")
	#for ladder in ladders:
		#print(ladder)
#
	#print("platforms:")
	#for platform in platforms:
		#print(platform)
#
	#print("ziplines: ")
	#for zipline in ziplines:
		#print(zipline)


	print("spikes: ")
	for spikebed in spikes:
		print(spikebed)

	#print(build_entity_list())
	#print("------------")
	#print(" ")
	#print(" ")
	#
	#print(find_shortest_path(build_entity_list(), 8, 9))

func find_shortest_path(start_id: int, target_id: int) -> Array:
	print("from ", start_id, " to ", target_id)
	var already_there = (start_id == target_id)
	if already_there:
		return [start_id]
		
	# Queue stores arrays representing paths: e.g., [[1], [1, 7], [1, 9]]
	var queue: Array = [[start_id]]
	
	# Track visited nodes using a Dictionary for O(1) lookups (acting as a Set)
	var visited: Dictionary = { start_id: true }
	
	while not queue.is_empty():
		var current_path: Array = queue.pop_front()
		var current_node_id: int = current_path[-1]
		
		# Ensure the node exists in our graph data
		if not entities.has(current_node_id):
			continue
			
		var current_node_data: Dictionary = entities[current_node_id]
		var exits: Array = current_node_data.get("exits", [])
		
		for neighbor_id in exits:
			if not visited.has(neighbor_id):
				# Construct the new path including this neighbor
				var new_path: Array = current_path.duplicate()
				new_path.append(neighbor_id)
				
				# If we reached the target, return immediately
				if neighbor_id == target_id:
					return new_path
					
				visited[neighbor_id] = true
				queue.append(new_path)
				
	# Return empty array if no path connects the two IDs
	return []

func findLandingSpots() -> void:
	var x = top_left.x
	
	while x <= bot_right.x:
		var y = top_left.x
		while y <= bot_right.y:
			var droppable := false
			
			if get_cell_source_id(Vector2i(x, y)) == -1 or get_cell_alternative_tile(Vector2i(x, y)) == 4:
				if get_cell_source_id(Vector2i(x, y + 1)) == -1:
					droppable = true
			
			#var droppable: bool = get_cell_source_id(Vector2i(x, y)) == -1 and get_cell_source_id(Vector2i(x, y + 1)) == -1
			
			if droppable:
				var drop = find_drop_from(Vector2i(x, y))
				if drop:
					level_drops[Vector2i(x, y)] = drop

			y += 1

		x += 1
		
func on_player_wins() -> void:
	player_wins.emit()

func _on_child_entered_tree(node: Node) -> void:
	if node is ZipLine:
		var zipline = node as ZipLine
		zipline.connect('zipline_entered', _on_zipline_entered)

signal zipline_entered(tile: ZipLine, runner: Runner)

func _on_zipline_entered(tile: ZipLine, runner: Runner) -> void:
	zipline_entered.emit(tile, runner)
