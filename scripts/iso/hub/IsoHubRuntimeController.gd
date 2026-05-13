extends Node2D
class_name IsoHubRuntimeController

## V26 — Hub Stations V1.
## V27 — Permanent Upgrade V1.
## V28 — Save System V1 loads/saves hub currency, upgrades, and last-run data.

const PLAYER_SCRIPT_PATH: String = "res://scripts/iso/IsoPhysicsTestPlayer.gd"
const PANEL_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubInteractionPanel.gd")
const NPC_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubNPC.gd")
const TRAINING_DUMMY_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubTrainingDummy.gd")
const STATION_MARKER_SCRIPT: Script = preload("res://scripts/iso/hub/IsoHubStationMarker.gd")
const PERMANENT_UPGRADE_SCRIPT: Script = preload("res://scripts/run/PermanentUpgradeData.gd")
const SAVE_GAME_SCRIPT: Script = preload("res://scripts/run/SaveGameData.gd")
const INFERNAL_AUDIO_SCRIPT: Script = preload("res://scripts/audio/InfernalAudio.gd")

@export var run_scene_path: String = "res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn"
@export var marker_root_name: String = "Markers"
@export var y_sorted_root_name: String = "L3_YSorted"
@export var interact_radius: float = 88.0
@export var npc_interact_radius: float = 92.0
@export var auto_spawn_player: bool = true
@export var auto_spawn_npcs: bool = true
@export var auto_spawn_station_markers: bool = true
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_speed: float = 8.0
@export var training_dummy_health: int = 12
@export var show_hub_station_markers: bool = true

var player_node: Node2D = null
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var interaction_panel: IsoHubInteractionPanel = null
var training_dummy: IsoHubTrainingDummy = null
var spawned_npcs: Array[IsoHubNPC] = []
var spawned_station_markers: Array = []

var status_text: String = "Hub ready. Walk to a station."
var _e_down_previous: bool = false
var _escape_down_previous: bool = false
var _panel_close_armed: bool = false
var _open_panel_kind: String = ""
var _upgrade_purchase_message: String = ""
var _upgrade_key_previous: Dictionary = {}

var station_defs: Array[Dictionary] = [
	{
		"marker": "HellGateStart",
		"title": "Hell Gate",
		"prompt": "Press E to begin the Circle 0 demo run.",
		"action_label": "[E] Begin Descent",
		"kind": "run_start",
		"color": Color("#b94632"),
		"fallback_position": Vector2(640.0, 315.0),
		"body": "HELL GATE\n\nBegin the current demo descent.\n\nRoute target:\nHub → Circle 0 → rooms → Ash Warden → victory or death → hub.\n\nThis station starts the playable demo loop."
	},
	{
		"marker": "TrainingDummyMarker",
		"title": "Training Yard",
		"prompt": "Press E to spawn or reset the training dummy.",
		"action_label": "[E] Reset Dummy",
		"kind": "training_dummy",
		"color": Color("#d4a35e"),
		"fallback_position": Vector2(470.0, 625.0),
		"body": "TRAINING YARD\n\nUse this space to test movement, dash, light attack, heavy attack, damage timing, and hit feedback.\n\nControls:\n- WASD: move\n- Shift: dash\n- Space / left mouse: light attack\n- F / right mouse: heavy attack\n\nPress E here again to reset the dummy."
	},
	{
		"marker": "FountainMarker",
		"title": "Memory Pool",
		"prompt": "Press E to inspect the last run result.",
		"action_label": "[E] View Last Run",
		"kind": "memory_pool",
		"color": Color("#8fb6c8"),
		"fallback_position": Vector2(765.0, 520.0),
		"body": ""
	},
	{
		"marker": "BoonShrineMarker",
		"title": "Reliquary Altar",
		"prompt": "Press E to inspect permanent progression.",
		"action_label": "[E] Inspect Altar",
		"kind": "upgrade_altar",
		"color": Color("#c59254"),
		"fallback_position": Vector2(525.0, 455.0),
		"body": "RELIQUARY ALTAR\n\nPermanent upgrades unlock in V27.\n\nThis station will spend Ash Sigils on small permanent bonuses such as max HP, starting damage, dash efficiency, and reward-choice improvements.\n\nCurrent status: altar sealed until the next roadmap milestone."
	},
	{
		"marker": "WeaponAltarMarker",
		"title": "Hub Forge",
		"prompt": "Press E to inspect weapon and forge status.",
		"action_label": "[E] Inspect Forge",
		"kind": "hub_forge",
		"color": Color("#d17b3b"),
		"fallback_position": Vector2(375.0, 500.0),
		"body": "HUB FORGE\n\nThe forge records weapon state and future unlocks.\n\nRun-only forge marks already exist inside runs. Permanent weapon work is still locked.\n\nCurrent weapon: Penitent Blade."
	},
	{
		"marker": "FountainMarker",
		"offset": Vector2(158.0, -140.0),
		"title": "Codex Lectern",
		"prompt": "Press E to inspect enemy and lore records.",
		"action_label": "[E] Open Codex",
		"kind": "codex",
		"color": Color("#bca98d"),
		"fallback_position": Vector2(905.0, 382.0),
		"body": "CODEX LECTERN\n\nRecords unlock later.\n\nPlanned demo records:\n- Circle 0 enemies\n- Ash Warden boss entry\n- room and hazard notes\n- institutional lore about Hell as a punishment machine\n\nCurrent status: placeholder station."
	},
	{
		"marker": "HellGateStart",
		"offset": Vector2(215.0, 48.0),
		"title": "Sealed Descent Door",
		"prompt": "Press E to inspect the sealed future route.",
		"action_label": "[E] Inspect Seal",
		"kind": "sealed_door",
		"locked": true,
		"color": Color("#6d5b4d"),
		"fallback_position": Vector2(850.0, 360.0),
		"body": "SEALED DESCENT DOOR\n\nThe route beyond Circle 0 is locked for the demo.\n\nFuture full-game path:\nCircle 0 → deeper circles → final descent toward Lucifer.\n\nCurrent status: locked future-content marker."
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
		"body": "Weapon Keeper placeholder.\n\nThe Hub Forge now shows the current weapon state.\n\nNext planned weapon work comes after the demo foundation is stable."
	},
	{
		"id": "shrine_attendant",
		"name": "The Veiled Attendant",
		"role": "reliquary",
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
		"body": "Archivist placeholder.\n\nThis NPC will become the codex keeper for enemies, bosses, rooms, hazards, and Hell's institutional lore."
	},
	{
		"id": "toll_clerk",
		"name": "Marta, Toll Clerk",
		"role": "merchant",
		"marker": "TrainingDummyMarker",
		"offset": Vector2(-165.0, -98.0),
		"color": Color("#d8b866"),
		"body": ""
	}
]

func _ready() -> void:
	call_deferred("_audio_context", "hub")
	SaveGameData.load_or_create()
	_setup_hud()
	_setup_interaction_panel()
	if auto_spawn_station_markers:
		call_deferred("_spawn_station_markers")
	if auto_spawn_player:
		call_deferred("_spawn_player_from_marker")
	if auto_spawn_npcs:
		call_deferred("_spawn_hub_npcs")
	if RunSessionData.has_last_run():
		status_text = "Returned from a run. Visit the Memory Pool to inspect the result."

func _process(_delta: float) -> void:
	if _panel_is_open():
		_update_panel_input()
		_update_hud()
		_update_station_marker_focus({})
		return

	var nearest_interactable: Dictionary = _get_nearest_interactable()
	if nearest_interactable.is_empty():
		if RunSessionData.has_last_run():
			status_text = "Hub ready. Last Run Results available at the Memory Pool."
		else:
			status_text = "Hub ready. Walk to a station."
	else:
		status_text = "%s — %s" % [str(nearest_interactable.get("title", "Interact")), str(nearest_interactable.get("prompt", "Press E."))]
		if _interact_pressed_once():
			_activate_interactable(nearest_interactable)

	_update_station_marker_focus(nearest_interactable)
	_update_hud()

func _spawn_player_from_marker() -> void:
	var spawn_marker: Node2D = _find_marker("PlayerSpawn")
	var spawn_position: Vector2 = Vector2(640.0, 650.0)
	if spawn_marker != null:
		spawn_position = spawn_marker.global_position

	player_node = _find_existing_player()
	if player_node == null:
		player_node = _create_player_instance()
		if player_node == null:
			status_text = "Player script could not be loaded. Check IsoPhysicsTestPlayer.gd."
			push_error("[IsoHubRuntime] Could not create player from " + PLAYER_SCRIPT_PATH)
			return
		player_node.name = "IsoHubPlayer"
		_get_y_sorted_root().add_child(player_node)
		print("[IsoHubRuntime] Created IsoHubPlayer.")

	player_node.global_position = spawn_position
	_ensure_camera(player_node)


func _create_player_instance() -> Node2D:
	if not ResourceLoader.exists(PLAYER_SCRIPT_PATH):
		push_error("[IsoHubRuntime] Missing player script: " + PLAYER_SCRIPT_PATH)
		return null

	var loaded_resource: Resource = load(PLAYER_SCRIPT_PATH)
	var player_script: Script = loaded_resource as Script
	if player_script == null:
		push_error("[IsoHubRuntime] Player script exists but could not be loaded. It may contain a parser error: " + PLAYER_SCRIPT_PATH)
		return null

	var player_instance: Object = player_script.new()
	if not player_instance is Node2D:
		push_error("[IsoHubRuntime] Player script did not create a Node2D instance: " + PLAYER_SCRIPT_PATH)
		return null

	return player_instance as Node2D

func _spawn_station_markers() -> void:
	_clear_station_markers()
	if not show_hub_station_markers:
		return
	var parent_node: Node = _get_y_sorted_root()
	for station: Dictionary in station_defs:
		var marker_node = STATION_MARKER_SCRIPT.new()
		marker_node.name = "Station_" + str(station.get("kind", "station"))
		parent_node.add_child(marker_node)
		var station_color: Color = station.get("color", Color("#c59254")) as Color
		marker_node.global_position = _get_station_world_position(station)
		marker_node.setup(
			str(station.get("title", "Station")),
			str(station.get("kind", "station")),
			str(station.get("action_label", "[E] Inspect")),
			station_color,
			bool(station.get("locked", false))
		)
		spawned_station_markers.append(marker_node)

func _clear_station_markers() -> void:
	for marker_node in spawned_station_markers:
		if marker_node != null and is_instance_valid(marker_node):
			marker_node.queue_free()
	spawned_station_markers.clear()

func _update_station_marker_focus(nearest_interactable: Dictionary) -> void:
	var focused_title: String = ""
	if not nearest_interactable.is_empty() and str(nearest_interactable.get("_kind", "")) == "station":
		focused_title = str(nearest_interactable.get("title", ""))
	for marker_node in spawned_station_markers:
		if marker_node != null and is_instance_valid(marker_node) and marker_node.has_method("set_focused"):
			marker_node.set_focused(str(marker_node.get("station_title")) == focused_title)

func _spawn_hub_npcs() -> void:
	_clear_spawned_npcs()
	var parent_node: Node = _get_y_sorted_root()

	for npc_def: Dictionary in npc_defs:
		var npc: IsoHubNPC = NPC_SCRIPT.new()
		npc.name = "NPC_" + str(npc_def.get("id", "unknown"))
		parent_node.add_child(npc)

		var marker: Node2D = _find_marker(str(npc_def.get("marker", "")))
		var base_position: Vector2 = Vector2(640.0, 520.0)
		if marker != null:
			base_position = marker.global_position

		var offset: Vector2 = npc_def.get("offset", Vector2.ZERO) as Vector2
		var npc_color: Color = npc_def.get("color", Color("#c59254")) as Color
		npc.global_position = base_position + offset

		npc.setup(str(npc_def.get("id", "npc")), str(npc_def.get("name", "Hub NPC")), str(npc_def.get("role", "placeholder")), npc_color)
		spawned_npcs.append(npc)

	print("[IsoHubRuntime] Spawned %d hub NPC placeholders." % spawned_npcs.size())

func _clear_spawned_npcs() -> void:
	for npc: IsoHubNPC in spawned_npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	spawned_npcs.clear()

func _find_existing_player() -> Node2D:
	for node: Node in get_tree().get_nodes_in_group("player"):
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
	if _open_panel_kind == "upgrade_altar":
		_update_reliquary_purchase_input()

	if not Input.is_physical_key_pressed(KEY_E):
		_panel_close_armed = true

	var escape_pressed: bool = _escape_pressed_once()
	var e_pressed: bool = _panel_close_armed and _interact_pressed_once()
	if escape_pressed or e_pressed:
		interaction_panel.close_panel()
		_panel_close_armed = false
		_open_panel_kind = ""
		status_text = "Hub ready. Walk to a station."

func _update_reliquary_purchase_input() -> void:
	var key_map: Dictionary = {
		1: KEY_1,
		2: KEY_2,
		3: KEY_3,
		4: KEY_4,
		5: KEY_5,
	}
	for slot: int in key_map.keys():
		var key_code: int = int(key_map[slot])
		var is_down: bool = Input.is_physical_key_pressed(key_code)
		var was_down: bool = bool(_upgrade_key_previous.get(slot, false))
		if is_down and not was_down:
			_try_purchase_reliquary_upgrade(slot)
		_upgrade_key_previous[slot] = is_down

func _try_purchase_reliquary_upgrade(slot: int) -> void:
	var upgrade_id: String = PERMANENT_UPGRADE_SCRIPT.get_upgrade_id_for_slot(slot)
	if upgrade_id == "":
		return
	var result: Dictionary = PERMANENT_UPGRADE_SCRIPT.purchase_upgrade(upgrade_id)
	if bool(result.get("ok", false)):
		SaveGameData.save_game("permanent_upgrade_purchase")
	_audio_event("reliquary_purchase" if bool(result.get("success", false)) else "hazard_warning")
	_upgrade_purchase_message = str(result.get("message", "Purchase checked."))
	status_text = _upgrade_purchase_message
	if interaction_panel != null:
		interaction_panel.show_panel("Reliquary Altar", _build_reliquary_panel_text(), "Press 1–5 to buy · E or Esc to close")
	_update_hud()

func _get_nearest_interactable() -> Dictionary:
	var nearest_station: Dictionary = _get_nearest_station()
	var nearest_npc: Dictionary = _get_nearest_npc()

	if nearest_station.is_empty():
		return nearest_npc
	if nearest_npc.is_empty():
		return nearest_station

	if float(nearest_npc.get("_distance", INF)) <= float(nearest_station.get("_distance", INF)):
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
		var station_position: Vector2 = _get_station_world_position(station)
		var distance: float = player_node.global_position.distance_to(station_position)
		if distance <= interact_radius and distance < best_distance:
			best_distance = distance
			best_station = station.duplicate(true)
			best_station["_kind"] = "station"
			best_station["_distance"] = distance
			best_station["_world_position"] = station_position

	return best_station

func _get_station_world_position(station: Dictionary) -> Vector2:
	var fallback_position: Vector2 = station.get("fallback_position", Vector2(640.0, 520.0)) as Vector2
	var marker: Node2D = _find_marker(str(station.get("marker", "")))
	var position: Vector2 = fallback_position
	if marker != null:
		position = marker.global_position
	var offset: Vector2 = station.get("offset", Vector2.ZERO) as Vector2
	return position + offset

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
	if str(interactable.get("_kind", "station")) == "npc":
		_activate_npc(interactable)
	else:
		_activate_station(interactable)

func _activate_npc(npc_def: Dictionary) -> void:
	var title: String = str(npc_def.get("name", "Hub NPC"))
	var npc_id: String = str(npc_def.get("id", ""))
	var body: String = str(npc_def.get("body", "This NPC is a placeholder."))

	if npc_id == "shrine_attendant":
		body = PatronShrineData.build_attendant_panel_text()
	elif npc_id == "toll_clerk":
		body = RunEconomyData.build_toll_clerk_panel_text()

	_show_panel(title, body)

func _activate_station(station: Dictionary) -> void:
	var kind: String = str(station.get("kind", "placeholder"))
	var title: String = str(station.get("title", "Station"))

	if kind == "run_start":
		_audio_event("gate_open")
		_audio_context("combat")
		print("[IsoHubRuntime] Starting run: " + run_scene_path)
		status_text = "Opening the Hell Gate..."
		_update_hud()
		get_tree().change_scene_to_file(run_scene_path)
		return

	if kind == "training_dummy":
		_audio_event("reward_claim")
		_spawn_or_reset_training_dummy()
		_show_panel(title, str(station.get("body", "Training dummy reset.")))
		return

	if kind == "memory_pool" or kind == "fountain_results":
		_audio_event("hub_ui_select")
		_show_panel("Memory Pool", RunSessionData.build_fountain_panel_text())
		return

	if kind == "upgrade_altar" or kind == "patron_shrine":
		_audio_event("hub_ui_select")
		_open_panel_kind = "upgrade_altar"
		_upgrade_purchase_message = ""
		_upgrade_key_previous.clear()
		_show_panel("Reliquary Altar", _build_reliquary_panel_text(), "Press 1–5 to buy · E or Esc to close")
		return

	if kind == "hub_forge" or kind == "weapon_altar":
		_audio_event("hub_ui_select")
		_show_panel("Hub Forge", _build_hub_forge_panel_text())
		return

	if kind == "codex":
		_audio_event("hub_ui_select")
		_show_panel("Codex Lectern", _build_codex_panel_text())
		return

	if kind == "sealed_door":
		_audio_event("hazard_warning")
		_show_panel("Sealed Descent Door", str(station.get("body", "This door is sealed.")))
		return

	if kind == "panel":
		_show_panel(title, str(station.get("body", "This station is not implemented yet.")))
		return

	_show_panel(title, "This station is not implemented yet.")

func _build_reliquary_panel_text() -> String:
	return PERMANENT_UPGRADE_SCRIPT.build_upgrade_panel_text(_upgrade_purchase_message)

func _build_hub_forge_panel_text() -> String:
	var weapon_text: String = ""
	if Engine.has_singleton("PlayerWeaponData"):
		weapon_text = ""
	# PlayerWeaponData is an autoload in the project; direct call is kept for the current hub workflow.
	weapon_text = PlayerWeaponData.build_weapon_panel_text()
	return "HUB FORGE\n\n%s\n\nDemo note:\nRun-only forge marks are functional inside the descent. Permanent forge progression is reserved for later roadmap work." % weapon_text

func _build_codex_panel_text() -> String:
	return "CODEX LECTERN\n\nRecords are not implemented yet.\n\nPlanned demo entries:\n- Ash Grunt\n- Cinder Lunger\n- Ember Spitter\n- Chainbound Penitent\n- Furnace Imp\n- Bell Wretch\n- The Ash Warden\n- Circle 0 hazards\n\nThis station is intentionally a placeholder until the save/progression layer can record discoveries."

func _show_panel(title: String, body: String, footer: String = "Press E or Esc to close.") -> void:
	if interaction_panel == null:
		_setup_interaction_panel()

	interaction_panel.show_panel(title, body, footer)
	_panel_close_armed = false
	if _open_panel_kind != "upgrade_altar":
		_open_panel_kind = ""
	status_text = title + " opened."

func _spawn_or_reset_training_dummy() -> void:
	var marker: Node2D = _find_marker("TrainingDummyMarker")
	var spawn_pos: Vector2 = Vector2(480.0, 620.0)
	if marker != null:
		spawn_pos = marker.global_position

	if training_dummy != null and is_instance_valid(training_dummy):
		training_dummy.reset_dummy()
		training_dummy.global_position = spawn_pos
		print("[IsoHubRuntime] Training dummy reset.")
		return

	training_dummy = TRAINING_DUMMY_SCRIPT.new()
	training_dummy.name = "HubTrainingDummy"
	training_dummy.max_health = training_dummy_health
	training_dummy.display_name = "Training Dummy"
	_get_y_sorted_root().add_child(training_dummy)
	training_dummy.global_position = spawn_pos
	print("[IsoHubRuntime] Training dummy spawned.")

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

func _audio_event(event_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	var pos: Vector2 = player_node.global_position if player_node != null and is_instance_valid(player_node) else Vector2.ZERO
	INFERNAL_AUDIO_SCRIPT.play_event_from_node(self, event_name, pos)

func _audio_context(context_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	INFERNAL_AUDIO_SCRIPT.set_context_from_node(self, context_name)

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HubHUD"
	add_child(hud_layer)

	hud_label = Label.new()
	hud_label.name = "HubStatusLabel"
	hud_label.position = Vector2(18.0, 18.0)
	hud_label.size = Vector2(780.0, 120.0)
	hud_label.add_theme_font_size_override("font_size", 16)
	hud_label.add_theme_color_override("font_color", Color("#ead8b8"))
	hud_layer.add_child(hud_label)

func _update_hud() -> void:
	if hud_label == null:
		return

	var last_run_line: String = "No recorded run result yet."
	if RunSessionData.has_last_run():
		last_run_line = "Last run saved. Visit Memory Pool."
	hud_label.text = "THRESHOLD NAVE\n%s\n%s\n%s\n%s" % [
		status_text,
		RunEconomyData.get_currency_summary_line() + " | Save: " + ("OK" if SaveGameData.has_save_file() else "new"),
		PERMANENT_UPGRADE_SCRIPT.build_summary_line(),
		last_run_line
	]

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
