@tool
extends Node2D
class_name IsoGridGuide

@export var tile_width: int = 64:
	set(value):
		tile_width = max(8, value)
		queue_redraw()
@export var tile_height: int = 32:
	set(value):
		tile_height = max(8, value)
		queue_redraw()
@export var grid_width: int = 12:
	set(value):
		grid_width = max(1, value)
		queue_redraw()
@export var grid_height: int = 8:
	set(value):
		grid_height = max(1, value)
		queue_redraw()
@export var show_floor_grid: bool = true:
	set(value):
		show_floor_grid = value
		queue_redraw()
@export var show_shell_preview: bool = true:
	set(value):
		show_shell_preview = value
		queue_redraw()
@export var show_combat_lane: bool = true:
	set(value):
		show_combat_lane = value
		queue_redraw()

var floor_color_a := Color(0.10, 0.10, 0.11, 0.95)
var floor_color_b := Color(0.13, 0.12, 0.12, 0.95)
var grid_line_color := Color(0.55, 0.38, 0.25, 0.32)
var shell_color := Color(0.04, 0.035, 0.04, 0.92)
var shell_edge_color := Color(0.80, 0.42, 0.18, 0.52)
var lane_color := Color(0.84, 0.50, 0.22, 0.12)

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if show_shell_preview:
		_draw_background_depth()

	if show_floor_grid:
		_draw_iso_floor_grid()

	if show_combat_lane:
		_draw_combat_lane()

	if show_shell_preview:
		_draw_room_shell_guides()


func iso_to_screen(cell: Vector2) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * float(tile_width) * 0.5,
		(cell.x + cell.y) * float(tile_height) * 0.5
	)


func _diamond_at(cell: Vector2) -> PackedVector2Array:
	var center := iso_to_screen(cell)
	var hw := float(tile_width) * 0.5
	var hh := float(tile_height) * 0.5
	return PackedVector2Array([
		center + Vector2(0, -hh),
		center + Vector2(hw, 0),
		center + Vector2(0, hh),
		center + Vector2(-hw, 0),
	])


func _draw_iso_floor_grid() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			var cell := Vector2(float(x), float(y))
			var diamond := _diamond_at(cell)
			var fill := floor_color_a if (x + y) % 2 == 0 else floor_color_b
			draw_colored_polygon(diamond, fill)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), grid_line_color, 1.0)


func _draw_combat_lane() -> void:
	var left_top := iso_to_screen(Vector2(4, 0))
	var right_top := iso_to_screen(Vector2(8, 0))
	var right_bottom := iso_to_screen(Vector2(12, 4))
	var left_bottom := iso_to_screen(Vector2(8, 8))
	var lane := PackedVector2Array([left_top, right_top, right_bottom, left_bottom])
	draw_colored_polygon(lane, lane_color)
	draw_polyline(lane + PackedVector2Array([lane[0]]), Color(0.90, 0.56, 0.20, 0.22), 2.0)

	var center := iso_to_screen(Vector2(6, 4))
	draw_arc(center, 42.0, 0.0, TAU, 64, Color(0.95, 0.55, 0.20, 0.42), 2.0)
	draw_arc(center, 23.0, 0.0, TAU, 64, Color(0.95, 0.70, 0.36, 0.28), 1.5)


func _draw_background_depth() -> void:
	var bounds := PackedVector2Array([
		iso_to_screen(Vector2(0, 0)) + Vector2(0, -110),
		iso_to_screen(Vector2(grid_width, 0)) + Vector2(210, 30),
		iso_to_screen(Vector2(grid_width, grid_height)) + Vector2(170, 190),
		iso_to_screen(Vector2(0, grid_height)) + Vector2(-210, 190),
	])
	draw_colored_polygon(bounds, Color(0.015, 0.012, 0.014, 0.96))

	for i in range(5):
		var p := iso_to_screen(Vector2(float(i) * 2.0 + 1.0, -1.0))
		draw_circle(p + Vector2(0, -55), 16.0 + float(i % 2) * 7.0, Color(0.95, 0.27, 0.08, 0.05))


func _draw_room_shell_guides() -> void:
	var north_a := iso_to_screen(Vector2(0, 0))
	var north_b := iso_to_screen(Vector2(grid_width, 0))
	var west_b := iso_to_screen(Vector2(0, grid_height))
	var east_b := iso_to_screen(Vector2(grid_width, grid_height))

	# North hero wall block.
	var north_wall := PackedVector2Array([
		north_a + Vector2(-34, -88),
		north_b + Vector2(34, -88),
		north_b + Vector2(34, -18),
		north_a + Vector2(-34, -18),
	])
	draw_colored_polygon(north_wall, shell_color)
	draw_polyline(north_wall + PackedVector2Array([north_wall[0]]), shell_edge_color, 2.0)

	# West return.
	var west_return := PackedVector2Array([
		north_a + Vector2(-34, -18),
		west_b + Vector2(-34, 18),
		west_b + Vector2(-78, 40),
		north_a + Vector2(-78, -40),
	])
	draw_colored_polygon(west_return, Color(0.035, 0.030, 0.035, 0.88))
	draw_polyline(west_return + PackedVector2Array([west_return[0]]), shell_edge_color, 1.6)

	# East return.
	var east_return := PackedVector2Array([
		north_b + Vector2(34, -18),
		east_b + Vector2(34, 18),
		east_b + Vector2(78, 40),
		north_b + Vector2(78, -40),
	])
	draw_colored_polygon(east_return, Color(0.035, 0.030, 0.035, 0.88))
	draw_polyline(east_return + PackedVector2Array([east_return[0]]), shell_edge_color, 1.6)

	# South foreground edge.
	var south_wall := PackedVector2Array([
		west_b + Vector2(-58, 30),
		east_b + Vector2(58, 30),
		east_b + Vector2(42, 76),
		west_b + Vector2(-42, 76),
	])
	draw_colored_polygon(south_wall, Color(0.02, 0.018, 0.020, 0.94))
	draw_polyline(south_wall + PackedVector2Array([south_wall[0]]), shell_edge_color, 2.0)

	# Rear gate placeholder.
	var gate_center := (north_a + north_b) * 0.5 + Vector2(0, -54)
	draw_rect(Rect2(gate_center - Vector2(72, 34), Vector2(144, 68)), Color(0.015, 0.012, 0.012, 0.95))
	draw_rect(Rect2(gate_center - Vector2(72, 34), Vector2(144, 68)), Color(0.95, 0.36, 0.12, 0.65), false, 2.0)
	draw_circle(gate_center, 30.0, Color(1.0, 0.28, 0.08, 0.12))
