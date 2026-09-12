extends MapZoneAdder
class_name MapDecomposer

func find_platforms() -> void:
	var foundPlatform := false
	var platformStart: Variant = null
	var platformEnd: int

	var pid: int = 1

	var y: int = top_left.y
	var x: int = top_left.x

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

		if (id in PLATFORM_TILES):
			if !foundPlatform:
				foundPlatform = true
				platformStart = cell_coords.x
				if id in [3, 7]:
					allLadders = true
			
			if id not in [3, 7]:
				allLadders= false

		if foundPlatform and (id not in PLATFORM_TILES or idx == used_cells.size() - 1):
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

func find_spikes() -> void:
	var sid: int = 1
	var eid_offset = ladders.size() + platforms.size() + bars.size() + ziplines.size()

	for cell_coords in used_cells:
		var id := get_cell_alternative_tile(cell_coords)

		if id == TileTypes.Spikes:
			spikes.push_back({ 
				"type": "spikes", 
				"x": cell_coords.x, 
				"y": cell_coords.y, 
				"id": sid, 
				"entity_id": sid + eid_offset 
			})

func spikes_at(coords: Vector2i) -> Variant:
	for spikebed in spikes:
		if spikebed.x == coords.x and spikebed.y == coords.y:
			return spikebed
	
	return null

func find_ziplines() -> void:
	var y: int = top_left.y
	var x: int = top_left.x
	
	var zid: int = 1
	
	var eid_offset = ladders.size() + platforms.size() + bars.size()

	const ZIPLINE_IDS = [TileTypes.ZipLineLeft, TileTypes.ZipLineRight]

	var processedCells: Array[Vector2i] = []

	for cell_coords in used_cells:
		if cell_coords in processedCells:
			continue

		var tileId := get_cell_alternative_tile(cell_coords)

		if tileId not in ZIPLINE_IDS:
			continue

		var startX := cell_coords.x
		var startY := cell_coords.y

		var ziplineDef: Variant = null

		ziplineDef = { "type": "zipline", "startX": startX, "startY": startY, "id": zid, "entity_id": eid_offset + zid }
		processedCells.push_back(cell_coords)

		var foundEnd := false

		var ziplineLength := 1
		var endX := startX
		var endY := startY

		ziplineDef["direction"] = 'left' if tileId == TileTypes.ZipLineLeft else 'right'

		var ziplineCells: Array[Vector2i] = [Vector2i(endX, endY)]

		while !foundEnd:
			var diagDownLeftCoords := Vector2i(startX - ziplineLength, startY + ziplineLength)
			var diagDownRightCoords := Vector2i(startX + ziplineLength, startY + ziplineLength)

			var diagCoords := diagDownLeftCoords if tileId == TileTypes.ZipLineLeft else diagDownRightCoords
			var diagTileId = get_cell_alternative_tile(diagCoords)

			var diagonalIsZipline: bool = diagTileId in ZIPLINE_IDS
			var changeOfDirection: bool = diagonalIsZipline and diagTileId != tileId

			var outOfBounds: bool = (
				diagCoords.x < top_left.x
				or diagCoords.x > bot_right.x 
				or diagCoords.y > bot_right.y
			)

			if outOfBounds or not diagonalIsZipline:
				foundEnd = true
				processedCells.push_back(diagCoords)
			elif changeOfDirection:
				foundEnd = true

			if foundEnd:
				ziplineDef["length"] = ziplineLength
				ziplineDef["endX"] = endX
				ziplineDef["endY"] = endY
			else:
				ziplineLength += 1
				endX = diagCoords.x
				endY = diagCoords.y
				ziplineCells.push_back(diagCoords)
				processedCells.push_back(diagCoords)

		ziplineDef["cells"] = ziplineCells
		ziplines.push_back(ziplineDef)
		add_zipline_zones(ziplineDef)
		zid += 1

		x = cell_coords.x
		y = cell_coords.y

		if ziplineDef:
			add_zipline_zones(ziplineDef)

func find_platform_segments(platform: Dictionary) -> Array[Dictionary]:
	var x: int = platform.startX
	
	var blocked: Array[int] = []
	
	while x <= platform.endX:
		var overheadCoords = Vector2i(x, platform.y - 1)

		if platform_at(overheadCoords) or spikes_at(overheadCoords):
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
	var hide_zones_on_gold := false

	for cell_coords in vert_cells:
		var ladderDef: Variant = null
		var id := get_cell_alternative_tile(cell_coords)

		if id == 7: # Golden Ladder
			# If there's already a ladder being assessed, and it
			# isn't golden, register the existing ladder and start
			# defining a new one
			if foundLadder and ladderStart and !golden:
				ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": y, "id": lid, "entity_id": lid, "hide_zones_on_gold": true }
				ladderStart = cell_coords.y
				
				ladders.push_back(ladderDef)
				lid += 1
			golden = true

		if cell_coords.y != (y + 1):
			if foundLadder and ladderStart:
				foundLadder = false
				ladderEnd = y
				ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": ladderEnd, "id": lid, "entity_id": lid }

				if golden:
					ladderDef.golden = true

				if hide_zones_on_gold:
					ladderDef['hide_zones_on_gold'] = true
					hide_zones_on_gold = false

				ladders.push_back(ladderDef)
				golden = false
				lid += 1
			
		if (id in [3, 7]): # Ladder
			if !foundLadder:
				foundLadder = true
				ladderStart = cell_coords.y
			elif ladderStart and golden and id == 3:
				# In this case, there was already a golden ladder
				# going, and now we've found a non-golden ladder it's attached
				# to
				golden = false
				hide_zones_on_gold = true
				ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": y, "id": lid, "entity_id": lid, "golden": true }
				ladders.push_back(ladderDef)

				ladderStart = cell_coords.y
				lid += 1
					


		elif foundLadder:
			foundLadder = false
			ladderEnd = y
			ladderDef = { "type": "ladder", "x": x, "startY": ladderStart, "endY": ladderEnd, "id": lid, "entity_id": lid }

			if hide_zones_on_gold:
				ladderDef['hide_zones_on_gold'] = true
				hide_zones_on_gold = false

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

func zipline_at(coords: Vector2i) -> Variant:
	for zipline in ziplines:
		if coords in zipline.cells:
			return zipline

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

	var z = zipline_at(coords)
	
	if z:
		return z
	
	var s = spikes_at(coords)

	if s:
		return s

	return null
