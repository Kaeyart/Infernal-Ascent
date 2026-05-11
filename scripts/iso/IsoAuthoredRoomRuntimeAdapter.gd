extends Node2D
class_name IsoAuthoredRoomRuntimeAdapter

## Runtime adapter for hand-authored isometric rooms.
##
## Intended setup:
##   YourAuthoredIsoRoom
##     RuntimeAdapter  <- attach this script here
##
## It reads existing authored markers and wires the current test runtime:
## - creates/moves IsoTestPlayer to PlayerSpawn
## - adds a Camera2D to the player
## - creates/configures PatronFlow using RewardSocket and Door L/C/R markers
##
## This does not spawn real enemies yet. It keeps the current C/E/R debug patron flow.

@export var use_parent_as_room_root: bool = true
@export var auto_create_test_player: bool = true
@export var auto_create_camera: bool = true
@export var auto_create_patron_flow: bool = true
@export var move_existing_nodes_to_markers: bool = true
@export var debug_print_mapping: bool = true

@export var player_node_name: String = "IsoTestPlayer"
@export var patron_flow_node_name: String = "PatronFlow"
@export var marker_root_name: String = "Markers"

@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_enabled: bool = true
@export var camera_smoothing_speed: float = 8.0

var room_root: Node = null
var player_node: Node2D = null
var patron_flow_node: IsoPatronFlowController = null

func _ready() -> void:
	room_root = _get_room_root()
	if room_root == null:
		push_warning("[IsoRuntimeAdapter] No room root found.")
		return

	var player_spawn: Node2D = _find_marker([
		"PlayerSpawn",
		"Player Spawn",
		"SpawnPlayer",
		"Spawn_Player",
		"player_spawn"
	])

	var reward_socket: Node2D = _find_marker([
		"RewardSocket",
		"Reward Socket",
		"Reward",
		"BoonSocket",
		"Boon Socket",
		"AltarSocket",
		"Altar Socket"
	])

	var door_left: Node2D = _find_marker([
		"DoorL",
		"Door L",
		"Door_Left",
		"DoorLeft",
		"LeftDoor",
		"DoorSocketLeft",
		"DoorSocket_L"
	])

	var door_center: Node2D = _find_marker([
		"DoorC",
		"Door C",
		"Door_C",
		"DoorCenter",
		"CenterDoor",
		"DoorSocketCenter",
		"DoorSocket_C"
	])

	var door_right: Node2D = _find_marker([
		"DoorR",
		"Door R",
		"Door_Right",
		"DoorRight",
		"RightDoor",
		"DoorSocketRight",
		"DoorSocket_R"
	])

	player_node = _find_or_create_player(player_spawn)
	patron_flow_node = _find_or_create_patron_flow(reward_socket, door_left, door_center, door_right)

	if auto_create_camera and player_node != null:
		_ensure_camera(player_node)

	if debug_print_mapping:
		_print_mapping(player_spawn, reward_socket, door_left, door_center, door_right)


func _get_room_root() -> Node:
	if use_parent_as_room_root and get_parent() != null:
		return get_parent()
	return self


func _find_or_create_player(player_spawn: Node2D) -> Node2D:
	var found_player: Node2D = _find_named_node2d(player_node_name)
	if found_player == null:
		var grouped: Node = get_tree().get_first_node_in_group("player")
		if grouped is Node2D:
			found_player = grouped as Node2D

	if found_player == null and auto_create_test_player:
		found_player = IsoTestPlayer.new()
		found_player.name = player_node_name
		var parent_for_player: Node = _get_y_sort_parent()
		parent_for_player.add_child(found_player)
		found_player.add_to_group("player")
		print("[IsoRuntimeAdapter] Created IsoTestPlayer.")

	if found_player != null and player_spawn != null and move_existing_nodes_to_markers:
		found_player.global_position = player_spawn.global_position

	return found_player


func _find_or_create_patron_flow(
	reward_socket: Node2D,
	door_left: Node2D,
	door_center: Node2D,
	door_right: Node2D
) -> IsoPatronFlowController:
	var found_flow: IsoPatronFlowController = null
	var named: Node = room_root.find_child(patron_flow_node_name, true, false)
	if named is IsoPatronFlowController:
		found_flow = named as IsoPatronFlowController

	if found_flow == null and auto_create_patron_flow:
		found_flow = IsoPatronFlowController.new()
		found_flow.name = patron_flow_node_name
		room_root.add_child(found_flow)
		found_flow.position = Vector2.ZERO
		print("[IsoRuntimeAdapter] Created PatronFlow.")

	if found_flow != null:
		if reward_socket != null:
			found_flow.altar_position = found_flow.to_local(reward_socket.global_position)
		if door_left != null:
			found_flow.gate_left_position = found_flow.to_local(door_left.global_position)
		if door_center != null:
			found_flow.gate_center_position = found_flow.to_local(door_center.global_position)
		if door_right != null:
			found_flow.gate_right_position = found_flow.to_local(door_right.global_position)

	return found_flow


func _ensure_camera(target_player: Node2D) -> void:
	var camera: Camera2D = null
	for child: Node in target_player.get_children():
		if child is Camera2D:
			camera = child as Camera2D
			break

	if camera == null:
		camera = Camera2D.new()
		camera.name = "IsoRoomCamera"
		target_player.add_child(camera)
		print("[IsoRuntimeAdapter] Created player Camera2D.")

	camera.position = Vector2.ZERO
	camera.zoom = camera_zoom
	camera.position_smoothing_enabled = camera_smoothing_enabled
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.enabled = true
	camera.make_current()


func _get_y_sort_parent() -> Node:
	var candidates: Array[String] = [
		"L3_YSorted",
		"YSorted",
		"Actors",
		"Runtime",
		"RuntimeActors"
	]

	for candidate: String in candidates:
		var node: Node = room_root.find_child(candidate, true, false)
		if node != null:
			return node

	return room_root


func _find_named_node2d(node_name: String) -> Node2D:
	if room_root == null:
		return null
	var node: Node = room_root.find_child(node_name, true, false)
	if node is Node2D:
		return node as Node2D
	return null


func _find_marker(candidate_names: Array[String]) -> Node2D:
	var marker_root: Node = room_root.find_child(marker_root_name, true, false)
	var search_root: Node = marker_root if marker_root != null else room_root

	for candidate_name: String in candidate_names:
		var exact: Node = search_root.find_child(candidate_name, true, false)
		if exact is Node2D:
			return exact as Node2D

	var normalized_candidates: Array[String] = []
	for candidate_name: String in candidate_names:
		normalized_candidates.append(_normalize_marker_name(candidate_name))

	var all_nodes: Array[Node] = []
	_collect_nodes(search_root, all_nodes)

	for node: Node in all_nodes:
		if node is Node2D:
			var normalized_node_name: String = _normalize_marker_name(node.name)
			if normalized_candidates.has(normalized_node_name):
				return node as Node2D

	for node: Node in all_nodes:
		if node is Node2D:
			var normalized_node_name: String = _normalize_marker_name(node.name)
			for normalized_candidate: String in normalized_candidates:
				if normalized_node_name.find(normalized_candidate) >= 0:
					return node as Node2D

	return null


func _collect_nodes(root: Node, out_nodes: Array[Node]) -> void:
	for child: Node in root.get_children():
		out_nodes.append(child)
		_collect_nodes(child, out_nodes)


func _normalize_marker_name(value: String) -> String:
	var s: String = value.to_lower()
	s = s.replace(" ", "")
	s = s.replace("_", "")
	s = s.replace("-", "")
	s = s.replace(".", "")
	return s


func _print_mapping(
	player_spawn: Node2D,
	reward_socket: Node2D,
	door_left: Node2D,
	door_center: Node2D,
	door_right: Node2D
) -> void:
	print("[IsoRuntimeAdapter] Room root: %s" % room_root.name)
	print("[IsoRuntimeAdapter] PlayerSpawn: %s" % _node_label(player_spawn))
	print("[IsoRuntimeAdapter] RewardSocket: %s" % _node_label(reward_socket))
	print("[IsoRuntimeAdapter] Door L: %s" % _node_label(door_left))
	print("[IsoRuntimeAdapter] Door C: %s" % _node_label(door_center))
	print("[IsoRuntimeAdapter] Door R: %s" % _node_label(door_right))


func _node_label(node: Node2D) -> String:
	if node == null:
		return "MISSING"
	return "%s @ %s" % [node.name, str(node.global_position)]
