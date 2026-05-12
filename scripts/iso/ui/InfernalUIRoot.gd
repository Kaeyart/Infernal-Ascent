extends CanvasLayer

class_name InfernalUIRoot
## V13 Infernal UI Framework V1.
## A real CanvasLayer + Control HUD. Gameplay scripts should feed this layer state;
## this layer owns screen UI, route cards, reward inspection, and run summary presentation.

@export var show_combat_hud: bool = true
@export var show_breadcrumb: bool = true
@export var route_cards_require_choice_phase: bool = true
@export var intro_visible_seconds: float = 2.7
@export var fade_ui_when_no_choices: bool = true

var _root: Control = null
var _combat_panel: Panel = null
var _hp_fill: ColorRect = null
var _hp_text: Label = null
var _currency_label: Label = null
var _breadcrumb_panel: Panel = null
var _breadcrumb_label: Label = null
var _objective_panel: Panel = null
var _objective_title: Label = null
var _objective_subtitle: Label = null
var _route_overlay: Panel = null
var _route_cards: Array[Panel] = []
var _route_labels: Array[Label] = []
var _focus_panel: Panel = null
var _focus_title: Label = null
var _focus_meta: Label = null
var _focus_body: Label = null
var _summary_panel: Panel = null
var _summary_title: Label = null
var _summary_body: Label = null

var _built: bool = false
var _last_phase: String = ""
var _last_room_title: String = ""
var _intro_timer: float = 0.0

func _ready() -> void:
	layer = 96
	add_to_group("infernal_ui_root")
	_build_ui()

func _process(delta: float) -> void:
	if _intro_timer > 0.0:
		_intro_timer -= delta
		if _intro_timer <= 0.0 and _objective_panel != null:
			_objective_panel.visible = false

func update_from_run_state(data: Dictionary) -> void:
	if not _built:
		_build_ui()
	var room_title: String = str(data.get("room_title", "Unknown Room"))
	var room_type: String = str(data.get("room_type", "Room"))
	var phase: String = str(data.get("phase", "ROOM"))
	var depth: int = int(data.get("depth", 1))
	var completed: int = int(data.get("completed", 0))
	var total: int = int(data.get("total", 0))
	var objective: String = str(data.get("objective", "Proceed."))
	var currency: String = str(data.get("currency", ""))
	var route: String = str(data.get("route", ""))
	var player_data: Dictionary = {}
	if data.get("player", {}) is Dictionary:
		player_data = data.get("player", {}) as Dictionary

	_update_combat_panel(player_data, currency)
	_update_breadcrumb(room_title, room_type, phase, depth, completed, total)
	_update_route_cards(data.get("choices", []), phase)
	_update_summary(data, phase)

	if phase != _last_phase or room_title != _last_room_title:
		if phase != "ROUTE CHOICE" and phase != "RUN COMPLETE":
			show_room_intro(room_title, "%s · Depth %d\n%s" % [room_type, depth, objective])
		_last_phase = phase
		_last_room_title = room_title

	if _breadcrumb_label != null:
		_breadcrumb_label.tooltip_text = "Route: %s" % route

func show_room_intro(title: String, subtitle: String = "") -> void:
	if not _built:
		_build_ui()
	_objective_panel.visible = true
	_objective_title.text = title.to_upper()
	_objective_subtitle.text = subtitle
	_intro_timer = intro_visible_seconds

func set_focus_payload(payload: Dictionary, focused: bool) -> void:
	if not _built:
		_build_ui()
	if not focused or payload.is_empty():
		_focus_panel.visible = false
		return
	var kind: String = str(payload.get("kind", "object"))
	var title: String = str(payload.get("display_name", "Interact"))
	var description: String = str(payload.get("description", ""))
	var reward_id: String = str(payload.get("reward_id", ""))
	_focus_panel.visible = true
	_focus_title.text = title.to_upper()
	_focus_meta.text = _focus_meta_text(kind, reward_id)
	_focus_body.text = _focus_body_text(kind, description, payload)
	_apply_panel_style(_focus_panel, Color(0.024, 0.018, 0.015, 0.94), _color_for_kind(kind), 2, 10)

func clear_focus_payload() -> void:
	if _focus_panel != null:
		_focus_panel.visible = false

func _build_ui() -> void:
	if _built:
		return
	_root = Control.new()
	_root.name = "InfernalUIRootControl"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_build_combat_panel()
	_build_breadcrumb()
	_build_objective_toast()
	_build_route_overlay()
	_build_focus_panel()
	_build_summary_panel()
	_built = true

func _build_combat_panel() -> void:
	_combat_panel = _make_panel("CombatStatus", Vector2(18.0, 18.0), Vector2(306.0, 88.0), Color(0.018, 0.014, 0.012, 0.86), Color(0.62, 0.40, 0.22, 0.80), 2, 8)
	var hp_back: ColorRect = ColorRect.new()
	hp_back.name = "HPBack"
	hp_back.position = Vector2(16.0, 18.0)
	hp_back.size = Vector2(220.0, 18.0)
	hp_back.color = Color(0.08, 0.022, 0.018, 0.95)
	_combat_panel.add_child(hp_back)
	_hp_fill = ColorRect.new()
	_hp_fill.name = "HPFill"
	_hp_fill.position = hp_back.position
	_hp_fill.size = hp_back.size
	_hp_fill.color = Color(0.72, 0.08, 0.045, 0.96)
	_combat_panel.add_child(_hp_fill)
	_hp_text = _make_label("HPText", _combat_panel, Vector2(16.0, 43.0), Vector2(270.0, 20.0), 13, Color(1.0, 0.86, 0.66, 1.0))
	_currency_label = _make_label("CurrencyText", _combat_panel, Vector2(16.0, 62.0), Vector2(270.0, 20.0), 12, Color(0.78, 0.73, 0.62, 1.0))

func _build_breadcrumb() -> void:
	_breadcrumb_panel = _make_panel("Breadcrumb", Vector2(360.0, 18.0), Vector2(560.0, 46.0), Color(0.014, 0.012, 0.011, 0.74), Color(0.42, 0.31, 0.20, 0.70), 1, 8)
	_breadcrumb_label = _make_label("BreadcrumbText", _breadcrumb_panel, Vector2(12.0, 9.0), Vector2(536.0, 30.0), 15, Color(0.93, 0.84, 0.66, 1.0))
	_breadcrumb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_objective_toast() -> void:
	_objective_panel = _make_panel("ObjectiveToast", Vector2(390.0, 76.0), Vector2(500.0, 96.0), Color(0.025, 0.018, 0.014, 0.94), Color(0.90, 0.42, 0.16, 0.86), 2, 10)
	_objective_title = _make_label("ObjectiveTitle", _objective_panel, Vector2(16.0, 12.0), Vector2(468.0, 25.0), 18, Color(1.0, 0.86, 0.58, 1.0))
	_objective_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_subtitle = _make_label("ObjectiveSubtitle", _objective_panel, Vector2(22.0, 42.0), Vector2(456.0, 44.0), 13, Color(0.86, 0.80, 0.70, 1.0))
	_objective_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_panel.visible = false

func _build_route_overlay() -> void:
	_route_overlay = _make_panel("RouteChoiceOverlay", Vector2(220.0, 575.0), Vector2(840.0, 156.0), Color(0.014, 0.010, 0.009, 0.92), Color(0.64, 0.42, 0.20, 0.82), 2, 12)
	var header: Label = _make_label("RouteHeader", _route_overlay, Vector2(18.0, 10.0), Vector2(804.0, 24.0), 14, Color(0.95, 0.80, 0.50, 1.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.text = "CHOOSE THE NEXT DESCENT"
	for i: int in range(3):
		var card: Panel = Panel.new()
		card.name = "RouteCard_%d" % i
		card.position = Vector2(18.0 + float(i) * 272.0, 42.0)
		card.size = Vector2(258.0, 96.0)
		_route_overlay.add_child(card)
		var label: Label = _make_label("RouteCardLabel_%d" % i, card, Vector2(12.0, 9.0), Vector2(234.0, 78.0), 13, Color(1.0, 0.88, 0.66, 1.0))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_route_cards.append(card)
		_route_labels.append(label)
	_route_overlay.visible = false

func _build_focus_panel() -> void:
	_focus_panel = _make_panel("FocusInspectPanel", Vector2(930.0, 96.0), Vector2(316.0, 210.0), Color(0.024, 0.018, 0.015, 0.94), Color(0.62, 0.44, 0.24, 0.82), 2, 10)
	_focus_title = _make_label("FocusTitle", _focus_panel, Vector2(16.0, 14.0), Vector2(284.0, 28.0), 18, Color(1.0, 0.86, 0.56, 1.0))
	_focus_meta = _make_label("FocusMeta", _focus_panel, Vector2(16.0, 48.0), Vector2(284.0, 24.0), 12, Color(0.72, 0.90, 1.0, 1.0))
	_focus_body = _make_label("FocusBody", _focus_panel, Vector2(16.0, 82.0), Vector2(284.0, 110.0), 13, Color(0.86, 0.80, 0.70, 1.0))
	_focus_panel.visible = false

func _build_summary_panel() -> void:
	_summary_panel = _make_panel("RunSummaryPanel", Vector2(390.0, 180.0), Vector2(500.0, 250.0), Color(0.018, 0.014, 0.012, 0.96), Color(0.96, 0.66, 0.24, 0.90), 3, 12)
	_summary_title = _make_label("SummaryTitle", _summary_panel, Vector2(20.0, 18.0), Vector2(460.0, 34.0), 22, Color(1.0, 0.84, 0.48, 1.0))
	_summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_body = _make_label("SummaryBody", _summary_panel, Vector2(32.0, 64.0), Vector2(436.0, 160.0), 14, Color(0.88, 0.82, 0.72, 1.0))
	_summary_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_panel.visible = false

func _update_combat_panel(player_data: Dictionary, currency: String) -> void:
	if not show_combat_hud:
		_combat_panel.visible = false
		return
	_combat_panel.visible = true
	var current_hp: int = int(player_data.get("current_health", player_data.get("hp", 0)))
	var max_hp: int = maxi(1, int(player_data.get("max_health", player_data.get("max_hp", 1))))
	var ratio: float = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_hp_fill.size.x = 220.0 * ratio
	_hp_text.text = "PENITENT KNIGHT    HP %d / %d" % [current_hp, max_hp]
	_currency_label.text = currency

func _update_breadcrumb(room_title: String, room_type: String, phase: String, depth: int, completed: int, total: int) -> void:
	if not show_breadcrumb:
		_breadcrumb_panel.visible = false
		return
	_breadcrumb_panel.visible = true
	_breadcrumb_label.text = "%s  ·  %s  ·  DEPTH %d  ·  %d/%d" % [room_title.to_upper(), phase, depth, completed, total]

func _update_route_cards(choices_value: Variant, phase: String) -> void:
	var choices: Array = []
	if choices_value is Array:
		choices = choices_value as Array
	var should_show: bool = choices.size() > 0 and ((not route_cards_require_choice_phase) or phase == "ROUTE CHOICE")
	_route_overlay.visible = should_show
	if not should_show:
		return
	var slot_names: Array[String] = ["LEFT GATE", "CENTER GATE", "RIGHT GATE"]
	for i: int in range(_route_cards.size()):
		if i < choices.size() and choices[i] is Dictionary:
			var choice: Dictionary = choices[i] as Dictionary
			var room_type: String = str(choice.get("room_type", "combat"))
			var display_name: String = str(choice.get("display_name", room_type.capitalize()))
			var description: String = str(choice.get("description", ""))
			var rarity: String = str(choice.get("rarity", "common")).to_upper()
			var icon: String = str(choice.get("icon", "?"))
			_route_cards[i].visible = true
			_apply_panel_style(_route_cards[i], Color(0.028, 0.020, 0.016, 0.94), _color_for_room_type(room_type), 2, 8)
			_route_labels[i].text = "%s\n%s  %s\n%s\n%s" % [slot_names[i], icon, display_name.to_upper(), rarity, description]
		else:
			_route_cards[i].visible = false

func _update_summary(data: Dictionary, phase: String) -> void:
	if phase != "RUN COMPLETE":
		_summary_panel.visible = false
		return
	_summary_panel.visible = true
	_summary_title.text = "RUN COMPLETE"
	_summary_body.text = "Rooms cleared: %d / %d\nRewards taken: %s\nBonus Ash Sigils: %d\n\nPress E to return to the Threshold Nave." % [
		int(data.get("completed", 0)),
		int(data.get("total", 0)),
		str(data.get("rewards", [])),
		int(data.get("bonus_sigils", 0)),
	]

func _focus_meta_text(kind: String, reward_id: String) -> String:
	match kind:
		"reward":
			return "BOON · ONE-TIME CLAIM" if reward_id != "" else "REWARD"
		"fountain":
			return "RECOVERY · ONE USE"
		"forge":
			return "FORGE · PLACEHOLDER"
		"shop":
			return "MERCHANT · PLACEHOLDER"
	return "INTERACTABLE"

func _focus_body_text(kind: String, description: String, payload: Dictionary) -> String:
	var action: String = "Press E to use."
	match kind:
		"reward":
			action = "Press E to claim this boon. The other boons vanish."
		"fountain":
			action = "Press E to drink and restore health."
		"forge":
			action = "Press E to acknowledge the cold forge. Weapon mutation comes later."
		"shop":
			action = "Press E to pass the silent merchant. Economy comes later."
	return "%s\n\n%s" % [description, action]

func _make_panel(node_name: String, pos: Vector2, size: Vector2, bg: Color, border: Color, border_width: int, radius: int) -> Panel:
	var panel: Panel = Panel.new()
	panel.name = node_name
	panel.position = pos
	panel.size = size
	_root.add_child(panel)
	_apply_panel_style(panel, bg, border, border_width, radius)
	return panel

func _apply_panel_style(panel: Panel, bg: Color, border: Color, border_width: int, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)

func _make_label(node_name: String, parent: Control, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.position = pos
	label.size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _color_for_kind(kind: String) -> Color:
	match kind:
		"reward":
			return Color(0.52, 0.72, 0.34, 0.95)
		"fountain":
			return Color(0.28, 0.62, 0.86, 0.95)
		"forge":
			return Color(0.90, 0.36, 0.12, 0.95)
		"shop":
			return Color(0.62, 0.36, 0.86, 0.95)
	return Color(0.75, 0.68, 0.56, 0.95)

func _color_for_room_type(room_type: String) -> Color:
	match room_type:
		"combat":
			return Color(0.80, 0.30, 0.12, 0.95)
		"elite_combat":
			return Color(0.90, 0.12, 0.10, 0.95)
		"reward":
			return Color(0.52, 0.72, 0.34, 0.95)
		"fountain":
			return Color(0.28, 0.62, 0.86, 0.95)
		"forge":
			return Color(0.90, 0.36, 0.12, 0.95)
		"shop":
			return Color(0.62, 0.36, 0.86, 0.95)
	return Color(0.68, 0.58, 0.44, 0.95)
