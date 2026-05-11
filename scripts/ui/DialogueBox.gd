extends CanvasLayer

signal dialogue_finished()

var root: Control = null
var panel: Control = null
var speaker_label: Label = null
var role_label: Label = null
var body_label: Label = null
var prompt_label: Label = null
var counter_label: Label = null

var active: bool = false
var speaker_name: String = ""
var speaker_role: String = ""
var source_accent: Color = Color("#dfaa46")
var lines: Array[String] = []
var line_index: int = 0
var input_guard_timer: float = 0.0

var source_npc: Node2D = null
var player: Node2D = null
var auto_close_distance: float = 120.0


func _ready() -> void:
	add_to_group("dialogue_box")
	layer = 80
	_build_ui()
	_hide_dialogue()
	set_process(true)


func _process(delta: float) -> void:
	input_guard_timer = maxf(0.0, input_guard_timer - delta)

	if not active:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if source_npc != null and is_instance_valid(source_npc) and player != null:
		if source_npc.global_position.distance_to(player.global_position) > auto_close_distance:
			close_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if input_guard_timer > 0.0:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if not key_event.pressed or key_event.echo:
			return

		if key_event.keycode in [KEY_SPACE, KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			close_dialogue()
			return

		if key_event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_advance_dialogue()
			return

	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func start_dialogue(new_speaker_name: String, new_lines: Array, new_source_npc: Node2D = null) -> void:
	speaker_name = new_speaker_name
	source_npc = new_source_npc
	player = get_tree().get_first_node_in_group("player") as Node2D
	_setup_source_identity()

	lines.clear()

	for line in new_lines:
		lines.append(str(line))

	if lines.is_empty():
		return

	active = true
	line_index = 0
	input_guard_timer = 0.18

	_show_dialogue()
	_refresh_text()


func close_dialogue() -> void:
	_hide_dialogue()
	dialogue_finished.emit()


func is_dialogue_active() -> bool:
	return active


func _advance_dialogue() -> void:
	line_index += 1

	if line_index >= lines.size():
		close_dialogue()
		return

	_refresh_text()


func _setup_source_identity() -> void:
	speaker_role = ""
	source_accent = Color("#dfaa46")

	if source_npc == null or not is_instance_valid(source_npc):
		return

	if _object_has_property(source_npc, "role_subtitle"):
		speaker_role = str(source_npc.get("role_subtitle"))

	if _object_has_property(source_npc, "accent_color"):
		var value: Variant = source_npc.get("accent_color")

		if value is Color:
			source_accent = value as Color


func _build_ui() -> void:
	root = Control.new()
	root.name = "DialogueRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = DialoguePanel.new()
	panel.name = "DialoguePanel"
	panel.position = Vector2(180, 486)
	panel.size = Vector2(920, 184)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	speaker_label = _make_label("SpeakerLabel", "", Vector2(220, 508), Vector2(520, 30), 23, Color("#f4d49a"))
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(speaker_label)

	role_label = _make_label("RoleLabel", "", Vector2(220, 536), Vector2(520, 22), 13, Color("#c4a98f"))
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(role_label)

	body_label = _make_label("BodyLabel", "", Vector2(220, 565), Vector2(840, 58), 18, Color("#f7e8d4"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	root.add_child(body_label)

	prompt_label = _make_label("PromptLabel", "[E] Continue    [Space] Close", Vector2(690, 632), Vector2(370, 24), 14, Color("#c4a98f"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(prompt_label)

	counter_label = _make_label("CounterLabel", "", Vector2(220, 632), Vector2(170, 24), 13, Color("#8f7a64"))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(counter_label)


func _make_label(node_name: String, text_value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text_value
	label.position = pos
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _show_dialogue() -> void:
	active = true
	root.visible = true


func _hide_dialogue() -> void:
	active = false
	source_npc = null

	if root != null:
		root.visible = false


func _refresh_text() -> void:
	if speaker_label == null:
		return

	speaker_label.text = speaker_name.to_upper()
	role_label.text = speaker_role
	body_label.text = lines[line_index]
	counter_label.text = "%d / %d" % [line_index + 1, lines.size()]

	var panel_accent: Color = source_accent
	panel.set("accent_color", panel_accent)
	panel.queue_redraw()

	speaker_label.add_theme_color_override("font_color", source_accent.lightened(0.20))
	role_label.add_theme_color_override("font_color", Color("#c4a98f"))

	if line_index >= lines.size() - 1:
		prompt_label.text = "[E] Finish    [Space] Close"
	else:
		prompt_label.text = "[E] Continue    [Space] Close"


func _object_has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false

	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true

	return false


class DialoguePanel:
	extends Control

	var accent_color: Color = Color("#dfaa46")

	func _draw() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)

		draw_rect(Rect2(Vector2(5, 5), size), Color(0, 0, 0, 0.34))
		draw_rect(rect, Color(0.025, 0.013, 0.010, 0.94))
		draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color(0.085, 0.033, 0.027, 0.86))
		draw_rect(rect, Color("#6b2a1f"), false, 4.0)
		draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), accent_color, false, 1.0)
		draw_rect(Rect2(Vector2(18, 18), size - Vector2(36, 36)), Color(1, 1, 1, 0.035), false, 1.0)

		draw_line(Vector2(28, 60), Vector2(size.x - 28, 60), Color(accent_color.r, accent_color.g, accent_color.b, 0.28), 1.0)
		draw_line(Vector2(28, size.y - 40), Vector2(size.x - 28, size.y - 40), Color(accent_color.r, accent_color.g, accent_color.b, 0.22), 1.0)

		for corner in [Vector2(14, 14), Vector2(size.x - 14, 14), Vector2(14, size.y - 14), Vector2(size.x - 14, size.y - 14)]:
			draw_circle(corner, 4.0, accent_color)
