extends MapExtended
class_name MapZoneAdder

const ZIPLINE_RIGHT_END_SCENE = preload("res://Elements/ZipLine/zip_line_right_end.tscn")
const ZIPLINE_LEFT_END_SCENE = preload("res://Elements/ZipLine/zip_line_left_end.tscn")

const LADDER_TOP_SCENE = preload("res://Elements/Ladder/ladder_top.tscn")
const LADDER_BOTTOM_SCENE = preload("res://Elements/Ladder/ladder_bottom.tscn")

const BAR_END_SCENE = preload("res://Elements/Bar/bar_end.tscn")

func add_zipline_zones(zipline: Dictionary) -> void:
	var end_instance = (ZIPLINE_LEFT_END_SCENE if zipline.direction == 'left' else ZIPLINE_RIGHT_END_SCENE).instantiate()
	var xGlobal = get_cell_center_global(Vector2i(zipline.endX, 0)).x
	var yGlobal = get_cell_center_global(Vector2i(0, zipline.endY)).y

	end_instance.position = Vector2(xGlobal, yGlobal)

	call_deferred("add_child", end_instance)

func add_bar_zones(bar: Dictionary) -> void:
	var left_instance = BAR_END_SCENE.instantiate()
	var right_instance = BAR_END_SCENE.instantiate()

	var startXGlobal = get_cell_center_global(Vector2i(bar.startX, 0))
	var endXGlobal = get_cell_center_global(Vector2i(bar.endX, 0))
	var YGlobal = get_cell_center_global(Vector2i(0, bar.y)).y

	left_instance.position = Vector2(startXGlobal.x - 19, YGlobal)
	right_instance.position = Vector2(endXGlobal.x + 19, YGlobal)

	call_deferred("add_child", left_instance)
	call_deferred("add_child", right_instance)

func add_ladder_zones(ladder: Dictionary) -> void:
	var top_instance:LadderTop = LADDER_TOP_SCENE.instantiate() as LadderTop
	var bottom_instance:LadderBottom = LADDER_BOTTOM_SCENE.instantiate() as LadderBottom

	var golden: bool = (ladder.has('golden') and ladder.golden)
	var hide_zones_on_gold: bool = (ladder.has('hide_zones_on_gold') and ladder.hide_zones_on_gold)

	top_instance.golden = golden
	bottom_instance.golden = golden
	top_instance.hide_on_gold = hide_zones_on_gold
	bottom_instance.hide_on_gold = hide_zones_on_gold

	var startYGlobal = get_cell_center_global(Vector2i(0, ladder.startY))
	var endYGlobal = get_cell_center_global(Vector2i(0, ladder.endY))
	var xGlobal = get_cell_center_global(Vector2i(ladder.x, ladder.endY)).x

	top_instance.position = Vector2(xGlobal, startYGlobal.y - 15)
	bottom_instance.position = Vector2(xGlobal, endYGlobal.y + 3)

	call_deferred("add_child", top_instance)
	call_deferred("add_child", bottom_instance)

	if golden:
		await top_instance.ready
		top_instance.collision_box.disabled = true
		await bottom_instance.ready
		bottom_instance.collision_box.disabled = true
	
	top_instance.connect('player_wins', on_player_wins)
