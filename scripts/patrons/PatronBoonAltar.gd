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
	var dark: Color = Color(0.055, 0.043, 0.038, 0.96)
	var panel: Rect2 = Rect2(Vector2(-220.0, -172.0), Vector2(440.0, 275.0))

	draw_rect(panel, dark, true)
	draw_rect(panel, patron_color, false, 3.0)

	draw_circle(Vector2(0.0, -26.0), 36.0, Color(patron_color.r, patron_color.g, patron_color.b, 0.15))
	draw_arc(Vector2(0.0, -26.0), 44.0, 0.0, TAU, 64, patron_color, 3.0)
	draw_circle(Vector2(0.0, -26.0), 13.0, patron_color)

	var font: Font = ThemeDB.fallback_font

	var y: float = -144.0
	draw_string(font, Vector2(-205.0, y), PatronRegistry.get_patron_name(patron_id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 410.0, 18, patron_color)
	y += 22.0
	_draw_wrapped_lines(font, PatronRegistry.get_patron_role_text(patron_id), Vector2(-205.0, y), 410.0, 14, Color("#d7c5aa"), 2)
	y += 42.0

	draw_string(font, Vector2(-205.0, y), str(boon_data.get("name", "Boon")), HORIZONTAL_ALIGNMENT_LEFT, 410.0, 21, Color("#f2e4c8"))
	y += 25.0
	var slot_line: String = "Affects: %s   Rarity: %s" % [
		str(boon_data.get("slot", "Passive")),
		str(boon_data.get("rarity", "Common"))
	]
	draw_string(font, Vector2(-205.0, y), slot_line, HORIZONTAL_ALIGNMENT_LEFT, 410.0, 14, Color("#b8a891"))
	y += 23.0

	_draw_label_value(font, "What it does:", str(boon_data.get("summary", boon_data.get("description", "Claim this favor."))), y)
	y += 38.0
	_draw_label_value(font, "Trigger:", str(boon_data.get("trigger_text", "When the listed action happens.")), y)
	y += 38.0
	_draw_label_value(font, "Effect:", str(boon_data.get("effect_text", boon_data.get("description", "This boon gives you power."))), y)
	y += 47.0
	_draw_label_value(font, "Good for:", str(boon_data.get("build_hint", "Choose this if it supports your current build.")), y)

	if prompt_visible:
		draw_string(font, Vector2(-88.0, 132.0), "Press E to claim this boon", HORIZONTAL_ALIGNMENT_CENTER, 176.0, 16, Color("#ffffff"))

func _draw_label_value(font: Font, label: String, value: String, y: float) -> void:
	draw_string(font, Vector2(-205.0, y), label, HORIZONTAL_ALIGNMENT_LEFT, 110.0, 13, Color("#c59254"))
	_draw_wrapped_lines(font, value, Vector2(-90.0, y), 292.0, 13, Color("#e2d0b5"), 2)

func _draw_wrapped_lines(font: Font, text: String, start: Vector2, max_width: float, font_size: int, color: Color, max_lines: int) -> void:
	var words: PackedStringArray = text.split(" ")
	var lines: Array[String] = []
	var current_line: String = ""

	for word: String in words:
		var candidate: String = word if current_line == "" else current_line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= max_width:
			current_line = candidate
		else:
			if current_line != "":
				lines.append(current_line)
			current_line = word
		if lines.size() >= max_lines:
			break

	if lines.size() < max_lines and current_line != "":
		lines.append(current_line)

	for i: int in range(min(lines.size(), max_lines)):
		var line_text: String = lines[i]
		if i == max_lines - 1 and words.size() > 0:
			var consumed_text: String = " ".join(lines)
			if consumed_text.length() < text.length():
				line_text = _trim_to_width(font, line_text + "...", max_width, font_size)
		draw_string(font, start + Vector2(0.0, float(i) * 15.0), line_text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)

func _trim_to_width(font: Font, text: String, max_width: float, font_size: int) -> String:
	var result: String = text
	while result.length() > 4 and font.get_string_size(result, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > max_width:
		result = result.substr(0, result.length() - 4) + "..."
	return result

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
