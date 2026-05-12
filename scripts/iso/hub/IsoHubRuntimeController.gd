extends Node2D
class_name IsoHubRuntimeController

const PLAYER_SCRIPT: Script = preload("res://scripts/iso/IsoPhysicsTestPlayer.gd")

@export var run_scene_path: String = "res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn"
@export var marker_root_name: String = "Markers"
@export var y_sorted_root_name: String = "L3_YSorted"
@export var interact_radius: float = 82.0
@export var auto_spawn_player: bool = true
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_speed: float = 8.0

var player_node: Node2D = null
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var status_text: String = "Hub ready. Walk to a station."
var _e_down_previous: bool = false

var station_defs: Array[Dictionary] = [
	{
		"marker": "HellGateStart",
		"title": "Hell Gate",
		"prompt": "Press E to descend into Circle 0.",
		"kind": "run_start"
	},
	{
		"marker": "WeaponAltarMarker",
		"title": "Weapon Altar",
		"prompt": "Press E — weapon selection and aspects coming soon.",
		"kind": "placeholder"
	},
	{
		"marker": "BoonShrineMarker",
		"title": "Boon Shrine",
		"prompt": "Press E — patron relationships coming soon.",
		"kind": "placeholder"
	},
	{
		"marker": "TrainingDummyMarker",
		"title": "Training Yard",
		"prompt": "Press E — dummy training coming soon.",
		"kind": "placeholder"
	},
	{
		"marker": "FountainMarker",
		"title": "Fountain",
		"prompt": "Press E — recovery station coming soon.",
		"kind": "placeholder"
	}
]

func _ready() -> void:
	_setup_hud()
	if auto_spawn_player:
		call_deferred("_spawn_player_from_marker")

func _process(_delta: float) -> void:
	var nearest_station: Dictionary = _get_nearest_station()

	if nearest_station.is_empty():
		status_text = "Hub ready. Walk to a station."
	else:
		status_text = "%s — %s" % [
			str(nearest_station.get("title", "Station")),
			str(nearest_station.get("prompt", "Press E."))
		]

		if _interact_pressed_once():
			_activate_station(nearest_station)

	_update_hud()

func _spawn_player_from_marker() -> void:
	var spawn_marker: Node2D = _find_marker("PlayerSpawn")
	var spawn_position: Vector2 = Vector2(640.0, 650.0)
	if spawn_marker != null:
		spawn_position = spawn_marker.global_position

	player_node = _find_existing_player()
	if player_node == null:
		player_node = PLAYER_SCRIPT.new()
		player_node.name = "IsoHubPlayer"
		var parent_node: Node = _get_y_sorted_root()
		parent_node.add_child(player_node)
		print("[IsoHubRuntime] Created IsoHubPlayer.")

	player_node.global_position = spawn_position
	_ensure_camera(player_node)

func _find_existing_player() -> Node2D:
	var grouped_players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node: Node in grouped_players:
		if node is Node2D and _is_node_inside_this_scene(node):
			return node as Node2D
	return null

func _ensure_camera(target_player: Node2D) -> void:
	var camera: Camera2D = null
	for child: Node in target_player.get_children():
		if child is Camera2D:
			camera = child as Camera2D
			break

	if camera == null:
		camera = Camera2D.new()
		camera.name = "IsoHubCamera"
		target_player.add_child(camera)

	camera.position = Vector2.ZERO
	camera.zoom = camera_zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.enabled = true
	camera.make_current()

func _get_nearest_station() -> Dictionary:
	if player_node == null or not is_instance_valid(player_node):
		player_node = _find_existing_player()
		if player_node == null:
			return {}

	var best_station: Dictionary = {}
	var best_distance: float = INF

	for station: Dictionary in station_defs:
		var marker_name: String = str(station.get("marker", ""))
		var marker: Node2D = _find_marker(marker_name)
		if marker == null:
			continue

		var distance: float = player_node.global_position.distance_to(marker.global_position)
		if distance <= interact_radius and distance < best_distance:
			best_distance = distance
			best_station = station

	return best_station

func _activate_station(station: Dictionary) -> void:
	var kind: String = str(station.get("kind", "placeholder"))
	var title: String = str(station.get("title", "Station"))

	if kind == "run_start":
		print("[IsoHubRuntime] Starting run: " + run_scene_path)
		status_text = "Opening the Hell Gate..."
		_update_hud()
		get_tree().change_scene_to_file(run_scene_path)
		return

	print("[IsoHubRuntime] Placeholder station used: " + title)
	status_text = "%s is not implemented yet." % title

func _find_marker(marker_name: String) -> Node2D:
	var marker_root: Node = get_parent().find_child(marker_root_name, true, false)
	var search_root: Node = marker_root if marker_root != null else get_parent()
	var marker_node: Node = search_root.find_child(marker_name, true, false)
	if marker_node is Node2D:
		return marker_node as Node2D
	return null

func _get_y_sorted_root() -> Node:
	var found: Node = get_parent().find_child(y_sorted_root_name, true, false)
	if found != null:
		return found
	return get_parent()

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HubHUD"
	add_child(hud_layer)

	hud_label = Label.new()
	hud_label.name = "HubStatusLabel"
	hud_label.position = Vector2(18.0, 18.0)
	hud_label.size = Vector2(820.0, 130.0)
	hud_layer.add_child(hud_label)

func _update_hud() -> void:
	if hud_label == null:
		return

	hud_label.text = "Infernal Ascent Hub V1\n%s\nHell Gate target: combat_ash_intake_hall_01_iso.tscn" % status_text

func _interact_pressed_once() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true

	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	var just_pressed: bool = e_down and not _e_down_previous
	_e_down_previous = e_down
	return just_pressed

func _is_node_inside_this_scene(node: Node) -> bool:
	var root: Node = get_parent()
	var cursor: Node = node
	while cursor != null:
		if cursor == root:
			return true
		cursor = cursor.get_parent()
	return false
