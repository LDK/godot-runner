extends TileMapLayer
class_name MapExtended

var bars: Array[Dictionary] = []
var ladders: Array[Dictionary] = []
var platforms: Array[Dictionary] = []
var ziplines: Array[Dictionary] = []
var spikes: Array[Dictionary] = []

var level_drops: Dictionary = {}

enum TileTypes {
	Empty = 0,
	Brick = 1,
	Block = 2,
	Ladder = 3,
	Bar = 4,
	GoldBrick = 5,
	TurtleSkin = 6,
	GoldLadder = 7,
	ZipLineLeft = 8,
	ZipLineRight = 9,
	Spikes = 10
}

var tile_type_names := ['Empty', 'Brick', 'Block', 'Ladder', 'Bar', 'Gold Brick', 'Turtle Skin', 'Gold Ladder', 'Zipline Left', 'Zipline Right', 'Spikes']

const PLATFORM_TILES = [TileTypes.Brick, TileTypes.Block, TileTypes.Ladder, TileTypes.GoldBrick, TileTypes.TurtleSkin]
const LADDER_TILES = [TileTypes.Ladder, TileTypes.GoldLadder]
const ZIPLINE_TILES = [TileTypes.ZipLineLeft, TileTypes.ZipLineRight]

@onready var used_cells: Array[Vector2i] = get_used_cells()

signal player_wins()
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

@onready var top_left: Vector2i = Vector2i(
	lowest_value_on_plane('x', used_cells), 
	lowest_value_on_plane('y', used_cells)
)
@onready var bot_right: Vector2i = Vector2i(
	highest_value_on_plane('x', used_cells),
	highest_value_on_plane('y', used_cells)
)

func on_player_wins() -> void:
	player_wins.emit()

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

func get_coords_from_global(global: Vector2) -> Vector2i:
	var map_coords := to_local(global)
	return local_to_map(map_coords)

func get_cell_center_global(cell: Vector2i) -> Vector2:
	var local_center := map_to_local(cell)
	return to_global(local_center)
