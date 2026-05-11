extends CanvasLayer

var root: Control = null
var panel: Control = null
var title_label: Label = null
var controls_label: Label = null
var witness_labels: Array[Label] = []
var boon_labels: Array[Label] = []
var selected_labels: Array[Label] = []
var detail_label: Label = null
var status_label: Label = null

var active: bool = false
var source_dummy: Node2D = null
var player: Node2D = null
var auto_close_distance: float = 170.0
var input_guard_timer: float = 0.0

var active_column: int = 0
var selected_witness_index: int = 0
var selected_boon_index: int = 0
var selected_owned_index: int = 0

var witness_entries: Array[Dictionary] = []
var visible_boons: Array[Dictionary] = []
var selected_boons: Array[Dictionary] = []

const ACTION_ORDER := [
	"Light",
	"Heavy",
	"Q",
	"Ultimate",
	"Dodge",
    "On Kill"
]


func _ready() -> void:
	add_to_group("training_dummy_menu")
	_build_ui()
	close_menu()
	set_process(true)


func _process(delta: float) -> void:
	input_guard_timer = maxf(0.0, input_guard_timer - delta)

	if not active:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if source_dummy != null and is_instance_valid(source_dummy) and player != null:
		if source_dummy.global_position.distance_to(player.global_position) > auto_close_distance:
			close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if input_guard_timer > 0.0:
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_ESCAPE, KEY_SPACE:
			get_viewport().set_input_as_handled()
			close_menu()

		KEY_LEFT, KEY_A:
			get_viewport().set_input_as_handled()
			active_column = max(0, active_column - 1)
			_refresh()

		KEY_RIGHT, KEY_D:
			get_viewport().set_input_as_handled()
			active_column = min(2, active_column + 1)
			_refresh()

		KEY_UP, KEY_W:
			get_viewport().set_input_as_handled()
			_move_selection(-1)

		KEY_DOWN, KEY_S:
			get_viewport().set_input_as_handled()
			_move_selection(1)

		KEY_ENTER, KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_confirm_current_selection()

		KEY_BACKSPACE, KEY_DELETE:
			get_viewport().set_input_as_handled()
			_remove_selected_boon()

		KEY_R:
			get_viewport().set_input_as_handled()
			_clear_selected_boons()


func open_menu(new_source_dummy: Node2D = null) -> void:
	source_dummy = new_source_dummy
	player = get_tree().get_first_node_in_group("player") as Node2D
	active = true
	input_guard_timer = 0.18
	root.visible = true
	active_column = 1
	_rebuild_data()
	_refresh()


func close_menu() -> void:
	active = false
	source_dummy = null

	if root != null:
		root.visible = false


func is_menu_active() -> bool:
	return active


func _build_ui() -> void:
	root = Control.new()
	root.name = "TrainingDummyMenuRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = TrainingPanel.new()
	panel.name = "TrainingPanel"
	panel.position = Vector2(92, 62)
	panel.size = Vector2(1096, 590)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	title_label = _make_label("Title", "TRAINING CHAMBER — DAMAGE & TIMING TRIAL", Vector2(140, 90), Vector2(1000, 34), 27, Color("#f4d49a"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)

	var left_title := _make_label("WitnessTitle", "WITNESS", Vector2(140, 145), Vector2(250, 24), 17, Color("#dfaa46"))
	var mid_title := _make_label("BoonTitle", "TEST BOONS", Vector2(420, 145), Vector2(405, 24), 17, Color("#dfaa46"))
	var right_title := _make_label("SelectedTitle", "ACTIVE TEST BUILD", Vector2(855, 145), Vector2(275, 24), 17, Color("#dfaa46"))

	left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	root.add_child(left_title)
	root.add_child(mid_title)
	root.add_child(right_title)

	for i in range(9):
		var label := _make_label("WitnessRow%d" % i, "", Vector2(145, 188 + i * 36), Vector2(240, 30), 16, Color("#f7e8d4"))
		root.add_child(label)
		witness_labels.append(label)

	for i in range(10):
		var label := _make_label("BoonRow%d" % i, "", Vector2(420, 188 + i * 36), Vector2(405, 30), 15, Color("#f7e8d4"))
		root.add_child(label)
		boon_labels.append(label)

	for i in range(10):
		var label := _make_label("SelectedRow%d" % i, "", Vector2(855, 188 + i * 36), Vector2(275, 30), 14, Color("#f7e8d4"))
		root.add_child(label)
		selected_labels.append(label)

	detail_label = _make_label("Detail", "", Vector2(145, 525), Vector2(685, 62), 15, Color("#c4a98f"))
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(detail_label)

	status_label = _make_label("Status", "Choose a boon and press Enter.", Vector2(855, 525), Vector2(275, 62), 15, Color("#9ed8cd"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	controls_label = _make_label(
		"Controls",
		"A/D Column    W/S Select    Enter Add    Delete Remove    R Clear    Space Close",
		Vector2(150, 604),
		Vector2(980, 28),
		14,
		Color("#8f7a64")
	)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(controls_label)


func _make_label(node_name: String, text_value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.position = pos
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _rebuild_data() -> void:
	_rebuild_witness_entries()
	_rebuild_visible_boons()
	_rebuild_selected_boons()


func _rebuild_witness_entries() -> void:
	witness_entries.clear()

	var pool := _get_boon_pool()
	var seen_ids: Array[String] = []

	var preferred_order := [
		"virgil",
		"francesca",
		"minos",
		"geryon",
		"ugolino",
        "beatrice"
	]

	for witness_id in preferred_order:
		for boon in pool:
			if str(boon.get("witness_id", "")) != witness_id:
				continue

			if seen_ids.has(witness_id):
				continue

			seen_ids.append(witness_id)
			witness_entries.append({
				"id": witness_id,
				"name": str(boon.get("witness_name", witness_id.capitalize()))
			})

	for boon in pool:
		var witness_id := str(boon.get("witness_id", ""))

		if witness_id == "":
			continue

		if seen_ids.has(witness_id):
			continue

		seen_ids.append(witness_id)
		witness_entries.append({
			"id": witness_id,
			"name": str(boon.get("witness_name", witness_id.capitalize()))
		})

	selected_witness_index = clampi(selected_witness_index, 0, max(0, witness_entries.size() - 1))


func _rebuild_visible_boons() -> void:
	visible_boons.clear()

	if witness_entries.is_empty():
		return

	var selected_witness_id := str(witness_entries[selected_witness_index].get("id", ""))
	var pool := _get_boon_pool()

	for action in ACTION_ORDER:
		for boon in pool:
			if str(boon.get("witness_id", "")) != selected_witness_id:
				continue

			if str(boon.get("target_action", "")) != action:
				continue

			visible_boons.append(boon)

	for boon in pool:
		if str(boon.get("witness_id", "")) != selected_witness_id:
			continue

		if ACTION_ORDER.has(str(boon.get("target_action", ""))):
			continue

		visible_boons.append(boon)

	selected_boon_index = clampi(selected_boon_index, 0, max(0, visible_boons.size() - 1))


func _rebuild_selected_boons() -> void:
	selected_boons.clear()

	if RunState.has_method("debug_get_selected_boons"):
		selected_boons = RunState.debug_get_selected_boons()

	selected_owned_index = clampi(selected_owned_index, 0, max(0, selected_boons.size() - 1))


func _refresh() -> void:
	_rebuild_visible_boons()
	_rebuild_selected_boons()
	_refresh_witness_column()
	_refresh_boon_column()
	_refresh_selected_column()
	_refresh_detail_text()


func _refresh_witness_column() -> void:
	for i in range(witness_labels.size()):
		var label := witness_labels[i]

		if i >= witness_entries.size():
			label.text = ""
			label.modulate = Color.WHITE
			continue

		var witness := witness_entries[i]
		var marker := "  "

		if active_column == 0 and i == selected_witness_index:
			marker = "> "

		label.text = "%s%s" % [marker, str(witness.get("name", "?"))]
		label.modulate = _get_witness_color(str(witness.get("id", "")))


func _refresh_boon_column() -> void:
	for i in range(boon_labels.size()):
		var label := boon_labels[i]

		if i >= visible_boons.size():
			label.text = ""
			label.modulate = Color.WHITE
			continue

		var boon := visible_boons[i]
		var marker := "  "

		if active_column == 1 and i == selected_boon_index:
			marker = "> "

		var target_action := str(boon.get("target_action", "?"))
		var rarity := str(boon.get("rarity", "Common"))
		var display_name := str(boon.get("display_name", "?"))
		var already_selected := _is_boon_selected(str(boon.get("boon_id", "")))

		var suffix := ""

		if already_selected:
			suffix = "  [owned]"

		label.text = "%s[%s] %s — %s%s" % [
			marker,
			target_action,
			display_name,
			rarity,
			suffix
		]

		if already_selected:
			label.modulate = Color(1, 1, 1, 0.42)
		else:
			label.modulate = _get_witness_color(str(boon.get("witness_id", "")))


func _refresh_selected_column() -> void:
	for i in range(selected_labels.size()):
		var label := selected_labels[i]

		if i >= selected_boons.size():
			label.text = ""
			label.modulate = Color.WHITE
			continue

		var boon := selected_boons[i]
		var marker := "  "

		if active_column == 2 and i == selected_owned_index:
			marker = "> "

		label.text = "%s[%s] %s" % [
			marker,
			str(boon.get("target_action", "?")),
			str(boon.get("display_name", "?"))
		]

		label.modulate = _get_witness_color(str(boon.get("witness_id", "")))


func _refresh_detail_text() -> void:
	var boon := _get_current_focus_boon()

	if boon.is_empty():
		detail_label.text = "No boon selected."
		return

	detail_label.text = "%s — %s\n%s\nEffect: %s" % [
		str(boon.get("witness_name", "?")),
		str(boon.get("display_name", "?")),
		str(boon.get("description", "")),
		_format_effect_type(str(boon.get("effect_type", "")))
	]


func _move_selection(amount: int) -> void:
	if active_column == 0:
		selected_witness_index = clampi(selected_witness_index + amount, 0, max(0, witness_entries.size() - 1))
		selected_boon_index = 0

	elif active_column == 1:
		selected_boon_index = clampi(selected_boon_index + amount, 0, max(0, visible_boons.size() - 1))

	else:
		selected_owned_index = clampi(selected_owned_index + amount, 0, max(0, selected_boons.size() - 1))

	_refresh()


func _confirm_current_selection() -> void:
	if active_column != 1:
		return

	if visible_boons.is_empty():
		return

	var boon := visible_boons[selected_boon_index]
	var boon_id := str(boon.get("boon_id", ""))

	if boon_id == "":
		return

	if _is_boon_selected(boon_id):
		status_label.text = "Already selected: %s." % str(boon.get("display_name", "?"))
		return

	if RunState.has_method("debug_add_boon_by_id"):
		var added: bool = RunState.debug_add_boon_by_id(boon_id)

		if added:
			status_label.text = "Added: %s." % str(boon.get("display_name", "?"))
		else:
			status_label.text = "Could not add boon."

	_refresh()


func _remove_selected_boon() -> void:
	if active_column != 2:
		return

	if selected_boons.is_empty():
		return

	var boon := selected_boons[selected_owned_index]
	var boon_id := str(boon.get("boon_id", ""))

	if boon_id == "":
		return

	if RunState.has_method("debug_remove_boon_by_id"):
		var removed: bool = RunState.debug_remove_boon_by_id(boon_id)

		if removed:
			status_label.text = "Removed: %s." % str(boon.get("display_name", "?"))
		else:
			status_label.text = "Could not remove boon."

	_refresh()


func _clear_selected_boons() -> void:
	if RunState.has_method("debug_clear_boons"):
		RunState.debug_clear_boons()

	status_label.text = "Training build cleared."
	_refresh()


func _get_current_focus_boon() -> Dictionary:
	if active_column == 2 and not selected_boons.is_empty():
		return selected_boons[selected_owned_index]

	if not visible_boons.is_empty():
		return visible_boons[selected_boon_index]

	return {}


func _get_boon_pool() -> Array[Dictionary]:
	if RunState.has_method("debug_get_boon_pool"):
		return RunState.debug_get_boon_pool()

	return []


func _is_boon_selected(boon_id: String) -> bool:
	for boon in selected_boons:
		if str(boon.get("boon_id", "")) == boon_id:
			return true

	return false


func _format_effect_type(effect_type: String) -> String:
	match effect_type:
		"apply_status":
			return "Applies a status effect."
		"bonus_damage_vs_status":
			return "Deals bonus damage against a marked/statused target."
		"detonate_status_damage":
			return "Consumes a status for burst damage."
		"spread_status_on_hit":
			return "Spreads a status to nearby enemies."
		"execute_status_below_ratio":
			return "Executes targets below a health threshold."
		"heal_on_hit_vs_status":
			return "Heals when hitting a target with the required status."
		"on_kill_heal_flat":
			return "Restores health on kill."
		"perfect_dodge_ultimate_flat":
			return "Rewards perfect dodges."
		_:
			return "Unknown effect."


func _get_witness_color(witness_id: String) -> Color:
	match witness_id:
		"virgil":
			return Color("#dfaa46")
		"francesca":
			return Color("#d85c8a")
		"minos":
			return Color("#ff684a")
		"geryon":
			return Color("#7fdc54")
		"ugolino":
			return Color("#9ed8cd")
		"beatrice":
			return Color("#f7e8d4")
		_:
			return Color("#f7e8d4")


class TrainingPanel:
	extends Control

	func _draw() -> void:
		draw_rect(Rect2(Vector2(6, 6), size), Color(0, 0, 0, 0.34))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.014, 0.012, 0.96))
		draw_rect(Rect2(Vector2(12, 12), size - Vector2(24, 24)), Color(0.08, 0.035, 0.030, 0.90))
		draw_rect(Rect2(Vector2.ZERO, size), Color("#6b2a1f"), false, 4.0)
		draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color("#dfaa46"), false, 1.0)

		draw_line(Vector2(300, 88), Vector2(300, size.y - 92), Color("#6b2a1f"), 2.0)
		draw_line(Vector2(745, 88), Vector2(745, size.y - 92), Color("#6b2a1f"), 2.0)
		draw_line(Vector2(42, 92), Vector2(size.x - 42, 92), Color(0.95, 0.70, 0.28, 0.22), 1.0)
		draw_line(Vector2(42, size.y - 95), Vector2(size.x - 42, size.y - 95), Color("#6b2a1f"), 1.0)
