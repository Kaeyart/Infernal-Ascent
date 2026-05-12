extends Node2D

class_name RunRoomInteractable

signal activated(payload: Dictionary)
signal focus_changed(payload: Dictionary, focused: bool)

@export var interact_radius: float = 62.0
@export var debug_draw_radius: bool = false

var payload: Dictionary = {}
var _time: float = 0.0
var _player_in_range: bool = false
var _was_in_range: bool = false
var _input_armed: bool = false
var _used: bool = false

func setup(data: Dictionary, spawn_position: Vector2) -> void:
	payload = data.duplicate(true)
	global_position = spawn_position
	z_index = 44
	z_as_relative = false
	name = "RunRoomInteractable_%s" % str(payload.get("kind", "object"))
	_input_armed = not _is_interact_down()
	queue_redraw()

func _exit_tree() -> void:
	if _player_in_range:
		emit_signal("focus_changed", payload, false)

func _process(delta: float) -> void:
	_time += delta
	_update_player_range()
	_update_interaction()
	queue_redraw()

func _update_player_range() -> void:
	var player: Node2D = _find_player()
	_was_in_range = _player_in_range
	if player == null:
		_player_in_range = false
	else:
		_player_in_range = global_position.distance_to(player.global_position) <= interact_radius
	if _player_in_range != _was_in_range:
		emit_signal("focus_changed", payload, _player_in_range and not _used)

func _update_interaction() -> void:
	if _used:
		return
	var interact_down: bool = _is_interact_down()
	if not interact_down:
		_input_armed = true
	if _player_in_range and _input_armed and _interact_pressed_once():
		_used = true
		_input_armed = false
		emit_signal("focus_changed", payload, false)
		emit_signal("activated", payload)

func mark_used() -> void:
	_used = true
	emit_signal("focus_changed", payload, false)
	queue_redraw()

func _find_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node: Node in players:
		if node is Node2D:
			return node as Node2D
	return null

func _is_interact_down() -> bool:
	if InputMap.has_action("interact") and Input.is_action_pressed("interact"):
		return true
	return Input.is_physical_key_pressed(KEY_E)

func _interact_pressed_once() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true
	return Input.is_physical_key_pressed(KEY_E)

func _draw() -> void:
	var kind: String = str(payload.get("kind", "reward"))
	var title: String = str(payload.get("display_name", "Interact"))
	var base_color: Color = _color_for_kind(kind)
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.1)
	if _used:
		base_color = Color(0.34, 0.34, 0.34, 0.80)
	_draw_shadow()
	_draw_object(kind, base_color, pulse)
	_draw_prompt(title, base_color)
	if debug_draw_radius:
		draw_arc(Vector2.ZERO, interact_radius, 0.0, TAU, 48, Color(0.3, 0.8, 1.0, 0.65), 1.0)

func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var angle: float = TAU * float(i) / 28.0
		points.append(Vector2(cos(angle) * 48.0, sin(angle) * 14.0 + 11.0))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.34))

func _draw_object(kind: String, base_color: Color, pulse: float) -> void:
	match kind:
		"boss_antechamber":
			_draw_sealed_gate(base_color, pulse)
		"fountain":
			_draw_fountain(base_color, pulse)
		"forge", "forge_mark":
			_draw_forge(base_color, pulse)
		"shop", "shop_item":
			_draw_shop(base_color, pulse)
		_:
			_draw_reward(base_color, pulse)

func _draw_reward(base_color: Color, pulse: float) -> void:
	draw_circle(Vector2(0.0, -34.0), 30.0 + pulse * 4.0, Color(base_color.r, base_color.g, base_color.b, 0.20 + pulse * 0.12))
	draw_rect(Rect2(Vector2(-20.0, -58.0), Vector2(40.0, 40.0)), Color(0.045, 0.035, 0.026, 0.96), true)
	draw_rect(Rect2(Vector2(-20.0, -58.0), Vector2(40.0, 40.0)), base_color, false, 2.0)
	draw_line(Vector2(0.0, -55.0), Vector2(0.0, -21.0), Color(1.0, 0.92, 0.62, 0.95), 2.0)
	draw_line(Vector2(-15.0, -38.0), Vector2(15.0, -38.0), Color(1.0, 0.92, 0.62, 0.95), 2.0)

func _draw_fountain(base_color: Color, pulse: float) -> void:
	draw_rect(Rect2(Vector2(-38.0, -31.0), Vector2(76.0, 30.0)), Color(0.06, 0.08, 0.11, 0.96), true)
	draw_rect(Rect2(Vector2(-38.0, -31.0), Vector2(76.0, 30.0)), base_color, false, 2.0)
	draw_arc(Vector2(0.0, -38.0), 26.0 + pulse * 4.0, deg_to_rad(200.0), deg_to_rad(340.0), 20, Color(0.65, 0.88, 1.0, 0.88), 2.5)
	draw_circle(Vector2(0.0, -25.0), 10.0, Color(0.55, 0.82, 1.0, 0.80))

func _draw_forge(base_color: Color, pulse: float) -> void:
	draw_rect(Rect2(Vector2(-36.0, -42.0), Vector2(72.0, 40.0)), Color(0.10, 0.055, 0.032, 0.96), true)
	draw_rect(Rect2(Vector2(-36.0, -42.0), Vector2(72.0, 40.0)), base_color, false, 2.0)
	draw_line(Vector2(-22.0, -16.0), Vector2(22.0, -16.0), Color(0.86, 0.78, 0.65, 1.0), 4.0)
	draw_circle(Vector2(0.0, -28.0), 8.0 + pulse * 2.0, Color(1.0, 0.35, 0.10, 0.34))

func _draw_shop(base_color: Color, pulse: float) -> void:
	draw_rect(Rect2(Vector2(-32.0, -52.0), Vector2(64.0, 48.0)), Color(0.06, 0.045, 0.08, 0.96), true)
	draw_rect(Rect2(Vector2(-32.0, -52.0), Vector2(64.0, 48.0)), base_color, false, 2.0)
	draw_circle(Vector2(0.0, -31.0), 12.0 + pulse * 2.0, Color(0.76, 0.48, 1.0, 0.48))
	draw_string(ThemeDB.fallback_font, Vector2(-18.0, -15.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 18, Color(1.0, 0.86, 0.45, 1.0))

func _draw_sealed_gate(base_color: Color, pulse: float) -> void:
	# V22.2: boss placeholder is a physical sealed door inside the room, not a floating UI object.
	draw_circle(Vector2(0.0, -50.0), 40.0 + pulse * 4.0, Color(0.95, 0.74, 0.36, 0.12 + pulse * 0.08))
	draw_rect(Rect2(Vector2(-36.0, -92.0), Vector2(72.0, 84.0)), Color(0.035, 0.026, 0.018, 0.96), true)
	draw_rect(Rect2(Vector2(-36.0, -92.0), Vector2(72.0, 84.0)), Color(0.86, 0.70, 0.42, 0.90), false, 2.0)
	draw_line(Vector2(0.0, -86.0), Vector2(0.0, -16.0), Color(1.0, 0.86, 0.52, 0.95), 2.0)
	draw_line(Vector2(-22.0, -52.0), Vector2(22.0, -52.0), Color(1.0, 0.86, 0.52, 0.95), 2.0)
	draw_arc(Vector2(0.0, -92.0), 36.0, PI, TAU, 24, Color(0.86, 0.70, 0.42, 0.76), 2.0)

func _draw_prompt(title: String, base_color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var kind: String = str(payload.get("kind", "object"))
	if kind == "boss_antechamber":
		_draw_boss_gate_name(title, base_color)
		return
	var has_meta: bool = kind == "reward" or kind == "forge_mark" or kind == "shop_item"
	var rect: Rect2 = Rect2(Vector2(-112.0, 30.0), Vector2(224.0, 58.0 if has_meta else 46.0))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.88), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.82), false, 1.5)
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 16.0), title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color(1.0, 0.90, 0.68, 1.0))
	if has_meta:
		var meta: String = "%s · %s" % [str(payload.get("rarity", "common")).to_upper(), str(payload.get("category", "Boon")).to_upper()]
		if kind == "shop_item":
			meta = "COST %d RUN ASH" % int(payload.get("cost", 0))
		draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 34.0), meta, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 10, Color(0.80, 0.72, 0.58, 0.96))
	var prompt: String = _prompt_text_for_kind(kind)
	if _used:
		prompt = "USED"
	elif not _player_in_range:
		prompt = "APPROACH"
	var prompt_y: float = rect.position.y + (52.0 if has_meta else 38.0)
	draw_string(font, Vector2(rect.position.x + 8.0, prompt_y), prompt, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color(0.72, 0.94, 1.0, 1.0 if _player_in_range else 0.68))

func _draw_boss_gate_name(title: String, base_color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var rect: Rect2 = Rect2(Vector2(-116.0, -136.0), Vector2(232.0, 30.0))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.84), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.78), false, 1.4)
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 20.0), title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color(1.0, 0.90, 0.68, 1.0))
	if _player_in_range and not _used:
		var prompt_rect: Rect2 = Rect2(Vector2(-74.0, 10.0), Vector2(148.0, 24.0))
		draw_rect(prompt_rect, Color(0.018, 0.013, 0.010, 0.82), true)
		draw_rect(prompt_rect, Color(base_color.r, base_color.g, base_color.b, 0.72), false, 1.2)
		draw_string(font, Vector2(prompt_rect.position.x + 6.0, prompt_rect.position.y + 17.0), "[E] APPROACH", HORIZONTAL_ALIGNMENT_CENTER, prompt_rect.size.x - 12.0, 10, Color(0.72, 0.94, 1.0, 1.0))

func _prompt_text_for_kind(kind: String) -> String:
	match kind:
		"boss_antechamber":
			return "[E] APPROACH"
		"reward":
			return "[E] CLAIM"
		"fountain":
			return "[E] DRINK"
		"forge":
			return "[E] INSPECT"
		"forge_mark":
			return "[E] FORGE"
		"shop":
			return "[E] INSPECT"
		"shop_item":
			return "[E] BUY"
	return "[E] USE"

func _color_for_kind(kind: String) -> Color:
	match kind:
		"boss_antechamber":
			return Color(0.86, 0.70, 0.42, 1.0)
		"reward":
			return _color_for_reward_category(str(payload.get("category", "Utility")))
		"fountain":
			return Color(0.28, 0.62, 0.86, 1.0)
		"forge", "forge_mark":
			return Color(0.90, 0.36, 0.12, 1.0)
		"shop", "shop_item":
			return Color(0.62, 0.36, 0.86, 1.0)
	return Color(0.78, 0.72, 0.62, 1.0)

func _color_for_reward_category(category: String) -> Color:
	match category.to_lower():
		"damage":
			return Color(0.86, 0.36, 0.20, 1.0)
		"defense":
			return Color(0.42, 0.68, 0.88, 1.0)
		"mobility":
			return Color(0.55, 0.78, 0.34, 1.0)
		"utility":
			return Color(0.82, 0.66, 0.28, 1.0)
		"special":
			return Color(0.72, 0.42, 0.90, 1.0)
	return Color(0.52, 0.72, 0.34, 1.0)
