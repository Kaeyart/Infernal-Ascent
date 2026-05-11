@tool
extends Node2D
class_name IsoRoomTemplate

@export var room_id: String = "iso_room_template"
@export var display_name: String = "Iso Room Template"
@export var tile_width: int = 64
@export var tile_height: int = 32
@export var grid_width: int = 12
@export var grid_height: int = 8
@export var debug_layer_order: bool = true

const LAYER_Z := {
	"L0_Background": -100,
	"L1_IsoFloor": -60,
	"L2_IsoWalls": -20,
	"L3_YSorted": 0,
	"L4_Foreground": 100,
}

func _ready() -> void:
	_apply_layer_order()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_apply_layer_order()


func _apply_layer_order() -> void:
	if not debug_layer_order:
		return

	for layer_name in LAYER_Z.keys():
		var node := get_node_or_null(layer_name)

		if node is CanvasItem:
			(node as CanvasItem).z_index = int(LAYER_Z[layer_name])

	var ysorted := get_node_or_null("L3_YSorted")

	if ysorted is Node2D:
		(ysorted as Node2D).y_sort_enabled = true


func iso_to_screen(cell: Vector2) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * float(tile_width) * 0.5,
		(cell.x + cell.y) * float(tile_height) * 0.5
	)


func screen_to_iso(point: Vector2) -> Vector2:
	var half_w := float(tile_width) * 0.5
	var half_h := float(tile_height) * 0.5
	return Vector2(
		(point.x / half_w + point.y / half_h) * 0.5,
		(point.y / half_h - point.x / half_w) * 0.5
	)


func get_marker(name_path: String) -> Node2D:
	var marker := get_node_or_null("Markers/%s" % name_path)

	if marker is Node2D:
		return marker as Node2D

	return null


func get_player_spawn_position() -> Vector2:
	var marker := get_marker("PlayerSpawn")
	return marker.global_position if marker != null else global_position


func get_reward_socket_position() -> Vector2:
	var marker := get_marker("RewardSocket")
	return marker.global_position if marker != null else get_player_spawn_position()


func get_enemy_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var parent := get_node_or_null("Markers/EnemySpawns")

	if parent != null:
		for child in parent.get_children():
			if child is Node2D:
				positions.append((child as Node2D).global_position)

	return positions


func get_door_socket_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var parent := get_node_or_null("Markers/DoorSockets")

	if parent != null:
		for child in parent.get_children():
			if child is Node2D:
				positions.append((child as Node2D).global_position)

	return positions
