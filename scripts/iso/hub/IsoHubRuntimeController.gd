extends Node2D
class_name IsoHubRuntimeController

const PLAYER_SCRIPT: Script = preload("res://scripts/iso/IsoPhysicsTestPlayer.gd")
const PANEL_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubInteractionPanel.gd")
const NPC_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubNPC.gd")

@export var run_scene_path: String = "res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn"
@export var marker_root_name: String = "Markers"
@export var y_sorted_root_name: String = "L3_YSorted"
@export var interact_radius: float = 82.0
@export var npc_interact_radius: float = 92.0
@export var auto_spawn_player: bool = true
@export var auto_spawn_npcs: bool = true
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_speed: float = 8.0
@export var training_dummy_health: int = 8

var player_node: Node2D = null
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var interaction_panel: IsoHubInteractionPanel = null
var training_dummy: IsoTestEnemy = null
var spawned_npcs: Array[IsoHubNPC] = []

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
		"prompt": "Press E to inspect your current weapon.",
		"kind": "weapon_altar",
		"body": ""
	},
	{
		"marker": "BoonShrineMarker",
		"title": "Patron Shrine",
		"prompt": "Press E to inspect patrons and relationships.",
		"kind": "patron_shrine",
		"body": ""
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
		"prompt": "Press E to view last run results.",
		"kind": "fountain_results",
		"body": ""
	}
]

var npc_defs: Array[Dictionary] = [
	{
		"id": "weapon_keeper",
		"name": "Varric, Weapon Keeper",
		"role": "armory",
		"marker": "WeaponAltarMarker",
		"offset": Vector2(-82.0, -52.0),
		"color": Color("#d1a45b"),
		"body": "Weapon Keeper placeholder.\n\nThe Weapon Altar now shows your current weapon: Penitent Blade.\n\nNext planned step for this station:\n- choose between unlocked weapons\n- inspect weapon aspects\n- apply forge upgrades\n- compare weapon roles before starting a run"
	},
	{
		"id": "shrine_attendant",
		"name": "The Veiled Attendant",
		"role": "patrons",
		"marker": "BoonShrineMarker",
		"offset": Vector2(78.0, -56.0),
		"color": Color("#9fd8ff"),
		"body": ""
	},
	{
		"id": "archivist",
		"name": "Erem, Ash Archivist",
		"role": "codex",
		"marker": "FountainMarker",
		"offset": Vector2(155.0, -135.0),
		"color": Color("#bca98d"),
		"body": "Archivist placeholder.\n\nThis NPC will become the codex keeper.\n\nPlanned records:\n- enemies encountered\n- patron boons discovered\n- boss records\n- run history\n- institutional lore about Hell and the Circles"
	},
	{
		"id": "toll_clerk",
		"name": "Marta, Toll Clerk",
		"role": "merchant",
		"marker": "TrainingDummyMarker",
		"offset": Vector2(-165.0, -98.0),
		"color": Color("#d8b866"),
		"body": "Toll Clerk placeholder.\n\nThis NPC will become the shop/economy contact.\n\nPlanned function:\n- spend run currency\n- buy starting supplies\n- exchange resources\n- explain harder-run modifiers and rewards"
	}
]

func _ready() -> void:
	_setup_hud()
	_setup_interaction_panel()
	if auto_spawn_player:
		call_deferred("_spawn_player_from_marker")
	if auto_spawn_npcs:
		call_deferred("_spawn_hub_npcs")

	if RunSessionData.has_last_run():
		status_text = "Returned from a run. Visit the Fountain to inspect Last Run Results."

func _process(_delta: float) -> void:
	if _panel_is_open():
		_update_panel_input()
		_update_hud()
		return

	var nearest_interactable: Dictionary = _get_nearest_interactable()

	if nearest_interactable.is_empty():
		if RunSessionData.has_last_run():
			status_text = "Hub ready. Last Run Results available at the Fountain."
		else:
			status_text = "Hub ready. Walk to a station or NPC."
	else:
		status_text = "%s — %s" % [
			str(nearest_interactable.get("title", "Interact")),
			str(nearest_interactable.get("prompt", "Press E."))
		]

		if _interact_pressed_once():
			_activate_interactable(nearest_interactable)

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

func _spawn_hub_npcs() -> void:
	_clear_spawned_npcs()

	var parent_node: Node = _get_y_sorted_root()

	for npc_def: Dictionary in npc_defs:
		var npc: IsoHubNPC = NPC_SCRIPT.new()
		npc.name = "NPC_" + str(npc_def.get("id", "unknown"))
		parent_node.add_child(npc)

		var marker_name: String = str(npc_def.get("marker", ""))
		var marker: Node2D = _find_marker(marker_name)
		var base_position: Vector2 = Vector2(640.0, 520.0)
		if marker != null:
			base_position = marker.global_position

		var offset_value: Variant = npc_def.get("offset", Vector2.ZERO)
		var offset: Vector2 = offset_value if offset_value is Vector2 else Vector2.ZERO
		npc.global_position = base_position + offset

		var color_value: Variant = npc_def.get("color", Color("#c59254"))
		var npc_color: Color = color_value if color_value is Color else Color("#c59254")

		npc.setup(
			str(npc_def.get("id", "npc")),
			str(npc_def.get("name", "Hub NPC")),
			str(npc_def.get("role", "placeholder")),
			npc_color
		)

		spawned_npcs.append(npc)

	print("[IsoHubRuntime] Spawned %d hub NPC placeholders." % spawned_npcs.size())

func _clear_spawned_npcs() -> void:
	for npc: IsoHubNPC in spawned_npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	spawned_npcs.clear()

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
		status_text = "Hub ready. Walk to a station or NPC."

func _get_nearest_interactable() -> Dictionary:
	var nearest_station: Dictionary = _get_nearest_station()
	var nearest_npc: Dictionary = _get_nearest_npc()

	if nearest_station.is_empty():
		return nearest_npc
	if nearest_npc.is_empty():
		return nearest_station

	var station_distance: float = float(nearest_station.get("_distance", INF))
	var npc_distance: float = float(nearest_npc.get("_distance", INF))

	if npc_distance <= station_distance:
		return nearest_npc
	return nearest_station

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
			best_station = station.duplicate(true)
			best_station["_kind"] = "station"
			best_station["_distance"] = distance

	return best_station

func _get_nearest_npc() -> Dictionary:
	if player_node == null or not is_instance_valid(player_node):
		player_node = _find_existing_player()
		if player_node == null:
			return {}

	var best_npc: Dictionary = {}
	var best_distance: float = INF

	for i: int in range(spawned_npcs.size()):
		var npc: IsoHubNPC = spawned_npcs[i]
		if npc == null or not is_instance_valid(npc):
			continue

		var distance: float = player_node.global_position.distance_to(npc.global_position)
		if distance <= npc_interact_radius and distance < best_distance:
			best_distance = distance
			var npc_def: Dictionary = npc_defs[i].duplicate(true)
			npc_def["_kind"] = "npc"
			npc_def["_distance"] = distance
			npc_def["title"] = str(npc_def.get("name", "NPC"))
			npc_def["prompt"] = "Press E to talk."
			best_npc = npc_def

	return best_npc

func _activate_interactable(interactable: Dictionary) -> void:
	var kind: String = str(interactable.get("_kind", "station"))
	if kind == "npc":
		_activate_npc(interactable)
		return
	_activate_station(interactable)

func _activate_npc(npc_def: Dictionary) -> void:
	var title: String = str(npc_def.get("name", "Hub NPC"))
	var npc_id: String = str(npc_def.get("id", ""))
	var body: String = str(npc_def.get("body", "This NPC is a placeholder."))

	if npc_id == "shrine_attendant":
		body = PatronShrineData.build_attendant_panel_text()

	_show_panel(title, body)

func _activate_station(station: Dictionary) -> void:
	var kind: String = str(station.get("kind", "placeholder"))
	var title: String = str(station.get("title", "Station"))

	if kind == "run_start":
		print("[IsoHubRuntime] Starting run: " + run_scene_path)
		status_text = "Opening the Hell Gate..."
		_update_hud()
		get_tree().change_scene_to_file(run_scene_path)
		return

	if kind == "weapon_altar":
		_show_weapon_altar_panel()
		return

	if kind == "patron_shrine":
		_show_patron_shrine_panel()
		return

	if kind == "fountain_results":
		_show_fountain_results_panel()
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

func _show_weapon_altar_panel() -> void:
	_show_panel("Weapon Altar", PlayerWeaponData.build_weapon_panel_text())

func _show_patron_shrine_panel() -> void:
	_show_panel("Patron Shrine", PatronShrineData.build_patron_shrine_panel_text())

func _show_fountain_results_panel() -> void:
	_show_panel("Fountain", RunSessionData.build_fountain_panel_text())

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
	hud_label.size = Vector2(900.0, 150.0)
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
