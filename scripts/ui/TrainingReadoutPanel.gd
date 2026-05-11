extends CanvasLayer

var root: Control = null
var panel: TrainingReadoutDrawPanel = null
var dummy: Node = null


func _ready() -> void:
	layer = 45
	_build_ui()
	set_process(true)


func _process(_delta: float) -> void:
	if dummy == null or not is_instance_valid(dummy):
		dummy = _find_dummy()

	var menu_active := _is_training_menu_active()

	if dummy == null or not dummy.has_method("get_training_readout_data") or menu_active:
		root.visible = false
		return

	var data: Dictionary = dummy.call("get_training_readout_data")
	var near: bool = bool(data.get("near", false))

	root.visible = near

	if near:
		panel.data = data
		panel.queue_redraw()


func _build_ui() -> void:
	root = Control.new()
	root.name = "TrainingReadoutRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = TrainingReadoutDrawPanel.new()
	panel.name = "TrainingReadoutDrawPanel"
	panel.position = Vector2(24, 84)
	panel.size = Vector2(342, 520)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	root.visible = false


func _find_dummy() -> Node:
	var dummies := get_tree().get_nodes_in_group("training_dummy")

	if dummies.is_empty():
		return null

	return dummies[0]


func _is_training_menu_active() -> bool:
	var menus := get_tree().get_nodes_in_group("training_dummy_menu")

	if menus.is_empty():
		return false

	var menu := menus[0]

	if menu != null and menu.has_method("is_menu_active"):
		return bool(menu.call("is_menu_active"))

	return false


class TrainingReadoutDrawPanel:
	extends Control

	var data: Dictionary = {}

	func _draw() -> void:
		if data.is_empty():
			return

		_draw_panel_background()
		_draw_header()
		_draw_hp()
		_draw_damage()
		_draw_statuses()
		_draw_boons()
		_draw_footer()

	func _draw_panel_background() -> void:
		draw_rect(Rect2(Vector2(4, 4), size), Color(0, 0, 0, 0.34))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.020, 0.012, 0.010, 0.96))
		draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color(0.075, 0.035, 0.030, 0.88))
		draw_rect(Rect2(Vector2.ZERO, size), Color("#6b2a1f"), false, 4.0)
		draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color("#dfaa46"), false, 1.0)

	func _draw_header() -> void:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, 34),
			"TRAINING READOUT",
			HORIZONTAL_ALIGNMENT_LEFT,
			220,
			20,
			Color("#dfaa46")
		)

		var profile_name := str(data.get("profile_name", "Dummy"))
		_draw_chip(Vector2(190, 18), profile_name, Color("#9ed8cd"), 132)

	func _draw_hp() -> void:
		var hp: float = float(data.get("hp", 0.0))
		var max_hp: float = float(data.get("max_hp", 1.0))
		var ratio: float = float(data.get("hp_ratio", 0.0))

		_draw_meter(
			Vector2(18, 62),
			306,
			18,
			ratio,
			"HP %.0f / %.0f" % [hp, max_hp],
			Color("#d63a2f")
		)

	func _draw_damage() -> void:
		var y := 102.0
		var last_kind := str(data.get("last_hit_kind", "None"))
		var last_damage: float = float(data.get("last_hit_damage", 0.0))
		var current_dps: float = float(data.get("current_dps", 0.0))
		var active: bool = bool(data.get("last_hit_active", false))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, y),
			"DAMAGE",
			HORIZONTAL_ALIGNMENT_LEFT,
			200,
			14,
			Color("#c4a98f")
		)

		y += 18.0

		_draw_chip(
			Vector2(18, y),
			"Last: %s" % last_kind,
			Color("#ffd36a") if active else Color("#8f7a64"),
			142
		)

		_draw_chip(
			Vector2(168, y),
			"%.1f dmg" % last_damage,
			Color("#ff684a"),
			74
		)

		_draw_chip(
			Vector2(250, y),
			"%.1f DPS" % current_dps,
			Color("#9ed8cd"),
			74
		)

	func _draw_statuses() -> void:
		var y := 160.0
		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, y),
			"STATUSES",
			HORIZONTAL_ALIGNMENT_LEFT,
			200,
			14,
			Color("#c4a98f")
		)

		var statuses: Array = data.get("statuses", [])

		if statuses.is_empty():
			_draw_chip(Vector2(18, y + 18), "None", Color("#8f7a64"), 92)
			return

		var x := 18.0

		for status in statuses:
			var status_id := str(status.get("id", ""))
			var stacks := int(status.get("stacks", 1))
			_draw_status_icon(Vector2(x + 12, y + 32), status_id, stacks)
			x += 46.0

	func _draw_boons() -> void:
		var y := 230.0
		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, y),
			"ACTIVE BOONS",
			HORIZONTAL_ALIGNMENT_LEFT,
			200,
			14,
			Color("#dfaa46")
		)

		y += 20.0

		var boon_lines: Array = data.get("boon_lines", [])

		if boon_lines.is_empty():
			boon_lines = ["None"]

		for i in range(mini(7, boon_lines.size())):
			_draw_chip(
				Vector2(18, y + float(i) * 28.0),
				str(boon_lines[i]),
				Color("#f7e8d4"),
				306
			)

	func _draw_footer() -> void:
		var y := size.y - 58.0

		draw_line(Vector2(18, y), Vector2(size.x - 18, y), Color("#6b2a1f"), 1.0)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, y + 22),
			"E Menu     Tab Profile     H Reset",
			HORIZONTAL_ALIGNMENT_LEFT,
			305,
			12,
			Color("#8f7a64")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(18, y + 42),
			"B/P/J Status     R Clear Boons",
			HORIZONTAL_ALIGNMENT_LEFT,
			305,
			12,
			Color("#8f7a64")
		)

	func _draw_chip(pos: Vector2, text_value: String, color: Color, width: float) -> void:
		var rect := Rect2(pos, Vector2(width, 22))

		draw_rect(rect, Color(0, 0, 0, 0.58))
		draw_rect(rect, Color(color.r, color.g, color.b, 0.14))
		draw_rect(rect, color, false, 1.0)

		draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(7, 15),
			text_value,
			HORIZONTAL_ALIGNMENT_LEFT,
			width - 12,
			11,
			Color("#fff1dc")
		)

	func _draw_meter(pos: Vector2, width: float, height: float, ratio: float, label: String, color: Color) -> void:
		var rect := Rect2(pos, Vector2(width, height))

		draw_rect(rect, Color(0, 0, 0, 0.62))
		draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), height)), Color(color.r, color.g, color.b, 0.72))
		draw_rect(rect, color, false, 1.0)

		draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(8, 13),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			width - 16,
			11,
			Color("#fff1dc")
		)

	func _draw_status_icon(pos: Vector2, status_id: String, stacks: int) -> void:
		var color := _get_status_color(status_id)

		draw_circle(pos, 11.0, Color(0, 0, 0, 0.74))
		draw_arc(pos, 11.0, 0.0, TAU, 28, color, 1.5)

		match status_id:
			"bleed":
				_draw_bleed_icon(pos)
				_draw_stack_pips(pos + Vector2(0, 15), stacks, color)

			"poison":
				_draw_poison_icon(pos)
				_draw_stack_pips(pos + Vector2(0, 15), stacks, color)

			"judgment":
				_draw_judgment_icon(pos)

			_:
				draw_circle(pos, 3.0, Color.WHITE)

	func _draw_bleed_icon(pos: Vector2) -> void:
		var color := Color("#ff2b1f")

		draw_circle(pos + Vector2(0, -2.5), 3.5, color)

		var points := PackedVector2Array([
			pos + Vector2(-3.2, 0.0),
			pos + Vector2(3.2, 0.0),
			pos + Vector2(0.0, 6.2)
		])

		draw_polygon(points, PackedColorArray([color, color, color]))

	func _draw_poison_icon(pos: Vector2) -> void:
		var color := Color("#6eea4b")
		var bright := Color("#d7ffd0")

		draw_circle(pos + Vector2(-3.7, -1.2), 2.1, color)
		draw_circle(pos + Vector2(3.7, -1.2), 2.1, color)
		draw_circle(pos + Vector2(0.0, 3.1), 2.5, color)

		draw_line(pos + Vector2(-5.2, -5.4), pos + Vector2(5.2, 5.4), bright, 1.1)
		draw_line(pos + Vector2(5.2, -5.4), pos + Vector2(-5.2, 5.4), bright, 1.1)

	func _draw_judgment_icon(pos: Vector2) -> void:
		var color := Color("#ffd36a")

		draw_arc(pos, 5.8, 0.0, TAU, 28, color, 1.3)
		draw_line(pos + Vector2(0, -5.5), pos + Vector2(0, 4.2), color, 1.3)
		draw_line(pos + Vector2(-5.0, -2.0), pos + Vector2(5.0, -2.0), color, 1.3)

	func _draw_stack_pips(pos: Vector2, stacks: int, color: Color) -> void:
		var safe_stacks: int = clampi(stacks, 1, 8)
		var spacing: float = 3.2
		var total_width: float = float(safe_stacks - 1) * spacing
		var start_x: float = -total_width * 0.5

		for i in range(safe_stacks):
			var pip_pos := pos + Vector2(start_x + float(i) * spacing, 0)
			draw_circle(pip_pos + Vector2(0.6, 0.8), 1.35, Color(0, 0, 0, 0.75))
			draw_circle(pip_pos, 1.25, color)

	func _get_status_color(status_id: String) -> Color:
		match status_id:
			"bleed":
				return Color("#ff2b1f")
			"poison":
				return Color("#6eea4b")
			"judgment":
				return Color("#ffd36a")
			_:
				return Color("#f7e8d4")
