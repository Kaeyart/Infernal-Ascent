extends Node2D
class_name PatronBoonAltar

signal boon_claimed(patron_id: String, boon: Dictionary)

var patron_id: String = ""
var boon_data: Dictionary = {}
var interact_radius: float = 74.0
var claimed: bool = false
var prompt_visible: bool = false
var _e_down_previous: bool = false

func setup(p_new_patron_id: String, p_boon_data: Dictionary) -> void:
	patron_id = p_new_patron_id
	boon_data = p_boon_data.duplicate(true)
	claimed = false
	queue_redraw()

func _process(_delta: float) -> void:
	if claimed:
		return
	prompt_visible = _is_player_in_range()
	if prompt_visible and _interact_pressed_once():
		_claim()
	queue_redraw()

func _draw() -> void:
	var patron_color: Color = PatronRegistry.get_patron_color(patron_id)
	var dark: Color = Color(0.06, 0.045, 0.04, 0.94)
	var panel: Rect2 = Rect2(Vector2(-155.0, -116.0), Vector2(310.0, 150.0))
	draw_rect(panel, dark, true)
	draw_rect(panel, patron_color, false, 3.0)
	draw_circle(Vector2.ZERO, 36.0, Color(patron_color.r, patron_color.g, patron_color.b, 0.18))
	draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 64, patron_color, 3.0)
	draw_circle(Vector2.ZERO, 14.0, patron_color)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-142.0, -88.0), PatronRegistry.get_patron_name(patron_id), HORIZONTAL_ALIGNMENT_LEFT, 284.0, 18, patron_color)
	draw_string(font, Vector2(-142.0, -62.0), str(boon_data.get("name", "Boon")), HORIZONTAL_ALIGNMENT_LEFT, 284.0, 20, Color("#f2e4c8"))
	draw_string(font, Vector2(-142.0, -36.0), str(boon_data.get("slot", "Passive")) + " / " + str(boon_data.get("rarity", "Common")), HORIZONTAL_ALIGNMENT_LEFT, 284.0, 14, Color("#b8a891"))
	draw_string(font, Vector2(-142.0, 58.0), str(boon_data.get("description", "Claim this favor.")), HORIZONTAL_ALIGNMENT_LEFT, 284.0, 14, Color("#d6c5aa"))
	if prompt_visible:
		draw_string(font, Vector2(-70.0, 104.0), "Press E to claim", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 16, Color("#ffffff"))

func _claim() -> void:
	claimed = true
	emit_signal("boon_claimed", patron_id, boon_data.duplicate(true))
	queue_free()

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
