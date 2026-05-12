extends Node2D
class_name IsoHubRuntimeController

const PLAYER_SCRIPT: Script = preload("res://scripts/iso/IsoPhysicsTestPlayer.gd")
const PANEL_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubInteractionPanel.gd")

@export var run_scene_path: String = "res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn"
@export var marker_root_name: String = "Markers"
@export var y_sorted_root_name: String = "L3_YSorted"
@export var interact_radius: float = 82.0
@export var auto_spawn_player: bool = true
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_speed: float = 8.0
@export var training_dummy_health: int = 8

var player_node: Node2D = null
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var interaction_panel: IsoHubInteractionPanel = null
var training_dummy: IsoTestEnemy = null

var status_text: String = "Hub ready. Walk to a station."
var _e_down_previous: bool = false
var _escape_down_previous: bool = false
var _panel_close_armed: bool = false

var station_defs: Array[Dictionary] = [
	{
		"marker": "HellGateStart",
		"title": "Hell Gate",
		"prompt": "Press E to descend into Circle 0.",
		"kind": "run_start",
		"body": "The gate opens into the current test descent: Ash Intake Hall. This starts the run loop."
	},
	{
		"marker": "WeaponAltarMarker",
		"title": "Weapon Altar",
		"prompt": "Press E to inspect the weapon altar.",
		"kind": "panel",
		"body": "Weapon system placeholder.\n\nPlanned function:\n- choose starting weapon\n- inspect weapon stats\n- upgrade base weapon power\n- choose weapon aspects that change the playstyle\n\nCurrent weapon: Penitent Blade.\nCurrent state: placeholder only."
	},
	{
		"marker": "BoonShrineMarker",
		"title": "Boon Shrine",
		"prompt": "Press E to inspect patron relationships.",
		"kind": "panel",
		"body": "Patron relationship placeholder.\n\nCurrent patrons:\n- Francesca: speed and wind attacks\n- Ugolino: survive by hurting enemies\n- Minos: mark and execute enemies\n\nPlanned function:\n- view patron ranks\n- inspect discovered boons\n- unlock starting patron choice"
	},
	{
		"marker": "TrainingDummyMarker",
		"title": "Training Yard",
		"prompt": "Press E to spawn or reset a training dummy.",
		"kind": "training_dummy",
		"body": "Training dummy reset. Use Space or left mouse to attack it.\n\nPlanned function:\n- test weapons\n- test boons\n- show damage numbers\n- spawn enemy practice targets"
	},
	{
		"marker": "FountainMarker",
		"title": "Fountain",
		"prompt": "Press E to inspect the fountain.",
		"kind": "panel",
		"body": "Recovery station placeholder.\n\nPlanned function:\n- restore health after a run\n- show last run results\n- cleanse temporary penalties\n- prepare for the next descent\n\nCurrent state: visual station only."
	}
]

func _ready() -> void:
	_setup_hud()
	_setup_interaction_panel()
	if auto_spawn_player:
		call_deferred("_spawn_player_from_marker")

func _process(_delta: float) -> void:
	if _panel_is_open():
		_update_panel_input()
		_update_hud()
		return

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

func _setup_interaction_panel() -> void:
	interaction_panel = PANEL_SCRIPT.new()
	interaction_panel.name = "HubInteractionPanel"
	add_child(interaction_panel)

func _panel_is_open() -> bool:
	return interaction_panel != null and interaction_panel.is_open()

func _update_panel_input() -> void:
	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	if not e_down:
		_panel_close_armed = true

	var escape_pressed: bool = _escape_pressed_once()
	var e_pressed: bool = _panel_close_armed and _interact_pressed_once()

	if escape_pressed or e_pressed:
		interaction_panel.close_panel()
		_panel_close_armed = false
		status_text = "Hub ready. Walk to a station."

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

	if kind == "training_dummy":
		_spawn_or_reset_training_dummy()
		_show_panel(title, str(station.get("body", "Training dummy reset.")))
		return

	if kind == "panel":
		_show_panel(title, str(station.get("body", "This station is not implemented yet.")))
		return

	print("[IsoHubRuntime] Placeholder station used: " + title)
	_show_panel(title, "This station is not implemented yet.")

func _show_panel(title: String, body: String) -> void:
	if interaction_panel == null:
		_setup_interaction_panel()

	interaction_panel.show_panel(title, body, "Press E or Esc to close.")
	_panel_close_armed = false
	status_text = title + " opened."

func _spawn_or_reset_training_dummy() -> void:
	var marker: Node2D = _find_marker("TrainingDummyMarker")
	var spawn_pos: Vector2 = Vector2(480.0, 620.0)
	if marker != null:
		spawn_pos = marker.global_position

	if training_dummy != null and is_instance_valid(training_dummy):
		training_dummy.queue_free()
		training_dummy = null

	training_dummy = IsoTestEnemy.new()
	training_dummy.name = "HubTrainingDummy"
	training_dummy.max_health = training_dummy_health
	training_dummy.move_enabled = false

	var parent_node: Node = _get_y_sorted_root()
	parent_node.add_child(training_dummy)
	training_dummy.global_position = spawn_pos
	print("[IsoHubRuntime] Training dummy spawned/reset.")

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
	hud_label.size = Vector2(860.0, 140.0)
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

func _escape_pressed_once() -> bool:
	var escape_down: bool = Input.is_physical_key_pressed(KEY_ESCAPE)
	var just_pressed: bool = escape_down and not _escape_down_previous
	_escape_down_previous = escape_down
	return just_pressed

func _is_node_inside_this_scene(node: Node) -> bool:
	var root: Node = get_parent()
	var cursor: Node = node
	while cursor != null:
		if cursor == root:
			return true
		cursor = cursor.get_parent()
	return false
