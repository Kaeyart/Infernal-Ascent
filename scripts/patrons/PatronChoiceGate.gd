extends Node2D
class_name PatronChoiceGate

signal choice_selected(choice_data: Dictionary)

var choice_data: Dictionary = {}
var interact_radius: float = 82.0
var prompt_visible: bool = false
var _e_down_previous: bool = false

func setup(p_choice_data: Dictionary) -> void:
	choice_data = p_choice_data.duplicate(true)
	queue_redraw()

func _process(_delta: float) -> void:
	prompt_visible = _is_player_in_range()
	if prompt_visible and _interact_pressed_once():
		emit_signal("choice_selected", choice_data.duplicate(true))
	queue_redraw()

func _draw() -> void:
	var color: Color = _get_choice_color()
	var font: Font = ThemeDB.fallback_font
	var diamond: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -46.0),
		Vector2(86.0, 0.0),
		Vector2(0.0, 46.0),
		Vector2(-86.0, 0.0)
	])
	draw_colored_polygon(diamond, Color(0.045, 0.035, 0.035, 0.92))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 3.0)
	draw_circle(Vector2(0.0, -6.0), 18.0, Color(color.r, color.g, color.b, 0.22))
	draw_arc(Vector2(0.0, -6.0), 25.0, 0.0, TAU, 48, color, 2.0)
	var title: String = str(choice_data.get("display_name", "Gate"))
	var subtitle: String = str(choice_data.get("subtitle", "Next room"))
	draw_string(font, Vector2(-92.0, 68.0), title, HORIZONTAL_ALIGNMENT_CENTER, 184.0, 18, color)
	draw_string(font, Vector2(-100.0, 92.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 13, Color("#d6c5aa"))
	if bool(choice_data.get("is_new_patron", false)):
		draw_string(font, Vector2(-86.0, -64.0), "NEW PATRON", HORIZONTAL_ALIGNMENT_CENTER, 172.0, 12, Color("#ffffff"))
	if prompt_visible:
		draw_string(font, Vector2(-76.0, 122.0), "Press E", HORIZONTAL_ALIGNMENT_CENTER, 152.0, 14, Color("#ffffff"))

func _get_choice_color() -> Color:
	var value: Variant = choice_data.get("color", Color("#d8b866"))
	if value is Color:
		return value
	return Color("#d8b866")

func _is_player_in_range() -> bool:
	var player: Node2D = _find_player_node()
	if player == null:
		return true
	return global_position.distance_to(player.global_position) <= interact_radius

func _find_player_node() -> Node2D:
	var grouped: Node = get_tree().get_first_node_in_group("player")
	if grouped is Node2D:
		return grouped as Node2D
	var named: Node = get_tree().root.find_child("Player", true, false)
	if named is Node2D:
		return named as Node2D
	return null

func _interact_pressed_once() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true
	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	var just_pressed: bool = e_down and not _e_down_previous
	_e_down_previous = e_down
	return just_pressed
