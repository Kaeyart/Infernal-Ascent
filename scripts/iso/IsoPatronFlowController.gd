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
	_ensure_manager()
	queue_redraw()

func set_manager(external_manager: PatronRunManager) -> void:
	if external_manager == null:
		return
	if manager == external_manager:
		return

	var old_manager: PatronRunManager = manager
	if old_manager != null:
		_disconnect_manager(old_manager)

	manager = external_manager
	_bind_manager(manager)

	if old_manager != null and old_manager != manager and old_manager.get_parent() == self:
		old_manager.queue_free()

	last_status = "Patron state linked to shared room manager. " + manager.describe_run_lock()
	queue_redraw()

func get_manager() -> PatronRunManager:
	_ensure_manager()
	return manager

func clear_runtime_elements() -> void:
	_clear_altar()
	_clear_gates()
	_gate_choice_in_progress = false
	last_status = "Room reset. Defeat enemies to call a patron."
	queue_redraw()

func _ensure_manager() -> void:
	if manager == null:
		manager = PatronRunManager.new()
		manager.name = "PatronRunManager"
		add_child(manager)
	_bind_manager(manager)

func _bind_manager(target_manager: PatronRunManager) -> void:
	if target_manager == null:
		return
	if not target_manager.patron_lock_changed.is_connected(_on_patron_lock_changed):
		target_manager.patron_lock_changed.connect(_on_patron_lock_changed)
	if not target_manager.boon_claimed.is_connected(_on_manager_boon_claimed):
		target_manager.boon_claimed.connect(_on_manager_boon_claimed)

func _disconnect_manager(target_manager: PatronRunManager) -> void:
	if target_manager == null:
		return
	if target_manager.patron_lock_changed.is_connected(_on_patron_lock_changed):
		target_manager.patron_lock_changed.disconnect(_on_patron_lock_changed)
	if target_manager.boon_claimed.is_connected(_on_manager_boon_claimed):
		target_manager.boon_claimed.disconnect(_on_manager_boon_claimed)

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
	_ensure_manager()
	_clear_gates()
	_clear_altar()

	var boon: Dictionary = manager.create_current_boon_offer()
	var patron_id: String = str(boon.get("patron_id", manager.choose_reward_patron_after_clear()))
	_spawn_boon_altar(patron_id, boon)
	last_status = "Room cleared. %s manifests a boon." % PatronRegistry.get_patron_name(patron_id)
	queue_redraw()

func reset_patron_run() -> void:
	_ensure_manager()
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
	_ensure_manager()
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
	_ensure_manager()
	manager.claim_boon(patron_id, boon)
	_spawn_choice_gates()

func _on_choice_gate_selected(choice_data: Dictionary) -> void:
	if _gate_choice_in_progress:
		return
	_ensure_manager()
	_gate_choice_in_progress = true
	manager.commit_gate_choice(choice_data)
	last_status = "Next path selected: %s. Room loop will continue. %s" % [
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
	var font: Font = ThemeDB.fallback_font
	var panel_rect: Rect2 = Rect2(Vector2(24.0, 20.0), Vector2(650.0, 100.0))
	draw_rect(panel_rect, Color(0.025, 0.02, 0.018, 0.76), true)
	draw_rect(panel_rect, Color("#c59254"), false, 2.0)
	draw_string(font, Vector2(42.0, 48.0), "Patron Flow", HORIZONTAL_ALIGNMENT_LEFT, 610.0, 18, Color("#f1dbc0"))
	draw_string(font, Vector2(42.0, 74.0), last_status, HORIZONTAL_ALIGNMENT_LEFT, 610.0, 14, Color("#d0b896"))

	var lock_text: String = "No manager."
	if manager != null:
		lock_text = manager.describe_run_lock()
	draw_string(font, Vector2(42.0, 96.0), lock_text, HORIZONTAL_ALIGNMENT_LEFT, 610.0, 13, Color("#c9a56f"))

	if debug_input_enabled and auto_show_help:
		draw_string(font, Vector2(42.0, 118.0), "Debug: C = simulate clear, R = reset patrons, E = interact", HORIZONTAL_ALIGNMENT_LEFT, 610.0, 13, Color("#8f806c"))

func _key_pressed_once(key: Key, was_down: bool) -> bool:
	var down: bool = Input.is_physical_key_pressed(key)
	return down and not was_down
