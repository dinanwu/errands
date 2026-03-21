@tool
extends Node2D

## Draws a placeholder isometric street grid.
## Replaced with a proper TileMapLayer once we have real art.

## Street runs along the isometric X axis (screen: top-left to bottom-right).
## Sidewalks on both sides, road in the middle.

const TILE_W = 64  # Isometric tile width
const TILE_H = 32  # Isometric tile height

const STREET_LENGTH = 30  # Tiles along the street
const SIDEWALK_WIDTH = 3  # Tiles wide on each side
const ROAD_WIDTH = 4      # Tiles wide for the road
const TOTAL_WIDTH = SIDEWALK_WIDTH * 2 + ROAD_WIDTH  # 10 tiles

# Colors
const COLOR_SIDEWALK = Color(0.65, 0.65, 0.62)   # Light grey concrete
const COLOR_ROAD = Color(0.35, 0.35, 0.38)        # Dark grey asphalt
const COLOR_ROAD_LINE = Color(0.85, 0.75, 0.2)    # Yellow center line
const COLOR_CROSSWALK = Color(0.9, 0.9, 0.88)     # White crosswalk


func _draw() -> void:
	for x in range(STREET_LENGTH):
		for y in range(TOTAL_WIDTH):
			var color = _get_tile_color(x, y)
			_draw_iso_tile(x, y, color)

	# Draw yellow center line (dashed, follows the street direction)
	_draw_center_line()

	# Draw zebra crosswalks at intervals
	for x in [5, 15, 25]:
		_draw_crosswalk(x)


func _get_tile_color(x: int, y: int) -> Color:
	if y < SIDEWALK_WIDTH or y >= SIDEWALK_WIDTH + ROAD_WIDTH:
		return COLOR_SIDEWALK
	else:
		return COLOR_ROAD


func _draw_iso_tile(grid_x: int, grid_y: int, color: Color) -> void:
	var screen_pos = _grid_to_screen(grid_x, grid_y)
	var points = PackedVector2Array([
		screen_pos + Vector2(0, -TILE_H / 2.0),
		screen_pos + Vector2(TILE_W / 2.0, 0),
		screen_pos + Vector2(0, TILE_H / 2.0),
		screen_pos + Vector2(-TILE_W / 2.0, 0),
	])
	draw_colored_polygon(points, color)
	# Tile outline (append first point to close the shape)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.15), 1.0)


func _draw_center_line() -> void:
	# Dashed yellow line running along the center of the road, parallel to the street.
	# The street runs along grid X, so adjacent tile centers along X form the line direction.
	var center_y = SIDEWALK_WIDTH + ROAD_WIDTH / 2.0 - 0.5  # Between the two center road tiles
	for x in range(STREET_LENGTH - 1):
		if x % 3 == 2:  # Gap in dashed line
			continue
		var start = _grid_to_screen(x, int(center_y)) + Vector2(0, TILE_H / 4.0)
		var end = _grid_to_screen(x + 1, int(center_y)) + Vector2(0, TILE_H / 4.0)
		draw_line(start, end, COLOR_ROAD_LINE, 3.0)


func _draw_crosswalk(grid_x: int) -> void:
	# Zebra stripes parallel to the road direction (running along grid X),
	# spaced across the road width (along grid Y).
	var num_stripes = 7
	var road_start_y = SIDEWALK_WIDTH
	var road_end_y = SIDEWALK_WIDTH + ROAD_WIDTH

	for i in range(num_stripes):
		# Space stripes evenly across the road width (Y axis)
		var t = (i + 0.5) / num_stripes
		var y_pos = road_start_y + t * ROAD_WIDTH

		# Each stripe runs parallel to the street, centered on grid_x
		var start = _grid_to_screen(grid_x - 0.4, y_pos - 0.5)
		var end = _grid_to_screen(grid_x + 0.4, y_pos - 0.5)
		draw_line(start, end, COLOR_CROSSWALK, 3.0)


func _grid_to_screen(grid_x: float, grid_y: float) -> Vector2:
	var screen_x = (grid_x - grid_y) * TILE_W / 2.0
	var screen_y = (grid_x + grid_y) * TILE_H / 2.0
	return Vector2(screen_x, screen_y)


## Converts a screen position back to the nearest grid tile.
static func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var grid_x = (screen_pos.x / (TILE_W / 2.0) + screen_pos.y / (TILE_H / 2.0)) / 2.0
	var grid_y = (screen_pos.y / (TILE_H / 2.0) - screen_pos.x / (TILE_W / 2.0)) / 2.0
	return Vector2i(roundi(grid_x), roundi(grid_y))


## Returns the walkable area bounds in screen coordinates.
func get_walkable_bounds() -> Rect2:
	var top_left = _grid_to_screen(0, 0)
	var top_right = _grid_to_screen(STREET_LENGTH - 1, 0)
	var bottom_left = _grid_to_screen(0, TOTAL_WIDTH - 1)
	var bottom_right = _grid_to_screen(STREET_LENGTH - 1, TOTAL_WIDTH - 1)

	var min_x = bottom_left.x
	var max_x = top_right.x
	var min_y = top_left.y
	var max_y = bottom_right.y

	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
