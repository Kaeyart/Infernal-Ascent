extends Node2D
class_name IsoPatronFlowController

signal patron_boon_claimed(patron_id: String, boon: Dictionary)
signal next_room_choice_selected(choice_data: Dictionary)
signal patron_run_locked(patrons: Array)

@export var debug_input_enabled: bool = true
@export var auto_show_help: bool = true
@export var altar_position: Vector2 = Vector2(640.0, 384.0)
@export var gate_left_position: Vector2 = Vector2(430.0, 220.0)
@export var gate_center_position: Vector2 = Vector2(640.0, 170.0)
@export var gate_right_position: Vector2 = Vector2(850.0, 220.0)

var manager: PatronRunManager = null
var current_altar: PatronBoonAltar = null
var active_gates: Array[PatronChoiceGate] = []
var last_status: String = "Clear a room to call the first patron."
var _c_down_previous: bool = false
var _r_down_previous: bool = false
var _gate_choice_in_progress: bool = false

func _ready() -> void:
	manager = PatronRunManager.new()
	manager.name = "PatronRunManager"
	add_child(manager)
	manager.patron_lock_changed.connect(_on_patron_lock_changed)
	manager.boon_claimed.connect(_on_manager_boon_claimed)
	queue_redraw()

func _process(_delta: float) -> void:
	if debug_input_enabled:
		if _key_pressed_once(KEY_C, _c_down_previous):
			_c_down_previous = true
			report_room_cleared()
		else:
			_c_down_previous = Input.is_physical_key_pressed(KEY_C)
		if _key_pressed_once(KEY_R, _r_down_previous):
			_r_down_previous = true
			reset_patron_run()
		else:
			_r_down_previous = Input.is_physical_key_pressed(KEY_R)
	queue_redraw()

func report_room_cleared() -> void:
	_clear_gates()
	_clear_altar()
	var boon: Dictionary = manager.create_current_boon_offer()
	var patron_id: String = str(boon.get("patron_id", manager.choose_reward_patron_after_clear()))
	_spawn_boon_altar(patron_id, boon)
	last_status = "Room cleared. %s manifests a boon." % PatronRegistry.get_patron_name(patron_id)
	queue_redraw()

func reset_patron_run() -> void:
	_clear_gates()
	_clear_altar()
	manager.reset_run()
	last_status = "Patron run reset. First clear will call a random witness."
	queue_redraw()

func _spawn_boon_altar(patron_id: String, boon: Dictionary) -> void:
	current_altar = PatronBoonAltar.new()
	current_altar.name = "PatronBoonAltar_" + patron_id
	current_altar.position = altar_position
	add_child(current_altar)
	current_altar.setup(patron_id, boon)
	current_altar.boon_claimed.connect(_on_boon_altar_claimed)

func _spawn_choice_gates() -> void:
	_clear_gates()
	_gate_choice_in_progress = false
	var choices: Array[Dictionary] = manager.build_exit_choices()
	var positions: Array[Vector2] = [gate_left_position, gate_center_position, gate_right_position]
	for i: int in range(min(choices.size(), positions.size())):
		var gate: PatronChoiceGate = PatronChoiceGate.new()
		gate.name = "ChoiceGate_" + str(i + 1)
		gate.position = positions[i]
		add_child(gate)
		gate.setup(choices[i])
		gate.choice_selected.connect(_on_choice_gate_selected)
		active_gates.append(gate)
	last_status = "Choose the next room physically. " + manager.describe_run_lock()

func _on_boon_altar_claimed(patron_id: String, boon: Dictionary) -> void:
	manager.claim_boon(patron_id, boon)
	_spawn_choice_gates()

func _on_choice_gate_selected(choice_data: Dictionary) -> void:
	# Multiple gates can receive E in the same frame in the standalone test scene
	# because there may be no player body to limit interaction range. Only the
	# first gate signal should count. This prevents accidental third-patron
	# reservations and makes the two-patron lock deterministic.
	if _gate_choice_in_progress:
		return
	_gate_choice_in_progress = true
	manager.commit_gate_choice(choice_data)
	last_status = "Next path selected: %s. Clear the next room to receive its reward. %s" % [
		str(choice_data.get("display_name", "Unknown")),
		manager.describe_run_lock()
	]
	emit_signal("next_room_choice_selected", choice_data.duplicate(true))
	_clear_gates()
	queue_redraw()

func _on_manager_boon_claimed(patron_id: String, boon: Dictionary) -> void:
	emit_signal("patron_boon_claimed", patron_id, boon.duplicate(true))

func _on_patron_lock_changed(is_locked: bool, patrons: Array) -> void:
	if is_locked:
		emit_signal("patron_run_locked", patrons.duplicate())

func _clear_altar() -> void:
	if current_altar != null and is_instance_valid(current_altar):
		current_altar.queue_free()
	current_altar = null

func _clear_gates() -> void:
	for gate: PatronChoiceGate in active_gates:
		if gate != null and is_instance_valid(gate):
			gate.queue_free()
	active_gates.clear()

func _draw() -> void:
	_draw_demo_floor()
	var font: Font = ThemeDB.fallback_font
	var panel_rect: Rect2 = Rect2(Vector2(24.0, 20.0), Vector2(620.0, 92.0))
	draw_rect(panel_rect, Color(0.025, 0.02, 0.018, 0.86), true)
	draw_rect(panel_rect, Color("#c59254"), false, 2.0)
	draw_string(font, Vector2(42.0, 48.0), "Patron Choice + Lock V1", HORIZONTAL_ALIGNMENT_LEFT, 580.0, 18, Color("#f1dbc0"))
	draw_string(font, Vector2(42.0, 74.0), last_status, HORIZONTAL_ALIGNMENT_LEFT, 580.0, 14, Color("#d0b896"))
	draw_string(font, Vector2(42.0, 96.0), manager.describe_run_lock(), HORIZONTAL_ALIGNMENT_LEFT, 580.0, 13, Color("#c9a56f"))
	if debug_input_enabled and auto_show_help:
		draw_string(font, Vector2(42.0, 118.0), "Debug: C = simulate room clear, R = reset run, E = interact", HORIZONTAL_ALIGNMENT_LEFT, 580.0, 13, Color("#8f806c"))

func _draw_demo_floor() -> void:
	var center: Vector2 = Vector2(640.0, 400.0)
	var floor_color: Color = Color(0.08, 0.075, 0.07, 0.62)
	var line_color: Color = Color(0.45, 0.34, 0.24, 0.32)
	for y: int in range(-3, 4):
		for x: int in range(-5, 6):
			var tile_center: Vector2 = center + Vector2(float(x - y) * 32.0, float(x + y) * 16.0)
			var diamond: PackedVector2Array = PackedVector2Array([
				tile_center + Vector2(0.0, -16.0),
				tile_center + Vector2(32.0, 0.0),
				tile_center + Vector2(0.0, 16.0),
				tile_center + Vector2(-32.0, 0.0)
			])
			draw_colored_polygon(diamond, floor_color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), line_color, 1.0)

func _key_pressed_once(key: Key, was_down: bool) -> bool:
	var down: bool = Input.is_physical_key_pressed(key)
	return down and not was_down
