extends Node2D
## R0.5E — generated isometric room playable test.
## Loads one generated TileMapLayer room and spawns the current player/enemy/hazard/gate runtime objects.
## This is intentionally isolated from the main run loop.

const ROOM_LOADER_SCRIPT: Script = preload("res://scripts/iso/room_pipeline/IsoGodotTileRoomLoader.gd")
const PLAYER_SCRIPT: Script = preload("res://scripts/iso/IsoPhysicsTestPlayer.gd")
const ENEMY_SCRIPT_PATH: String = "res://scripts/iso/IsoTestEnemy.gd"
const HAZARD_SCRIPT: Script = preload("res://scripts/iso/IsoRoomHazard.gd")
const GATE_SCRIPT: Script = preload("res://scripts/iso/RunChoiceGate.gd")

const ROOM_PATHS: Array[String] = [
	"res://data/rooms/circle0/tilemap/ash_intake_hall_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/cinder_drain_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/furnace_vestibule_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/chain_reservoir_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/ember_sorting_floor_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/penitent_crossing_iso.room.tilemap.runtime.json",
]

const TILE_SIZE: Vector2 = Vector2(96.0, 48.0)

@export var room_origin: Vector2 = Vector2(640.0, 365.0)
@export var starting_room_index: int = 0
@export var spawn_real_enemies: bool = true
@export var spawn_real_hazards: bool = true
@export var spawn_route_gates_after_clear: bool = true
@export var show_socket_markers: bool = false
@export var show_loader_help: bool = false
@export var camera_zoom: Vector2 = Vector2(0.88, 0.88)

var _room_index: int = 0
var _room: Dictionary = {}
var _room_loader: Node2D = null
var _gameplay_root: Node2D = null
var _player: Node2D = null
var _camera: Camera2D = null
var _hud_layer: CanvasLayer = null
var _hud_label: Label = null
var _room_clear: bool = false
var _status: String = "Initializing generated room test."
var _enemies_alive: int = 0

func _ready() -> void:
	_build_scene_nodes()
	_load_room_index(clampi(starting_room_index, 0, ROOM_PATHS.size() - 1))
	set_process_unhandled_input(true)

func _process(_delta: float) -> void:
	_update_room_clear_state()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			match key_event.keycode:
				KEY_1:
					_load_room_index(0)
				KEY_2:
					_load_room_index(1)
				KEY_3:
					_load_room_index(2)
				KEY_4:
					_load_room_index(3)
				KEY_5:
					_load_room_index(4)
				KEY_6:
					_load_room_index(5)
				KEY_R:
					_load_room_index(_room_index)
				KEY_G:
					_spawn_route_gates()
				KEY_K:
					_kill_all_enemies_for_test()
				KEY_M:
					show_socket_markers = not show_socket_markers
					_reload_visual_room_only()

func _build_scene_nodes() -> void:
	_gameplay_root = Node2D.new()
	_gameplay_root.name = "GeneratedRoomGameplay"
	_gameplay_root.y_sort_enabled = true
	_gameplay_root.z_index = 30
	add_child(_gameplay_root)

	_camera = Camera2D.new()
	_camera.name = "GeneratedRoomCamera"
	_camera.position = room_origin + Vector2(0.0, -10.0)
	_camera.zoom = camera_zoom
	_camera.enabled = true
	add_child(_camera)

	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "GeneratedRoomHUD"
	add_child(_hud_layer)
	_hud_label = Label.new()
	_hud_label.position = Vector2(22.0, 18.0)
	_hud_label.add_theme_font_size_override("font_size", 14)
	_hud_layer.add_child(_hud_label)

func _load_room_index(index: int) -> void:
	if index < 0 or index >= ROOM_PATHS.size():
		return
	_room_index = index
	_room_clear = false
	_enemies_alive = 0
	_load_room_data(ROOM_PATHS[_room_index])
	_rebuild_room_loader(ROOM_PATHS[_room_index])
	_rebuild_gameplay_layer()

func _load_room_data(path: String) -> void:
	_room.clear()
	if not FileAccess.file_exists(path):
		_status = "Missing runtime JSON: %s" % path
		push_warning(_status)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_status = "Invalid JSON room data: %s" % path
		push_warning(_status)
		return
	_room = parsed
	_status = "Loaded playable generated room: %s" % String(_room.get("display_name", path))

func _rebuild_room_loader(path: String) -> void:
	if _room_loader != null and is_instance_valid(_room_loader):
		_room_loader.queue_free()
	_room_loader = ROOM_LOADER_SCRIPT.new() as Node2D
	_room_loader.name = "GeneratedIsoTileRoomVisuals"
	_room_loader.set("runtime_room_path", path)
	_room_loader.set("room_origin", room_origin)
	_room_loader.set("show_internal_hud", false)
	_room_loader.set("show_help_overlay", show_loader_help)
	_room_loader.set("show_debug_labels", false)
	_room_loader.set("show_socket_markers", show_socket_markers)
	_room_loader.set("show_prop_markers", true)
	add_child(_room_loader)
	move_child(_room_loader, 0)

func _reload_visual_room_only() -> void:
	_rebuild_room_loader(ROOM_PATHS[_room_index])

func _rebuild_gameplay_layer() -> void:
	_clear_children(_gameplay_root)
	_spawn_player()
	if spawn_real_hazards:
		_spawn_hazards()
	if spawn_real_enemies:
		_spawn_enemies()
	_update_hud()

func _clear_children(node: Node) -> void:
	var children: Array = node.get_children()
	for child_value in children:
		var child: Node = child_value as Node
		if child != null:
			child.queue_free()

func _spawn_player() -> void:
	var spawn_data: Dictionary = _room.get("player_spawn", {})
	_player = PLAYER_SCRIPT.new() as Node2D
	if _player == null:
		_status = "Player script failed to instantiate."
		return
	_player.name = "GeneratedRoomPlayer"
	_player.global_position = _screen_pos_from_dict(spawn_data)
	_player.add_to_group("player")
	_gameplay_root.add_child(_player)

func _spawn_enemies() -> void:
	var enemy_spawns: Array = _room.get("enemy_spawns", [])
	for enemy_value in enemy_spawns:
		if typeof(enemy_value) != TYPE_DICTIONARY:
			continue
		var enemy_data: Dictionary = enemy_value
		var enemy_node: Node2D = (load(ENEMY_SCRIPT_PATH) as Script).new() as Node2D
		if enemy_node == null:
			continue
		enemy_node.name = "GeneratedRoomEnemy_%s" % String(enemy_data.get("role", "enemy"))
		enemy_node.global_position = _screen_pos_from_dict(enemy_data)
		enemy_node.set("enemy_type", _enemy_type_from_role(String(enemy_data.get("role", "ash_grunt"))))
		if enemy_node.has_signal("died"):
			enemy_node.connect("died", Callable(self, "_on_enemy_died"))
		_gameplay_root.add_child(enemy_node)
		_enemies_alive += 1

func _spawn_hazards() -> void:
	var hazard_spawns: Array = _room.get("hazard_sockets", [])
	for hazard_value in hazard_spawns:
		if typeof(hazard_value) != TYPE_DICTIONARY:
			continue
		var hazard_data: Dictionary = hazard_value
		var hazard_node: Node2D = HAZARD_SCRIPT.new() as Node2D
		if hazard_node == null:
			continue
		var setup_data: Dictionary = {
			"hazard_kind": String(hazard_data.get("type", "ash_vent")),
			"radius": float(hazard_data.get("radius", 52.0)),
			"damage": 1,
			"windup_duration": 1.55,
			"active_duration": 0.36,
			"cooldown_duration": 3.0,
			"debug_draw_radius": false,
			"draw_warning_label": true,
		}
		hazard_node.name = "GeneratedRoomHazard_%s" % String(setup_data.get("hazard_kind", "hazard"))
		_gameplay_root.add_child(hazard_node)
		if hazard_node.has_method("setup"):
			hazard_node.call("setup", setup_data, _screen_pos_from_dict(hazard_data))
		else:
			hazard_node.global_position = _screen_pos_from_dict(hazard_data)

func _spawn_route_gates() -> void:
	if not spawn_route_gates_after_clear:
		return
	# Remove old generated gates first.
	var children: Array = _gameplay_root.get_children()
	for child_value in children:
		var child: Node = child_value as Node
		if child != null and child.is_in_group("generated_room_gate"):
			child.queue_free()
	var gate_spawns: Array = _room.get("gate_sockets", [])
	for i in range(gate_spawns.size()):
		var gate_value: Variant = gate_spawns[i]
		if typeof(gate_value) != TYPE_DICTIONARY:
			continue
		var gate_data: Dictionary = gate_value
		var gate_node: Node2D = GATE_SCRIPT.new() as Node2D
		if gate_node == null:
			continue
		var choice: Dictionary = _choice_data_for_gate(gate_data, i)
		gate_node.name = "GeneratedRoomGate_%s" % String(choice.get("room_type", "combat"))
		gate_node.add_to_group("generated_room_gate")
		gate_node.set("show_world_gate_label", true)
		gate_node.set("show_focus_prompt", true)
		_gameplay_root.add_child(gate_node)
		if gate_node.has_signal("gate_chosen"):
			gate_node.connect("gate_chosen", Callable(self, "_on_gate_chosen"))
		if gate_node.has_method("setup"):
			gate_node.call("setup", choice, _screen_pos_from_dict(gate_data))
		else:
			gate_node.global_position = _screen_pos_from_dict(gate_data)

func _choice_data_for_gate(gate_data: Dictionary, index: int) -> Dictionary:
	var label: String = String(gate_data.get("label", "COMBAT"))
	var label_lower: String = label.to_lower()
	var room_type: String = "combat"
	if label_lower.find("reward") >= 0:
		room_type = "reward"
	elif label_lower.find("fountain") >= 0:
		room_type = "fountain"
	elif label_lower.find("shop") >= 0:
		room_type = "shop"
	elif label_lower.find("forge") >= 0:
		room_type = "forge"
	elif label_lower.find("elite") >= 0:
		room_type = "elite_combat"
	var next_index: int = (_room_index + index + 1) % ROOM_PATHS.size()
	return {
		"room_type": room_type,
		"display_name": label.capitalize(),
		"short_description": "Generated room test route.",
		"risk_label": "Test",
		"icon": _icon_for_room_type(room_type),
		"target_room_index": next_index,
	}

func _icon_for_room_type(room_type: String) -> String:
	match room_type:
		"reward":
			return "✦"
		"fountain":
			return "♒"
		"shop":
			return "$"
		"forge":
			return "⚒"
		"elite_combat":
			return "!"
	return "⚔"

func _enemy_type_from_role(role: String) -> String:
	match role:
		"cinder_lunger":
			return "cinder_lunger"
		"ember_spitter":
			return "ember_spitter"
		"chainbound_penitent":
			return "chainbound_penitent"
		"furnace_imp":
			return "furnace_imp"
		"bell_wretch":
			return "bell_wretch"
	return "ash_grunt"

func _on_enemy_died(_enemy: Node) -> void:
	_enemies_alive = maxi(0, _enemies_alive - 1)
	_update_room_clear_state()

func _update_room_clear_state() -> void:
	if _room_clear:
		return
	if _enemies_alive <= 0:
		var live_count: int = 0
		var enemies: Array = get_tree().get_nodes_in_group("iso_test_enemy")
		for node_value in enemies:
			var node: Node = node_value as Node
			if node != null and is_instance_valid(node) and node.is_inside_tree():
				live_count += 1
		if live_count <= 0:
			_room_clear = true
			_status = "Room clear. Route gates opened."
			_spawn_route_gates()

func _on_gate_chosen(choice: Dictionary) -> void:
	var target_index: int = int(choice.get("target_room_index", (_room_index + 1) % ROOM_PATHS.size()))
	_status = "Route chosen: %s" % String(choice.get("display_name", "Gate"))
	_load_room_index(clampi(target_index, 0, ROOM_PATHS.size() - 1))

func _kill_all_enemies_for_test() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("iso_test_enemy")
	for node_value in enemies:
		var node: Node = node_value as Node
		if node != null and is_instance_valid(node) and node.has_method("take_damage"):
			node.call("take_damage", 999)
	_enemies_alive = 0
	_update_room_clear_state()

func _screen_pos_from_dict(data: Dictionary) -> Vector2:
	var map_x: int = int(data.get("map_x", 0))
	var map_y: int = int(data.get("map_y", 0))
	return room_origin + _map_to_iso_screen(Vector2i(map_x, map_y))

func _map_to_iso_screen(cell: Vector2i) -> Vector2:
	var sx: float = float(cell.x - cell.y) * TILE_SIZE.x * 0.5
	var sy: float = float(cell.x + cell.y) * TILE_SIZE.y * 0.5
	return Vector2(sx, sy)

func _update_hud() -> void:
	if _hud_label == null:
		return
	var room_name: String = String(_room.get("display_name", "No Room"))
	var lines: Array[String] = []
	lines.append("R0.5E Generated Room Playable Test")
	lines.append("Room: %s" % room_name)
	lines.append("Status: %s" % _status)
	lines.append("Enemies alive: %d" % _enemies_alive)
	lines.append("1–6 switch rooms · R reload · K kill enemies · G force gates · M socket markers")
	_hud_label.text = "\n".join(lines)
