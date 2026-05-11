extends Node2D

# Marker-only helper script for visually-authored room scenes.
# Expected scene structure:
# AuthoredRoomTemplate
#   Art
#   Collision
#   Markers
#     PlayerSpawn
#     RewardSocket
#     UpgradeSockets
#       UpgradeSocket_01
#       UpgradeSocket_02
#       UpgradeSocket_03
#     EnemySpawns
#       EnemySpawn_01
#       EnemySpawn_02
#     DoorSockets
#       DoorSocket_01
#       DoorSocket_02
#       DoorSocket_03

const DEFAULT_DOOR_ORIENTATION := "north"


func get_marker_position(marker_name: String, fallback: Vector2) -> Vector2:
	var marker: Node2D = _find_marker(marker_name)

	if marker == null:
		return fallback

	return marker.global_position


func get_player_spawn(fallback: Vector2) -> Vector2:
	return get_marker_position("PlayerSpawn", fallback)


func get_reward_socket(fallback: Vector2) -> Vector2:
	return get_marker_position("RewardSocket", fallback)


func get_enemy_spawns() -> Array[Vector2]:
	return _collect_marker_positions("Markers/EnemySpawns")


func get_upgrade_sockets() -> Array[Vector2]:
	return _collect_marker_positions("Markers/UpgradeSockets")


func get_reward_sockets() -> Array[Vector2]:
	var upgrade_sockets: Array[Vector2] = get_upgrade_sockets()

	if not upgrade_sockets.is_empty():
		return upgrade_sockets

	var reward_socket: Vector2 = get_reward_socket(Vector2.ZERO)

	if reward_socket != Vector2.ZERO:
		return [reward_socket]

	return []


func get_door_sockets() -> Array[Dictionary]:
	var sockets: Array[Dictionary] = []
	var door_root: Node = get_node_or_null("Markers/DoorSockets")

	if door_root == null:
		return sockets

	for child in door_root.get_children():
		if not (child is Node2D):
			continue

		var marker := child as Node2D
		var orientation: String = DEFAULT_DOOR_ORIENTATION

		if marker.has_meta("orientation"):
			orientation = str(marker.get_meta("orientation"))
		elif marker.name.to_lower().contains("left") or marker.name.to_lower().contains("west"):
			orientation = "west"
		elif marker.name.to_lower().contains("right") or marker.name.to_lower().contains("east"):
			orientation = "east"
		elif marker.name.to_lower().contains("south") or marker.name.to_lower().contains("bottom"):
			orientation = "south"

		sockets.append({
			"pos": marker.global_position,
			"orientation": orientation
		})

	return sockets


func _find_marker(marker_name: String) -> Node2D:
	var markers_root: Node = get_node_or_null("Markers")

	if markers_root == null:
		return null

	var direct: Node = markers_root.get_node_or_null(marker_name)

	if direct is Node2D:
		return direct as Node2D

	return _find_node2d_by_name(markers_root, marker_name)


func _find_node2d_by_name(root: Node, marker_name: String) -> Node2D:
	for child in root.get_children():
		if child.name == marker_name and child is Node2D:
			return child as Node2D

		var nested: Node2D = _find_node2d_by_name(child, marker_name)

		if nested != null:
			return nested

	return null


func _collect_marker_positions(path: String) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var root: Node = get_node_or_null(path)

	if root == null:
		return positions

	for child in root.get_children():
		if child is Node2D:
			positions.append((child as Node2D).global_position)

	return positions
