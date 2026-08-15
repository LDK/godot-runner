extends TileMapLayer
class_name LevelMap

@onready var scene: Node2D = get_tree().current_scene

var tile_types := ['Empty', 'Brick', 'Block', 'Ladder', 'Bar', 'GoldLadder']

var entities: Dictionary = {}

func highest_value_on_plane(plane: String, cells: Array[Vector2i]) -> int:
	var highest: int = -9999

	for cell in cells:
		if cell[plane] > highest:
			highest = cell[plane]

	return highest

func lowest_value_on_plane(plane: String, cells: Array[Vector2i]) -> int:
	var lowest: int = 9999

	for cell in cells:
		if cell[plane] < lowest:
			lowest = cell[plane]

	return lowest

@onready var used_cells: Array[Vector2i] = get_used_cells()

@onready var top_left: Vector2i = Vector2i(
	lowest_value_on_plane('x', used_cells), 
	lowest_value_on_plane('y', used_cells)
)
@onready var bot_right: Vector2i = Vector2i(
	highest_value_on_plane('x', used_cells),
	highest_value_on_plane('y', used_cells)
)

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

var bars: Array[Dictionary] = []
var ladders: Array[Dictionary] = []
var platforms: Array[Dictionary] = []

var level_drops: Dictionary = {}

func find_bars() -> void:
	var foundBar := false
	var barStart: Variant = null
	var barEnd: int

	var y: int = top_left.y
	var x: int = top_left.x
	
	var bid: int = 1
	
	var eid_offset = ladders.size() + platforms.size()

	for cell_coords in used_cells:
		var barDef: Variant = null
		var id := get_cell_alternative_tile(cell_coords)
		
		if cell_coords.x != (x + 1):
			if foundBar and barStart:
				foundBar = false
				barEnd = x
				barDef = { "type": "bar", "y": y, "startX": barStart, "endX": barEnd, "id": bid, "entity_id": eid_offset + bid }
				bars.push_back(barDef)
				bid += 1
				find_bar_drop_platforms(barDef)
			
		if (id == 4): # Bar
			if !foundBar:
				foundBar = true
				barStart = cell_coords.x
		elif foundBar:
			foundBar = false
			barEnd = x
			barDef = { "type": "bar", "y": y, "startX": barStart, "endX": barEnd, "id": bid, "entity_id": eid_offset + bid }
			bid += 1
			bars.push_back(barDef)

		if cell_coords.y != y:
			y = cell_coords.y

		x = cell_coords.x

		if barDef:
			add_bar_zones(barDef)

func find_ladders() -> void:
	var foundLadder := false
	var ladderStart: Variant = null
	var ladderEnd: int

	var lid: int = 1

	var y: int = top_left.y
	var x: int = top_left.x

	var vert_cells = used_cells
	vert_cells.sort_custom(sort_x_asc_y_asc)
	var golden := false

	for cell_coords in vert_cells:
		var ladderDef: Variant = null
		var id := get_cell_alternative_tile(cell_coords)

		if id == 7: # Golden Ladder
			golden = true

		if cell_coords.y != (y + 1):
			if foundLadder and ladderStart:
				foundLadder = false
				ladderEnd = y
				ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": ladderEnd, "id": lid, "entity_id": lid }

				if golden:
					ladderDef.golden = true

				ladders.push_back(ladderDef)
				golden = false
				lid += 1
			
		if (id in [3, 7]): # Ladder
			if !foundLadder:
				foundLadder = true
				ladderStart = cell_coords.y
		elif foundLadder:
			foundLadder = false
			ladderEnd = y
			ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": ladderEnd, "id": lid, "entity_id": lid }

			if golden:
				ladderDef.golden = true

			ladders.push_back(ladderDef)
			golden = false
			lid += 1

		if ladderDef:
			add_ladder_zones(ladderDef)

		if cell_coords.x != x:
			x = cell_coords.x

		y = cell_coords.y

func get_cell_center_global(cell: Vector2i) -> Vector2:
	var local_center := map_to_local(cell)
	return to_global(local_center)

func find_platform_segments(platform: Dictionary) -> Array[Dictionary]:
	var x: int = platform.startX
	
	var blocked: Array[int] = []
	
	while x <= platform.endX:
		if platform_at(Vector2i(x, platform.y - 1)):
			blocked.push_back(x)

		x += 1
	
	if blocked.size():
		if blocked.size() >= (platform.endX - platform.startX):
			# Whole thing is blocked. Still return it so it can be used to check against for other platforms. 
			platform.unwalkable = true
			return [platform]
		else:
			var idx := 0
			var blocked_areas: Array[Array] = []
			var startX := blocked[0]
			var lastX := -9999
			var starts: Array[int] = []

			while idx <= blocked.size() - 1:
				if (
					# Tile is not contiguous with previous tile and isn't the first tile in the block...
					((not blocked[idx] == lastX + 1) and lastX != -9999) or
					# ...or this is the last tile of the block & it doesn't go up to the edge of the underlying platform
					(idx == blocked.size() - 1 and lastX < platform.endX)
				):
					blocked_areas.push_back([startX, (lastX if (idx != blocked.size() - 1) else blocked[idx])])
					starts.push_back(startX)

					# Start a new one
					startX = blocked[idx]

				lastX = blocked[idx]
				idx += 1
			
			var new_platforms: Array[Dictionary] = []
			var startBlocked := false
			var endBlocked := false

			idx = 0
			
			for area in blocked_areas:
				var blockStart = blocked[0]
				var blockEnd = blocked[1] if blocked.size() > 1 else blocked[0]

				if blockStart <= platform.startX:
					platform.startX = blockEnd + 1
					startBlocked = true

				if blockEnd >= platform.endX:
					platform.endX = blockEnd - 1
					endBlocked = true

				var new_platform: Dictionary = platform.duplicate()
				
				if !startBlocked and !new_platforms.size():
					new_platform.endX = blockStart - 1
				else:
					new_platform.startX = blockEnd + 1
					new_platform.endX = blocked_areas[(idx + 1)][1] if (blocked_areas.size() > idx + 1) else area[1]
				idx += 1

				new_platforms.push_back(new_platform)
			
			if !endBlocked:
				var new_platform: Dictionary = platform.duplicate()
				new_platform.startX = lastX + 1
				new_platforms.push_back(new_platform)

			return new_platforms
	else:
		return [platform]

func find_platforms() -> void:
	var foundPlatform := false
	var platformStart: Variant = null
	var platformEnd: int

	var pid: int = 1

	var y: int = top_left.y
	var x: int = top_left.x

	var platform_types = [1,2,3] # Bricks, Blocks or Ladders can be considered part of a platform

	var allLadders := false

	var eid_offset = ladders.size()

	var idx = -1

	for cell_coords in used_cells:
		idx += 1

		var platformDef: Variant = null
		var id := get_cell_alternative_tile(cell_coords)

		if cell_coords.x != (x + 1):
			if foundPlatform:
				foundPlatform = false

				if not allLadders:
					platformEnd = x
					platformDef = { "type": "platform", "y": y, "startX": platformStart, "endX": platformEnd, "id": pid, "entity_id": pid + eid_offset }
				else:
					allLadders = false

		if (id in platform_types):
			if !foundPlatform:
				foundPlatform = true
				platformStart = cell_coords.x
				if id in [3, 7]:
					allLadders = true
			
			if id not in [3, 7]:
				allLadders= false

		if foundPlatform and (id not in platform_types or idx == used_cells.size() - 1):
			foundPlatform = false
			
			if not allLadders:
				platformEnd = cell_coords.x if idx == used_cells.size() - 1 else x
				platformDef = { "type": "platform", "y": y, "startX": platformStart, "endX": platformEnd, "id": pid, "entity_id": pid + eid_offset }
		
			else:
				allLadders = false

		if cell_coords.y != y:
			y = cell_coords.y

		x = cell_coords.x
		
		if platformDef:
			var segments := find_platform_segments(platformDef)

			if segments.size() == 1:
				if platformStart == platformEnd:
					var cell_id = get_cell_alternative_tile(Vector2i(platformStart, y))
					if cell_id in [3, 7]:
						#print("that's also just a ladder piece", cell_coords)
						pass
					else:
						platforms.push_back(platformDef)
						pid += 1
				else:
					platforms.push_back(platformDef)
					pid += 1
			else:
				for segment in segments:
					segment.id = pid
					segment.entity_id = pid + eid_offset
					platforms.push_back(segment)
					pid += 1


func check_ladder_at_coords(x: int, y: int, dict_arr: Array[int]) -> void:
	var tile_id = get_cell_alternative_tile(Vector2i(x,y))

	if (tile_id in [3, 7]): # Ladder
		for ladder in ladders:
			if ladder.x == x and (ladder.startY == y or ladder.endY == y):
				dict_arr.push_back(ladder.entity_id)

func find_platform_drops() -> void:
	platforms.sort_custom(sort_dict_y_asc)

	var blockedLeft := false
	var blockedRight := false

	for platform in platforms:
		var y = platform.y + 1
		var leftX = platform.startX - 1
		var rightX = platform.endX + 1
		var dropLeft: Variant = null
		var dropRight: Variant = null

		var barLeft := false
		var barRight := false

		var pids:Array[int] = platform.platforms if platform.has('platforms') else ([] as Array[int])
		var lids:Array[int] = platform.ladders if platform.has('ladders') else ([] as Array[int])
		var bids:Array[int] = platform.bars if platform.has('bars') else ([] as Array[int])

		if get_cell_alternative_tile(Vector2i(leftX, platform.y - 1)) == 4:
			barLeft = true

		if get_cell_alternative_tile(Vector2i(rightX, platform.y - 1)) == 4:
			barRight = true
		
		#if platform_at(Vector2i(leftX, platform.y)):
		if get_cell_alternative_tile(Vector2i(leftX, platform.y)) in [1,2,3]:
			blockedLeft = true

		if get_cell_alternative_tile(Vector2i(rightX, platform.y)) in [1,2,3]:
			blockedRight = true

		while y <= bot_right.y:
			if !dropLeft and !barLeft and !blockedLeft:
				var p = platform_at(Vector2i(leftX, y))
				var l = ladder_at(Vector2i(leftX, y))
				var b = bar_at(Vector2i(leftX, y))
				
				if p:
					dropLeft = p.id
					if p.entity_id not in pids:
						pids.push_back(p.entity_id)
				elif l:
					dropLeft = l.id
					if l.entity_id not in lids:
						lids.push_back(l.entity_id)
				elif b:
					dropLeft = b.id
					if b.entity_id not in bids:
						bids.push_back(b.entity_id)

			if !dropRight and !barRight and !blockedRight:
				var p = platform_at(Vector2i(rightX, y))
				var l = ladder_at(Vector2i(rightX, y))
				var b = bar_at(Vector2i(rightX, y))
				
				if p:
					dropRight = p.entity_id
					if p.entity_id not in pids:
						pids.push_back(p.entity_id)
				elif l:
					dropRight = l.entity_id
					if l.entity_id not in lids:
						lids.push_back(l.entity_id)
				elif b:
					dropRight = b.entity_id
					if b.entity_id not in bids:
						bids.push_back(b.entity_id)

			y += 1

		platform.platforms = pids
		platform.bars = bids
		platform.ladders = lids

func find_platform_ladders() -> void:
	platforms.sort_custom(sort_dict_y_asc)
	
	for platform in platforms:
		var y = platform.y
		var x = platform.startX
		var p_ladders: Array[int] = []
		
		while (x <= platform.endX):
			check_ladder_at_coords(x, y, p_ladders)
			check_ladder_at_coords(x, y - 1, p_ladders)
			x += 1
		
		if p_ladders.size():
			platform.ladders = p_ladders

func find_platform_bars() -> void:
	for platform in platforms:
		var walk_bids: Array[int] = []

		for bar in bars:
			if (bar.entity_id not in walk_bids 
				and bar.y == (platform.y - 1) 
				and (
					(bar.endX >= platform.startX - 1 and bar.startX <= platform.endX + 1)
					)
				):
				walk_bids.push_back(bar.entity_id)

		platform.bars = walk_bids

func find_bar_drop_platforms(bar: Dictionary) -> void:
	var pids: Array[int] = []

	var coveredX: Array[int] = []

	for p in platforms:
		var blocked := true
		var x = bar.startX

		while x <= bar.endX:
			if p.y > bar.y:
				if x >= p.startX and x <= p.endX and !p.id in pids:
					var px:int = p.startX
	
					while px <= p.endX:
						if !px in coveredX and px >= bar.startX and px <= bar.endX:
							coveredX.push_back(px)
							
							if blocked:
								blocked = false
						px += 1
					if not blocked and p.entity_id not in pids:
						pids.push_back(p.entity_id)
			x += 1
	
	coveredX.sort()
	
	pids.sort()
	bar.platforms = pids

func platform_at(coords: Vector2i) -> Variant:
	for platform in platforms:
		if platform.y == coords.y:
			if coords.x >= platform.startX and coords.x <= platform.endX:
				return platform
	
	return null

func bar_at(coords: Vector2i) -> Variant:
	for bar in bars:
		if bar.y == coords.y:
			if coords.x >= bar.startX and coords.x <= bar.endX:
				return bar

	return null

func ladder_at(coords: Vector2i) -> Variant:
	for ladder in ladders:
		if ladder.x == coords.x:
			if (coords.y + 1) >= ladder.startY and coords.y <= ladder.endY:
				return ladder
	
	return null

func entity_at(coords: Vector2i) -> Variant:
	var p = platform_at(coords)
	
	if p:
		return p
	
	var l = ladder_at(coords)
	
	if l:
		return l
	
	var b = bar_at(coords)
	
	if b:
		return b

	return null

func find_bar_climb_locations(bar: Dictionary) -> void:
	var lids: Array[int] = bar.ladders if bar.has('ladders') else ([] as Array[int])
	var pids: Array[int] = bar.platforms if bar.has('platforms') else ([] as Array[int])

	var x: int = bar.startX

	var p = platform_at(Vector2i(x, bar.y + 1))

	while x <= bar.endX:
		p = platform_at(Vector2i(x, bar.y + 1))

		if p and p.entity_id not in pids:
			pids.push_back(p.entity_id)
		
		x += 1

	p = platform_at(Vector2i(bar.startX - 1, bar.y + 1))

	if p and p.entity_id not in pids:
		pids.push_back(p.entity_id)

	p = platform_at(Vector2i(bar.endX + 1, bar.y + 1))

	if p and p.entity_id not in pids:
		pids.push_back(p.entity_id)

	var l = ladder_at(Vector2i(bar.startX - 1, bar.y))
	
	if l and l.entity_id not in lids:
		lids.push_back(l.entity_id)

	l = ladder_at(Vector2i(bar.endX + 1, bar.y))
	
	if l and l.entity_id not in lids:
		lids.push_back(l.entity_id)
	
	lids.sort()
	pids.sort()

	bar.ladders = lids
	bar.platforms = pids

func find_bar_drop_locations(bar: Dictionary) -> void:
	var x: int = bar.startX

	var lids: Array[int] = []
	var bids: Array[int] = []
	var pids: Array[int] = []

	while x <= bar.endX:
		var y: int = bar.y + 1
		var use_type: String
		var use_element: Variant = null

		while y <= bot_right.y:
			var p = platform_at(Vector2i(x, y))
			var l = ladder_at(Vector2i(x, y))
			var b = bar_at(Vector2i(x, y))
			
			if p:
				if !use_element or p.y < use_element.y:
					use_element = p
					use_type = 'p'

			if l:
				if !use_element or l.startY < use_element.y:
					use_element = l
					use_element.y = l.startY
					use_type = 'l'

			if b:
				if !use_element or b.y < use_element.y:
					use_element = b
					use_type = 'b'
			
			y += 1

		if use_element:
			if use_type == 'p' and use_element.entity_id not in pids:
				pids.push_back(use_element.entity_id)
			elif use_type == 'l' and use_element.entity_id not in lids:
				lids.push_back(use_element.entity_id)
			elif use_type == 'b' and use_element.entity_id not in bids:
				bids.push_back(use_element.entity_id)
			
			use_element = null

		x += 1

	lids.sort()
	pids.sort()
	bids.sort()

	bar.ladders = lids
	bar.platforms = pids
	bar.bars = bids

func find_bars_drop_locations() -> void:
	for bar in bars:
		find_bar_drop_locations(bar)

func find_bars_climb_locations() -> void:
	for bar in bars:
		find_bar_climb_locations(bar)

func get_platform_by_id(id: int) -> Variant:
	for platform in platforms:
		if platform.id == id:
			return platform

	return null

func get_bar_by_id(id: int) -> Variant:
	for bar in bars:
		if bar.id == id:
			return bar

	return null

func get_ladder_by_id(id: int) -> Variant:
	for ladder in ladders:
		if ladder.id == id:
			return ladder

	return null

func create_entity(type: String, def: Dictionary) -> Variant:
	if type not in ['platform', 'bar', 'ladder']:
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

	return entity

func build_entity_list() -> Dictionary:
	entities = {}
	
	for ladder in ladders:
		var entity: Dictionary = create_entity('ladder', ladder)
		entities[entity.id] = entity

	for platform in platforms:
		if platform.has('unwalkable'):
			continue
		var entity: Dictionary = create_entity('platform', platform)
		entities[entity.id] = entity

	for bar in bars:
		var entity: Dictionary = create_entity('bar', bar)
		entities[entity.id] = entity

	return entities

func find_ladder_platforms() -> void:
	for ladder in ladders:
		var pids: Array[int] = []

		var y: int = ladder.startY
		
		while y <= ladder.endY:
			for platform in platforms:
				if platform.y == y or platform.y == y + 1:
					if ladder.x >= platform.startX and ladder.x <= platform.endX:
						if platform.entity_id not in pids:
							pids.push_back(platform.entity_id)

			y += 1
		
		ladder.platforms = pids

func find_ladder_ladders() -> void:
	for ladder in ladders:
		var lids: Array[int] = []

		var y: int = ladder.startY
		
		while y <= ladder.endY:
			for l in ladders:
				if l.x == ladder.x - 1 or l.x == ladder.x + 1:
					if (
						(l.startY >= ladder.startY and l.startY <= ladder.endY) or 
						(l.endY >= ladder.startY and l.endY <= ladder.endY) or 
						(l.startY <= ladder.startY and l.endY >= ladder.endY)
					):
						if not l.entity_id in lids:
							lids.push_back(l.entity_id)

			y += 1
		
		lids.sort()
		ladder.ladders = lids

func find_ladder_bars() -> void:
	for ladder in ladders:
		var bids: Array[int] = []

		var y: int = ladder.startY
		
		while y <= ladder.endY:
			for bar in bars:
				if bar.y == y and (
					bar.endX == ladder.x - 1 or bar.startX == ladder.x + 1
				):
					if bar.entity_id not in bids:
						bids.push_back(bar.entity_id)
			y += 1
		
		bids.sort()
		ladder.bars = bids

func add_bar_drop_list(bar: Dictionary) -> void:
	var x: int = bar.startX
	var drops: Dictionary = {}
	
	while x <= bar.endX:
		var y = bar.y + 1
		
		while y <= bot_right.y:
			if !drops.has(x) or !drops[x]:
				var entity = entity_at(Vector2i(x, y))
				drops[x] = entity.entity_id if entity else null
			
			y += 1

		x += 1

	bar.drops = drops

func add_bar_drop_lists() -> void:
	for bar in bars:
		add_bar_drop_list(bar)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# find_ladders uses a different sort, so let's get it out of the way first :)
	find_ladders()
	used_cells.sort_custom(sort_y_asc_x_asc)
	find_platforms()
	find_bars()

	find_platform_bars()
	find_platform_ladders()
	find_platform_drops()
		
	find_ladder_platforms()
	find_ladder_ladders()
	find_ladder_bars()

	find_bars_drop_locations()
	find_bars_climb_locations()
	add_bar_drop_lists()

	entities = build_entity_list()

	find_landing_spots()

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

	
	#print(build_entity_list())
	#print("------------")
	#print(" ")
	#print(" ")
	#
	#print(find_shortest_path(build_entity_list(), 8, 9))
	

## Finds the shortest path between a start ID and a target ID using BFS.
## Returns an Array of IDs representing the path, or an empty Array if no path exists.
func find_shortest_path(start_id: int, target_id: int) -> Array:
	# Edge case: Already at the destination
	if start_id == target_id:
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

func find_drop_from(coords: Vector2i) -> Variant:
	var x = coords.x
	var y = coords.y + 1
	
	while y <= bot_right.y:
		var e = entity_at(Vector2i(x, y))

		if e:
			return e
		
		y += 1

	return null

const LADDER_TOP_SCENE = preload("res://Elements/Ladder/ladder_top.tscn")
const LADDER_BOTTOM_SCENE = preload("res://Elements/Ladder/ladder_bottom.tscn")

func add_ladder_zones(ladder: Dictionary) -> void:
	var top_instance = LADDER_TOP_SCENE.instantiate()
	var bottom_instance = LADDER_BOTTOM_SCENE.instantiate()

	top_instance.golden = true if (ladder.has('golden') and ladder.golden) else false

	var startYGlobal = get_cell_center_global(Vector2i(0, ladder.startY))
	var endYGlobal = get_cell_center_global(Vector2i(0, ladder.endY))
	var xGlobal = get_cell_center_global(Vector2i(ladder.x, ladder.endY)).x

	top_instance.position = Vector2(xGlobal, startYGlobal.y - 15)
	bottom_instance.position = Vector2(xGlobal, endYGlobal.y + 3)

	add_child(top_instance)
	add_child(bottom_instance)

const BAR_END_SCENE = preload("res://Elements/Bar/bar_end.tscn")

func add_bar_zones(bar: Dictionary) -> void:
	var left_instance = BAR_END_SCENE.instantiate()
	var right_instance = BAR_END_SCENE.instantiate()

	var startXGlobal = get_cell_center_global(Vector2i(bar.startX, 0))
	var endXGlobal = get_cell_center_global(Vector2i(bar.endX, 0))
	var YGlobal = get_cell_center_global(Vector2i(0, bar.y)).y

	left_instance.position = Vector2(startXGlobal.x - 20, YGlobal)
	right_instance.position = Vector2(endXGlobal.x + 20, YGlobal)

	add_child(left_instance)
	add_child(right_instance)

func find_landing_spots() -> void:
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
		
