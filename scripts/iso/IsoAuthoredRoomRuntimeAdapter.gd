extends Node2D

class_name IsoAuthoredRoomRuntimeAdapter

@export var use_parent_as_room_root: bool = true
@export var auto_create_test_player: bool = true
@export var auto_create_camera: bool = true
@export var auto_create_patron_flow: bool = true
@export var auto_spawn_test_enemies: bool = true
@export var move_existing_nodes_to_markers: bool = true
@export var clear_room_when_test_enemies_dead: bool = true
@export var hide_legacy_node2d_test_player: bool = true
@export var debug_print_mapping: bool = true
@export var player_node_name: String = "IsoPhysicsTestPlayer"
@export var patron_flow_node_name: String = "PatronFlow"
@export var marker_root_name: String = "Markers"
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_enabled: bool = true
@export var camera_smoothing_speed: float = 8.0
@export var test_enemy_health: int = 3
@export var test_enemy_movement_enabled: bool = true

@export_category("Ash Intake Encounter V1")
@export var use_encounter_director: bool = true
@export var max_enemies_cycle_1: int = 2
@export var max_enemies_cycle_2: int = 3
@export var max_enemies_cycle_3_plus: int = 4
@export var show_enemy_debug_ranges: bool = false

var room_root: Node = null
var player_node: Node2D = null
var patron_flow_node: IsoPatronFlowController = null
var spawned_enemies: Array[IsoTestEnemy] = []
var shared_patron_manager_override: PatronRunManager = null
var _room_cleared: bool = false
var _alive_enemy_count: int = 0
var _encounter_cycle_index: int = 1

func _ready() -> void:
	room_root = _get_room_root()
	if room_root == null:
		push_warning("[IsoRuntimeAdapter] No room root found.")
		return
	if hide_legacy_node2d_test_player:
		_hide_legacy_test_players()
	_setup_runtime_nodes()

func set_shared_patron_manager(manager: PatronRunManager) -> void:
	shared_patron_manager_override = manager
	if patron_flow_node != null and manager != null:
		patron_flow_node.set_manager(manager)
		print("[IsoRuntimeAdapter] PatronFlow linked to local room-loop manager.")

func set_encounter_cycle_index(cycle_index: int) -> void:
	_encounter_cycle_index = maxi(1, cycle_index)

func reset_runtime_for_next_room() -> void:
	if room_root == null:
		room_root = _get_room_root()
	if room_root == null:
		return
	_clear_existing_test_enemies()
	_clear_existing_projectiles()
	_room_cleared = false
	_alive_enemy_count = 0
	_setup_runtime_nodes()
	if patron_flow_node != null:
		patron_flow_node.clear_runtime_elements()
	print("[IsoRuntimeAdapter] Runtime reset for next room cycle.")

func _setup_runtime_nodes() -> void:
	var player_spawn: Node2D = _find_marker(["PlayerSpawn", "Player Spawn", "SpawnPlayer", "Spawn_Player", "player_spawn"])
	var reward_socket: Node2D = _find_marker(["RewardSocket", "Reward Socket", "Reward", "BoonSocket", "Boon Socket", "AltarSocket", "Altar Socket"])
	var door_left: Node2D = _find_marker(["DoorL", "Door L", "Door_Left", "DoorLeft", "LeftDoor", "DoorSocketLeft", "DoorSocket_L"])
	var door_center: Node2D = _find_marker(["DoorC", "Door C", "Door_C", "DoorCenter", "CenterDoor", "DoorSocketCenter", "DoorSocket_C"])
	var door_right: Node2D = _find_marker(["DoorR", "Door R", "Door_Right", "DoorRight", "RightDoor", "DoorSocketRight", "DoorSocket_R"])
	player_node = _find_or_create_player(player_spawn)
	patron_flow_node = _find_or_create_patron_flow(reward_socket, door_left, door_center, door_right)
	if auto_create_camera and player_node != null:
		_ensure_camera(player_node)
	if auto_spawn_test_enemies:
		_spawn_test_enemies_from_markers()
	if debug_print_mapping:
		_print_mapping(player_spawn, reward_socket, door_left, door_center, door_right)

func _get_room_root() -> Node:
	if use_parent_as_room_root and get_parent() != null:
		return get_parent()
	return self

func _find_shared_patron_manager() -> PatronRunManager:
	if shared_patron_manager_override != null:
		return shared_patron_manager_override
	if room_root != null and room_root.has_meta("shared_patron_manager"):
		var meta_value: Variant = room_root.get_meta("shared_patron_manager")
		if meta_value is PatronRunManager:
			return meta_value as PatronRunManager
	return null

func _hide_legacy_test_players() -> void:
	if room_root == null:
		return
	var legacy_node: Node = room_root.find_child("IsoTestPlayer", true, false)
	if legacy_node != null and not (legacy_node is CharacterBody2D):
		legacy_node.remove_from_group("player")
		legacy_node.set_process(false)
		legacy_node.set_physics_process(false)
		if legacy_node is CanvasItem:
			(legacy_node as CanvasItem).visible = false
		print("[IsoRuntimeAdapter] Hidden legacy Node2D IsoTestPlayer. Physics player will be used.")

func _find_or_create_player(player_spawn: Node2D) -> Node2D:
	var found_player: Node2D = null
	var named: Node = room_root.find_child(player_node_name, true, false)
	if named is IsoPhysicsTestPlayer:
		found_player = named as Node2D
	if found_player == null:
		var grouped_players: Array[Node] = get_tree().get_nodes_in_group("player")
		for grouped_node: Node in grouped_players:
			if grouped_node is IsoPhysicsTestPlayer and _is_node_inside_room(grouped_node):
				found_player = grouped_node as Node2D
				break
	if found_player == null and auto_create_test_player:
		var physics_player: IsoPhysicsTestPlayer = IsoPhysicsTestPlayer.new()
		physics_player.name = player_node_name
		var parent_for_player: Node = _get_y_sort_parent()
		parent_for_player.add_child(physics_player)
		physics_player.add_to_group("player")
		found_player = physics_player
		print("[IsoRuntimeAdapter] Created IsoPhysicsTestPlayer.")
	if found_player != null and player_spawn != null and move_existing_nodes_to_markers:
		found_player.global_position = player_spawn.global_position
	return found_player

func _find_or_create_patron_flow(reward_socket: Node2D, door_left: Node2D, door_center: Node2D, door_right: Node2D) -> IsoPatronFlowController:
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
		var shared_manager: PatronRunManager = _find_shared_patron_manager()
		if shared_manager != null:
			found_flow.set_manager(shared_manager)
			print("[IsoRuntimeAdapter] PatronFlow linked to shared manager.")
		if reward_socket != null:
			found_flow.altar_position = found_flow.to_local(reward_socket.global_position)
		if door_left != null:
			found_flow.gate_left_position = found_flow.to_local(door_left.global_position)
		if door_center != null:
			found_flow.gate_center_position = found_flow.to_local(door_center.global_position)
		if door_right != null:
			found_flow.gate_right_position = found_flow.to_local(door_right.global_position)
	return found_flow

func _spawn_test_enemies_from_markers() -> void:
	var enemy_markers: Array[Node2D] = _find_enemy_markers()
	if enemy_markers.is_empty():
		print("[IsoRuntimeAdapter] No enemy markers found. Press C can still clear room in debug.")
		return
	var parent_for_enemies: Node = _get_y_sort_parent()
	spawned_enemies.clear()
	_alive_enemy_count = 0
	_room_cleared = false
	var profiles: Array[String] = _get_encounter_profiles(enemy_markers.size())
	for i: int in range(profiles.size()):
		var marker: Node2D = enemy_markers[i % enemy_markers.size()]
		var enemy: IsoTestEnemy = IsoTestEnemy.new()
		enemy.name = "IsoTestEnemy_%s_%s" % [profiles[i], marker.name]
		parent_for_enemies.add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.configure_for_encounter_type(profiles[i], _encounter_cycle_index)
		if not use_encounter_director:
			enemy.max_health = test_enemy_health
			enemy.health = enemy.max_health
			enemy.move_enabled = test_enemy_movement_enabled
		enemy.show_debug_aggro_radius = show_enemy_debug_ranges
		enemy.show_debug_attack_range = show_enemy_debug_ranges
		enemy.show_debug_active_hitbox = show_enemy_debug_ranges
		enemy.died.connect(_on_test_enemy_died)
		spawned_enemies.append(enemy)
		_alive_enemy_count += 1
	print("[IsoRuntimeAdapter] Spawned encounter cycle %d: %s" % [_encounter_cycle_index, str(profiles)])

func _get_encounter_profiles(marker_count: int) -> Array[String]:
	if not use_encounter_director:
		var legacy: Array[String] = []
		for i: int in range(marker_count):
			legacy.append("ash_grunt")
		return legacy
	var max_count: int = max_enemies_cycle_3_plus
	var profiles: Array[String] = []
	if _encounter_cycle_index <= 1:
		max_count = max_enemies_cycle_1
		profiles = ["ash_grunt", "ash_grunt"]
	elif _encounter_cycle_index == 2:
		max_count = max_enemies_cycle_2
		profiles = ["ash_grunt", "cinder_lunger", "ash_grunt"]
	else:
		max_count = max_enemies_cycle_3_plus
		profiles = ["ash_grunt", "cinder_lunger", "ember_spitter", "ash_grunt"]
	var final_count: int = mini(marker_count, maxi(1, max_count))
	while profiles.size() > final_count:
		profiles.pop_back()
	while profiles.size() < final_count:
		profiles.append("ash_grunt")
	return profiles

func _clear_existing_test_enemies() -> void:
	for enemy: IsoTestEnemy in spawned_enemies:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
	var group_nodes: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for node: Node in group_nodes:
		if _is_node_inside_room(node):
			node.queue_free()

func _clear_existing_projectiles() -> void:
	var nodes: Array[Node] = []
	_collect_nodes(room_root if room_root != null else self, nodes)
	for node: Node in nodes:
		if node is AshBoltProjectile:
			node.queue_free()

func _on_test_enemy_died(enemy: IsoTestEnemy) -> void:
	var enemy_index: int = spawned_enemies.find(enemy)
	if enemy_index >= 0:
		spawned_enemies.remove_at(enemy_index)
	_alive_enemy_count = max(0, _alive_enemy_count - 1)
	print("[IsoRuntimeAdapter] Test enemy defeated. Remaining: %d" % _alive_enemy_count)
	if clear_room_when_test_enemies_dead and _alive_enemy_count <= 0:
		_complete_test_room_clear()

func _complete_test_room_clear() -> void:
	if _room_cleared:
		return
	_room_cleared = true
	_clear_existing_projectiles()
	if patron_flow_node != null:
		print("[IsoRuntimeAdapter] Test room cleared. Calling PatronFlow.")
		patron_flow_node.report_room_cleared()
	else:
		push_warning("[IsoRuntimeAdapter] Room cleared but PatronFlow is missing.")

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
	var candidates: Array[String] = ["L3_YSorted", "YSorted", "Actors", "Runtime", "RuntimeActors"]
	for candidate: String in candidates:
		var node: Node = room_root.find_child(candidate, true, false)
		if node != null:
			return node
	return room_root

func _find_enemy_markers() -> Array[Node2D]:
	var marker_root: Node = room_root.find_child(marker_root_name, true, false)
	var search_root: Node = marker_root if marker_root != null else room_root
	var container: Node = _find_enemy_marker_container(search_root)
	if container != null:
		return _get_direct_enemy_marker_children(container)
	var result: Array[Node2D] = []
	var all_nodes: Array[Node] = []
	_collect_nodes(search_root, all_nodes)
	for node: Node in all_nodes:
		if node is Node2D and _is_valid_enemy_marker(node):
			result.append(node as Node2D)
	return result

func _find_enemy_marker_container(search_root: Node) -> Node:
	var container_names: Array[String] = ["EnemySpawns", "EnemySpawnSockets", "EnemySockets", "EnemyMarkers", "Enemies"]
	for container_name: String in container_names:
		var found: Node = search_root.find_child(container_name, true, false)
		if found != null:
			return found
	return null

func _get_direct_enemy_marker_children(container: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child: Node in container.get_children():
		if child is Node2D and _is_valid_enemy_marker(child):
			result.append(child as Node2D)
	return result

func _is_valid_enemy_marker(node: Node) -> bool:
	var normalized_name: String = _normalize_marker_name(node.name)
	if ["enemyspawns", "enemyspawnsockets", "enemysockets", "enemymarkers", "enemies"].has(normalized_name):
		return false
	if normalized_name.find("enemy") < 0:
		return false
	if node.get_child_count() > 0:
		return false
	return true

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

func _is_node_inside_room(node: Node) -> bool:
	if node == null or room_root == null:
		return false
	var cursor: Node = node
	while cursor != null:
		if cursor == room_root:
			return true
		cursor = cursor.get_parent()
	return false

func _collect_nodes(root_node: Node, out_nodes: Array[Node]) -> void:
	if root_node == null:
		return
	for child: Node in root_node.get_children():
		out_nodes.append(child)
		_collect_nodes(child, out_nodes)

func _normalize_marker_name(value: String) -> String:
	var normalized_value: String = value.to_lower()
	normalized_value = normalized_value.replace(" ", "")
	normalized_value = normalized_value.replace("_", "")
	normalized_value = normalized_value.replace("-", "")
	normalized_value = normalized_value.replace(".", "")
	return normalized_value

func _print_mapping(player_spawn: Node2D, reward_socket: Node2D, door_left: Node2D, door_center: Node2D, door_right: Node2D) -> void:
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
