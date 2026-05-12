extends Node2D
## R0.5D — Godot-native isometric room loader.
## Uses TileMapLayer for floor cells and a y-sorted Node2D layer for actors/props/sockets.
## This is the correct direction for production integration; the older polygon-only loader is now a preview/debug tool.

@export_file("*.json") var runtime_room_path: String = "res://data/rooms/circle0/tilemap/ash_intake_hall_iso.room.tilemap.runtime.json"
@export var room_origin: Vector2 = Vector2(640.0, 360.0)
@export var show_help_overlay: bool = true
@export var show_debug_labels: bool = false
@export var show_socket_markers: bool = true
@export var show_prop_markers: bool = true
@export var show_internal_hud: bool = true

const TILE_SIZE: Vector2i = Vector2i(96, 48)
const TILESET_SOURCE_ID: int = 0
const ATLAS_FLOOR: Vector2i = Vector2i(0, 0)
const ATLAS_CRACKED_FLOOR: Vector2i = Vector2i(1, 0)
const ATLAS_HAZARD: Vector2i = Vector2i(2, 0)
const ATLAS_GATE: Vector2i = Vector2i(3, 0)
const DEBUG_TILESET_PATH: String = "res://art/iso/room_kits/circle0/debug_tiles/circle0_iso_debug_tiles.png"

const ROOM_PATHS: Array[String] = [
	"res://data/rooms/circle0/tilemap/ash_intake_hall_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/cinder_drain_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/furnace_vestibule_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/chain_reservoir_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/ember_sorting_floor_iso.room.tilemap.runtime.json",
	"res://data/rooms/circle0/tilemap/penitent_crossing_iso.room.tilemap.runtime.json",
]

var _room: Dictionary = {}
var _room_index: int = 0
var _status_text: String = ""
var _floor_layer: TileMapLayer
var _hazard_layer: TileMapLayer
var _gate_layer: TileMapLayer
var _world_sort: Node2D
var _label_layer: Node2D
var _hud_layer: CanvasLayer
var _hud_label: Label

func _ready() -> void:
	_build_node_tree()
	_load_room(runtime_room_path)
	set_process_unhandled_input(true)

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
					_load_room(runtime_room_path)
				KEY_H:
					show_help_overlay = not show_help_overlay
					_update_hud()
				KEY_L:
					show_debug_labels = not show_debug_labels
					_rebuild_world_layer()
				KEY_M:
					show_socket_markers = not show_socket_markers
					_rebuild_world_layer()

func _build_node_tree() -> void:
	_floor_layer = TileMapLayer.new()
	_floor_layer.name = "FloorTileMapLayer"
	_floor_layer.position = room_origin
	_floor_layer.y_sort_enabled = true
	_floor_layer.tile_set = _build_debug_tileset()
	add_child(_floor_layer)

	_hazard_layer = TileMapLayer.new()
	_hazard_layer.name = "HazardTileMapLayer"
	_hazard_layer.position = room_origin
	_hazard_layer.y_sort_enabled = true
	_hazard_layer.tile_set = _floor_layer.tile_set
	_hazard_layer.z_index = 4
	add_child(_hazard_layer)

	_gate_layer = TileMapLayer.new()
	_gate_layer.name = "GateTileMapLayer"
	_gate_layer.position = room_origin
	_gate_layer.y_sort_enabled = true
	_gate_layer.tile_set = _floor_layer.tile_set
	_gate_layer.z_index = 5
	add_child(_gate_layer)

	_world_sort = Node2D.new()
	_world_sort.name = "YSortedWorldObjects"
	_world_sort.y_sort_enabled = true
	_world_sort.z_index = 10
	add_child(_world_sort)

	_label_layer = Node2D.new()
	_label_layer.name = "OptionalDebugLabels"
	_label_layer.z_index = 100
	add_child(_label_layer)

	if show_internal_hud:
		_hud_layer = CanvasLayer.new()
		_hud_layer.name = "RoomLoaderHUD"
		add_child(_hud_layer)
		_hud_label = Label.new()
		_hud_label.position = Vector2(24.0, 20.0)
		_hud_label.add_theme_font_size_override("font_size", 14)
		_hud_layer.add_child(_hud_label)

func _build_debug_tileset() -> TileSet:
	var image: Image = Image.new()
	var error_code: int = image.load(DEBUG_TILESET_PATH)
	if error_code != OK:
		push_error("Missing debug isometric tile sheet: %s" % DEBUG_TILESET_PATH)
		return TileSet.new()

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(ATLAS_FLOOR)
	source.create_tile(ATLAS_CRACKED_FLOOR)
	source.create_tile(ATLAS_HAZARD)
	source.create_tile(ATLAS_GATE)

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = TILE_SIZE
	tile_set.uv_clipping = true
	tile_set.add_source(source, TILESET_SOURCE_ID)
	return tile_set

func _load_room_index(index: int) -> void:
	if index < 0 or index >= ROOM_PATHS.size():
		return
	_room_index = index
	runtime_room_path = ROOM_PATHS[index]
	_load_room(runtime_room_path)

func _load_room(path: String) -> void:
	_room = {}
	_status_text = ""
	_clear_room_layers()
	if not FileAccess.file_exists(path):
		_status_text = "Missing room runtime JSON: %s" % path
		push_warning(_status_text)
		_update_hud()
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_status_text = "Failed to parse room JSON: %s" % path
		push_warning(_status_text)
		_update_hud()
		return
	_room = parsed
	_status_text = "Loaded %s" % String(_room.get("display_name", path))
	_apply_tile_layers()
	_rebuild_world_layer()
	_update_hud()

func _clear_room_layers() -> void:
	_floor_layer.clear()
	_hazard_layer.clear()
	_gate_layer.clear()
	_clear_children(_world_sort)
	_clear_children(_label_layer)

func _clear_children(node: Node) -> void:
	var children: Array[Node] = node.get_children()
	for child: Node in children:
		child.queue_free()

func _apply_tile_layers() -> void:
	var tile_layers: Dictionary = _room.get("tile_layers", {})
	var floor_cells: Array = tile_layers.get("floor", [])
	for cell_value in floor_cells:
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell: Dictionary = cell_value
		var coords: Vector2i = Vector2i(int(cell.get("x", 0)), int(cell.get("y", 0)))
		var atlas: Vector2i = ATLAS_FLOOR
		var tile_name: String = String(cell.get("tile", "floor"))
		if tile_name == "cracked_floor":
			atlas = ATLAS_CRACKED_FLOOR
		_floor_layer.set_cell(coords, TILESET_SOURCE_ID, atlas, 0)

	var hazard_sockets: Array = _room.get("hazard_sockets", [])
	for hazard_value in hazard_sockets:
		if typeof(hazard_value) != TYPE_DICTIONARY:
			continue
		var hazard: Dictionary = hazard_value
		var hazard_coords: Vector2i = _map_coords_from_dict(hazard)
		_hazard_layer.set_cell(hazard_coords, TILESET_SOURCE_ID, ATLAS_HAZARD, 0)

	var gate_sockets: Array = _room.get("gate_sockets", [])
	for gate_value in gate_sockets:
		if typeof(gate_value) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = gate_value
		var gate_coords: Vector2i = _map_coords_from_dict(gate)
		_gate_layer.set_cell(gate_coords, TILESET_SOURCE_ID, ATLAS_GATE, 0)

	_floor_layer.update_internals()
	_hazard_layer.update_internals()
	_gate_layer.update_internals()

func _rebuild_world_layer() -> void:
	_clear_children(_world_sort)
	_clear_children(_label_layer)
	if _room.is_empty():
		return
	if show_prop_markers:
		_add_dressing_markers()
	if show_socket_markers:
		_add_player_spawn_marker()
		_add_enemy_spawn_markers()
		_add_hazard_markers()
		_add_gate_markers()
	if show_debug_labels:
		_add_debug_labels()

func _add_dressing_markers() -> void:
	var zones: Dictionary = _room.get("dressing_zones", {})
	var floor_props: Array = zones.get("floor_props", [])
	for prop_value in floor_props:
		if typeof(prop_value) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = prop_value
		var pos: Vector2 = _screen_pos_from_dict(prop)
		_create_marker(_world_sort, pos, Color(0.37, 0.25, 0.14, 0.75), 18.0, "diamond")
	var wall_props: Array = zones.get("wall_props", [])
	for wall_value in wall_props:
		if typeof(wall_value) != TYPE_DICTIONARY:
			continue
		var wall_prop: Dictionary = wall_value
		var wpos: Vector2 = _screen_pos_from_dict(wall_prop)
		_create_marker(_world_sort, wpos + Vector2(0.0, -30.0), Color(0.14, 0.11, 0.08, 0.88), 28.0, "pillar")

func _add_player_spawn_marker() -> void:
	var spawn: Dictionary = _room.get("player_spawn", {})
	var pos: Vector2 = _screen_pos_from_dict(spawn)
	_create_marker(_world_sort, pos, Color(0.10, 0.62, 0.92, 0.88), 22.0, "circle")

func _add_enemy_spawn_markers() -> void:
	var enemies: Array = _room.get("enemy_spawns", [])
	for enemy_value in enemies:
		if typeof(enemy_value) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_value
		var pos: Vector2 = _screen_pos_from_dict(enemy)
		_create_marker(_world_sort, pos, Color(0.90, 0.24, 0.16, 0.82), 18.0, "cross")

func _add_hazard_markers() -> void:
	var hazards: Array = _room.get("hazard_sockets", [])
	for hazard_value in hazards:
		if typeof(hazard_value) != TYPE_DICTIONARY:
			continue
		var hazard: Dictionary = hazard_value
		var pos: Vector2 = _screen_pos_from_dict(hazard)
		_create_marker(_world_sort, pos, Color(1.0, 0.58, 0.12, 0.68), 30.0, "ring")

func _add_gate_markers() -> void:
	var gates: Array = _room.get("gate_sockets", [])
	for gate_value in gates:
		if typeof(gate_value) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = gate_value
		var pos: Vector2 = _screen_pos_from_dict(gate)
		_create_marker(_world_sort, pos + Vector2(0.0, -32.0), Color(0.92, 0.68, 0.26, 0.86), 26.0, "gate")

func _add_debug_labels() -> void:
	_add_label(Vector2(28.0, 58.0), String(_room.get("template", "iso_room")), Color(0.72, 0.68, 0.58), 13, _label_layer)
	var gates: Array = _room.get("gate_sockets", [])
	for gate_value in gates:
		if typeof(gate_value) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = gate_value
		_add_label(_screen_pos_from_dict(gate) + Vector2(-40.0, -82.0), String(gate.get("label", "GATE")), Color(0.95, 0.80, 0.42), 12, _label_layer)
	var enemies: Array = _room.get("enemy_spawns", [])
	for enemy_value in enemies:
		if typeof(enemy_value) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_value
		_add_label(_screen_pos_from_dict(enemy) + Vector2(-38.0, 22.0), String(enemy.get("role", "enemy")), Color(1.0, 0.42, 0.30), 10, _label_layer)

func _create_marker(parent: Node, pos: Vector2, color: Color, radius: float, marker_type: String) -> void:
	var marker: Node2D = Node2D.new()
	marker.position = pos
	parent.add_child(marker)
	var poly: Polygon2D = Polygon2D.new()
	poly.color = color
	match marker_type:
		"circle":
			poly.polygon = _regular_polygon(radius, 18)
		"ring":
			poly.polygon = _regular_polygon(radius, 24)
		"cross":
			poly.polygon = PackedVector2Array([Vector2(-radius, -4.0), Vector2(-4.0, -4.0), Vector2(-4.0, -radius), Vector2(4.0, -radius), Vector2(4.0, -4.0), Vector2(radius, -4.0), Vector2(radius, 4.0), Vector2(4.0, 4.0), Vector2(4.0, radius), Vector2(-4.0, radius), Vector2(-4.0, 4.0), Vector2(-radius, 4.0)])
		"pillar":
			poly.polygon = PackedVector2Array([Vector2(-radius * 0.55, -radius), Vector2(radius * 0.55, -radius), Vector2(radius * 0.70, radius * 0.9), Vector2(-radius * 0.70, radius * 0.9)])
		"gate":
			poly.polygon = PackedVector2Array([Vector2(-radius * 0.75, -radius), Vector2(radius * 0.75, -radius), Vector2(radius * 0.75, radius), Vector2(-radius * 0.75, radius)])
		_:
			poly.polygon = PackedVector2Array([Vector2(0.0, -radius), Vector2(radius, 0.0), Vector2(0.0, radius), Vector2(-radius, 0.0)])
	marker.add_child(poly)

func _regular_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(sides):
		var angle: float = (TAU * float(i)) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _screen_pos_from_dict(data: Dictionary) -> Vector2:
	var coords: Vector2i = _map_coords_from_dict(data)
	return room_origin + _floor_layer.map_to_local(coords)

func _map_coords_from_dict(data: Dictionary) -> Vector2i:
	return Vector2i(int(data.get("map_x", 0)), int(data.get("map_y", 0)))

func _add_label(pos: Vector2, text: String, color: Color, font_size: int, parent: Node) -> void:
	var label: Label = Label.new()
	label.position = pos
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _update_hud() -> void:
	if _hud_label == null:
		return
	var room_name: String = String(_room.get("display_name", "No Room"))
	var cell_count: int = 0
	if not _room.is_empty():
		var tile_layers: Dictionary = _room.get("tile_layers", {})
		cell_count = int(tile_layers.get("floor", []).size())
	var lines: Array[String] = []
	lines.append("R0.5D Godot TileMapLayer Room Loader")
	lines.append("Room: %s" % room_name)
	lines.append("Floor cells: %d" % cell_count)
	lines.append("Status: %s" % _status_text)
	if show_help_overlay:
		lines.append("1–6 switch rooms · R reload · H help · L labels · M markers")
	_hud_label.text = "\n".join(lines)

func _draw() -> void:
	# Root draws only a neutral backing plate. TileMapLayer draws the actual isometric floor.
	var rect_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.105, 0.095, 0.085, 1.0), true)
	if _room.is_empty():
		return
	_draw_back_wall_hint()

func _draw_back_wall_hint() -> void:
	var poly_value: Variant = _room.get("iso_floor_polygon", [])
	if typeof(poly_value) != TYPE_ARRAY:
		return
	var poly_array: Array = poly_value
	if poly_array.size() < 3:
		return
	var points: Array[Vector2] = []
	for point_value in poly_array:
		if typeof(point_value) != TYPE_ARRAY:
			continue
		var point_array: Array = point_value
		if point_array.size() < 2:
			continue
		points.append(_logical_world_to_screen(Vector2(float(point_array[0]), float(point_array[1]))))
	if points.size() < 3:
		return
	var min_y: float = 999999.0
	for point: Vector2 in points:
		min_y = min(min_y, point.y)
	var wall_rect: Rect2 = Rect2(Vector2(room_origin.x - 430.0, min_y - 78.0), Vector2(860.0, 86.0))
	draw_rect(wall_rect, Color(0.08, 0.07, 0.06, 0.72), true)
	draw_rect(wall_rect, Color(0.44, 0.29, 0.14, 0.50), false, 2.0)

func _logical_world_to_screen(p: Vector2) -> Vector2:
	var mx: float = (p.y / (float(TILE_SIZE.y) * 0.5) + p.x / (float(TILE_SIZE.x) * 0.5)) * 0.5
	var my: float = (p.y / (float(TILE_SIZE.y) * 0.5) - p.x / (float(TILE_SIZE.x) * 0.5)) * 0.5
	return room_origin + _floor_layer.map_to_local(Vector2i(int(round(mx)), int(round(my))))
