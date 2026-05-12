extends Node2D

class_name RunChoiceGate

signal gate_chosen(choice_data: Dictionary)
signal gate_focus_changed(choice_data: Dictionary, focused: bool)

@export var interact_radius: float = 82.0
@export var gate_width: float = 86.0
@export var gate_height: float = 112.0
@export var pulse_speed: float = 2.0
@export var debug_draw_radius: bool = false
@export var show_world_gate_label: bool = true
@export var show_focus_prompt: bool = true

var choice_data: Dictionary = {}
var _time: float = 0.0
var _player_in_range: bool = false
var _was_in_range: bool = false
var _input_armed: bool = false
var _activated: bool = false

func setup(data: Dictionary, spawn_position: Vector2) -> void:
	choice_data = data.duplicate(true)
	global_position = spawn_position
	name = "RunChoiceGate_%s" % str(choice_data.get("room_type", "unknown"))
	z_index = 42
	z_as_relative = false
	_input_armed = not _is_interact_down()
	queue_redraw()

func _exit_tree() -> void:
	if _player_in_range:
		emit_signal("gate_focus_changed", choice_data, false)

func _process(delta: float) -> void:
	_time += delta
	if _activated:
		queue_redraw()
		return
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
		emit_signal("gate_focus_changed", choice_data, _player_in_range)

func _update_interaction() -> void:
	var interact_down: bool = _is_interact_down()
	if not interact_down:
		_input_armed = true
	if _player_in_range and _input_armed and _interact_pressed_once():
		_activated = true
		_input_armed = false
		emit_signal("gate_chosen", choice_data)

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
	var room_type: String = str(choice_data.get("room_type", "combat"))
	var display_name: String = str(choice_data.get("display_name", room_type.capitalize()))
	var icon: String = str(choice_data.get("icon", "?"))
	var base_color: Color = _color_for_room_type(room_type)
	var pulse: float = 0.5 + 0.5 * sin(_time * pulse_speed)
	if _activated:
		base_color = Color(0.34, 0.34, 0.34, 0.85)
	_draw_shadow()
	_draw_portal(base_color, pulse)
	if show_world_gate_label:
		_draw_minimal_label(display_name, icon, base_color, pulse)
	elif show_focus_prompt and _player_in_range:
		_draw_focus_prompt(base_color, pulse)
	if debug_draw_radius:
		draw_arc(Vector2.ZERO, interact_radius, 0.0, TAU, 64, Color(0.3, 0.8, 1.0, 0.65), 1.0)

func _draw_shadow() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(36):
		var a: float = TAU * float(i) / 36.0
		pts.append(Vector2(cos(a) * 76.0, sin(a) * 22.0 + 8.0))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.40))

func _draw_portal(base_color: Color, pulse: float) -> void:
	var portal_top: Vector2 = Vector2(0.0, -gate_height * 0.48)
	var glow_alpha: float = 0.07 + pulse * 0.08
	draw_rect(Rect2(Vector2(-gate_width * 0.42, -gate_height * 0.82), Vector2(gate_width * 0.84, gate_height * 0.78)), Color(base_color.r, base_color.g, base_color.b, glow_alpha), true)
	draw_arc(portal_top, gate_width * 0.50, PI, TAU, 44, Color(base_color.r, base_color.g, base_color.b, 0.82), 3.0)
	draw_line(Vector2(-gate_width * 0.50, portal_top.y), Vector2(-gate_width * 0.50, 0.0), Color(base_color.r, base_color.g, base_color.b, 0.82), 3.0)
	draw_line(Vector2(gate_width * 0.50, portal_top.y), Vector2(gate_width * 0.50, 0.0), Color(base_color.r, base_color.g, base_color.b, 0.82), 3.0)
	draw_arc(portal_top, gate_width * 0.62, PI, TAU, 44, Color(1.0, 0.82, 0.36, 0.30 if _player_in_range else 0.12), 1.5)
	if _player_in_range:
		draw_arc(portal_top, gate_width * 0.72, PI, TAU, 44, Color(1.0, 0.80, 0.28, 0.26 + pulse * 0.10), 2.0)

func _draw_focus_prompt(base_color: Color, pulse: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var rect: Rect2 = Rect2(Vector2(-42.0, 20.0), Vector2(84.0, 24.0))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.82), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.70 + pulse * 0.15), false, 1.4)
	draw_string(font, Vector2(rect.position.x + 6.0, rect.position.y + 17.0), "[E] ENTER", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 11, Color(0.86, 0.94, 1.0, 1.0))

func _draw_minimal_label(display_name: String, icon: String, base_color: Color, pulse: float) -> void:
	# V22.2: keep the door name above the door, but do not turn the world-space gate into a second UI card.
	var font: Font = ThemeDB.fallback_font
	var clean_name: String = display_name.to_upper()
	var rect: Rect2 = Rect2(Vector2(-68.0, -142.0), Vector2(136.0, 24.0))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.82), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.62 + pulse * 0.12), false, 1.25)
	draw_string(font, Vector2(rect.position.x + 6.0, rect.position.y + 17.0), clean_name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 10, Color(1.0, 0.88, 0.64, 0.96))
	if show_focus_prompt and _player_in_range:
		_draw_focus_prompt(base_color, pulse)

func _color_for_room_type(room_type: String) -> Color:
	match room_type:
		"combat":
			return Color(0.80, 0.30, 0.12, 1.0)
		"elite_combat":
			return Color(0.90, 0.12, 0.10, 1.0)
		"reward":
			return Color(0.50, 0.72, 0.32, 1.0)
		"fountain":
			return Color(0.26, 0.62, 0.86, 1.0)
		"forge":
			return Color(0.92, 0.38, 0.12, 1.0)
		"shop":
			return Color(0.62, 0.36, 0.86, 1.0)
	return Color(0.78, 0.72, 0.62, 1.0)
