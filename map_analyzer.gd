extends MapDecomposer
class_name MapAnalyzer

const DROP_BLOCKERS = PLATFORM_TILES + [TileTypes.Bar, TileTypes.ZipLineLeft, TileTypes.ZipLineRight]

func find_platform_drops() -> void:
	platforms.sort_custom(sort_dict_y_asc)

	for platform in platforms:
		var blockedLeft := false
		var blockedRight := false

		var y = platform.y
		var leftX = platform.startX - 1
		var rightX = platform.endX + 1
		var dropLeft: Variant = null
		var dropRight: Variant = null

		var pids:Array[int] = platform.platforms if platform.has('platforms') else ([] as Array[int])
		var lids:Array[int] = platform.ladders if platform.has('ladders') else ([] as Array[int])
		var bids:Array[int] = platform.bars if platform.has('bars') else ([] as Array[int])
		var zids:Array[int] = platform.ziplines if platform.has('ziplines') else ([] as Array[int])

		print(0)

		if get_cell_alternative_tile(Vector2i(leftX, platform.y - 1)) in DROP_BLOCKERS:
			blockedLeft = true

		if get_cell_alternative_tile(Vector2i(rightX, platform.y - 1)) in DROP_BLOCKERS:
			blockedRight = true
		
		if get_cell_alternative_tile(Vector2i(leftX, platform.y)) in PLATFORM_TILES:
			blockedLeft = true

		if get_cell_alternative_tile(Vector2i(rightX, platform.y)) in PLATFORM_TILES:
			blockedRight = true

		var dropEntities: Array[Dictionary] = []

		if !dropLeft and !blockedLeft:
			var dropLeftCoords = Vector2i(leftX, y)
			var dropEntity = find_drop_from(dropLeftCoords)
			
			if dropEntity:
				dropEntities.push_back(dropEntity)

		if !dropRight and !blockedRight:
			var dropRightCoords = Vector2i(rightX, y)

			var dropEntity = find_drop_from(dropRightCoords)

			if dropEntity:
				dropEntities.push_back(dropEntity)

		for dropEntity in dropEntities:
			if dropEntity.type == 'platform':
				pids.push_back(dropEntity.entity_id)
			elif dropEntity.type == 'ladder':
				lids.push_back(dropEntity.entity_id)
			elif dropEntity.type == 'bar':
				bids.push_back(dropEntity.entity_id)
			elif dropEntity.type == 'zipline':
				zids.push_back(dropEntity.entity_id)

		platform.platforms = pids
		platform.bars = bids
		platform.ladders = lids
		platform.ziplines = zids

func check_ladder_at_coords(x: int, y: int, dict_arr: Array[int]) -> void:
	var tile_id = get_cell_alternative_tile(Vector2i(x,y))

	if (tile_id in LADDER_TILES): # Ladder
		for ladder in ladders:
			if ladder.x == x and (ladder.startY == y or ladder.endY == y):
				dict_arr.push_back(ladder.entity_id)

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

func find_platform_ziplines() -> void:
	for platform in platforms:
		var walk_zids: Array[int] = []

		for zipline in ziplines:
			if (zipline.entity_id not in walk_zids 
				and (
					Vector2i(platform.startX - 1, platform.y - 1) in zipline.cells
					or Vector2i(platform.endX + 1, platform.y - 1) in zipline.cells
				)
			):
				walk_zids.push_back(zipline.entity_id)

		platform.ziplines = walk_zids


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

func find_bar_climb_locations(bar: Dictionary) -> void:
	var lids: Array[int] = bar.ladders if bar.has('ladders') else ([] as Array[int])
	var pids: Array[int] = bar.platforms if bar.has('platforms') else ([] as Array[int])
	var zids: Array[int] = bar.ziplines if bar.has('ziplines') else ([] as Array[int])

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
	
	var z = zipline_at(Vector2i(bar.startX - 1, bar.y))
	
	if z and z.entity_id not in zids:
		zids.push_back(z.entity_id)

	z = zipline_at(Vector2i(bar.endX + 1, bar.y))
	
	if z and z.entity_id not in zids:
		zids.push_back(z.entity_id)
	
	lids.sort()
	pids.sort()
	zids.sort()

	bar.ladders = lids
	bar.platforms = pids
	bar.ziplines = zids

func find_drop_from(coords: Vector2i) -> Variant:
	var x = coords.x
	var y = coords.y + 1
	
	while y <= bot_right.y:
		var e = entity_at(Vector2i(x, y))

		if e:
			return e
		
		y += 1

	return null

func find_bar_drop_locations(bar: Dictionary) -> void:
	var x: int = bar.startX

	var lids: Array[int] = []
	var bids: Array[int] = []
	var pids: Array[int] = []
	var zids: Array[int] = []

	while x <= bar.endX:
		var y: int = bar.y + 1
		var use_element: Variant = find_drop_from(Vector2i(x, y))

		if use_element:
			if use_element.type == 'platform' and use_element.entity_id not in pids:
				pids.push_back(use_element.entity_id)
			elif use_element.type == 'ladder' and use_element.entity_id not in lids:
				lids.push_back(use_element.entity_id)
			elif use_element.type == 'bar' and use_element.entity_id not in bids:
				bids.push_back(use_element.entity_id)
			elif use_element.type == 'zipline' and use_element.entity_id not in zids:
				zids.push_back(use_element.entity_id)
			
			if use_element.type == 'platform':
				var l = ladder_at(Vector2i(x, use_element.y))
				if l:
					#print("This platform is also a ladder!")
					lids.push_back(l.entity_id)
			
			if use_element.type == 'ladder':
				var p = platform_at(Vector2i(use_element.x, use_element.startY))
				if p:
					#print("This ladder is also a platform!")
					pids.push_back(p.entity_id)

		x += 1

	lids.sort()
	pids.sort()
	bids.sort()
	zids.sort()

	bar.ladders = lids
	bar.platforms = pids
	bar.bars = bids
	bar.ziplines = zids

func find_bars_drop_locations() -> void:
	for bar in bars:
		find_bar_drop_locations(bar)

func find_bars_climb_locations() -> void:
	for bar in bars:
		find_bar_climb_locations(bar)

func find_zipline_landings() -> void:
	for zipline in ziplines:
		zipline.platforms = []
		zipline.bars = []
		zipline.ladders = []
		zipline.ziplines = []
		
		var landingOffsetX = 1 if zipline.direction == 'right' else -1
		var landingCoords = Vector2i(zipline.endX + landingOffsetX, zipline.endY + 1)

		var landingEntity = entity_at(landingCoords)
		
		if not landingEntity:
			landingEntity = find_drop_from(landingCoords)

		if landingEntity and landingEntity.type == 'spikes':
			zipline.leads_to_death = true

		if landingEntity.type == 'platform':
			zipline.platforms.push_back(landingEntity.entity_id)
		elif landingEntity.type == 'bar':
			zipline.bars.push_back(landingEntity.entity_id)
		elif landingEntity.type == 'ladder':
			zipline.ladders.push_back(landingEntity.entity_id)
		elif landingEntity.type == 'zipline':
			print("from ", zipline.entity_id, " to ", landingEntity.entity_id)
			zipline.ziplines.push_back(landingEntity.entity_id)

func find_zipline_drop_locations(zipline: Dictionary) -> void:
	for cell in zipline.cells:
		var use_element: Variant = find_drop_from(cell)

		if use_element:
			if use_element.type == 'platform' and use_element.entity_id not in zipline.platforms:
				zipline.platforms.push_back(use_element.entity_id)
			elif use_element.type == 'ladder' and use_element.entity_id not in zipline.ladders:
				zipline.ladders.push_back(use_element.entity_id)
			elif use_element.type == 'bar' and use_element.entity_id not in zipline.bars:
				zipline.bars.push_back(use_element.entity_id)
			elif use_element.type == 'zipline' and use_element.entity_id not in zipline.ziplines:
				zipline.ziplines.push_back(use_element.entity_id)

func find_ziplines_drop_locations() -> void:
	for zipline in ziplines:
		find_zipline_drop_locations(zipline)

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

func get_zipline_by_id(id: int) -> Variant:
	for zipline in ziplines:
		if zipline.id == id:
			return zipline

	return null

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

func find_ladder_ziplines() -> void:
	for ladder in ladders:
		var zids: Array[int] = []

		var y: int = ladder.startY
		var x: int = ladder.x

		while y <= ladder.endY:
			var ladderTileCoords = Vector2i(x, y)

			for zipline in ziplines:
				if (
					ladderTileCoords in zipline.cells
					and zipline.entity_id not in zids
				):
					zids.push_back(zipline.entity_id)

			y += 1
		
		ladder.ziplines = zids

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

func add_zipline_drop_list(zipline: Dictionary) -> void:
	var drops: Dictionary = {}
	
	for coords in zipline.cells:
		if !drops.has(coords) or !drops[coords]:
			var entity = find_drop_from(coords)
			drops[coords] = entity.entity_id if entity else null
			
			if entity and entity.entity_id:
				if entity.type == 'platform' and entity.entity_id not in zipline.platforms:
					zipline.platforms.push_back(entity.entity_id)
				elif entity.type == 'ladder' and entity.entity_id not in zipline.ladders:
					zipline.ladders.push_back(entity.entity_id)
				elif entity.type == 'bar' and entity.entity_id not in zipline.bars:
					zipline.bars.push_back(entity.entity_id)
				elif entity.type == 'zipline' and entity.entity_id not in zipline.ziplines:
					zipline.ziplines.push_back(entity.entity_id)

	zipline.drops = drops
	
func add_zipline_drop_lists() -> void:
	for zipline in ziplines:
		add_zipline_drop_list(zipline)

		if zipline.has('drops'):
			for coords in zipline.drops:
				var dropEntity = entity_at(coords)

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
