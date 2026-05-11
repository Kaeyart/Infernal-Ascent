extends Node2D
class_name IsoRoomLocalLoopController

@export var rooms_until_run_end: int = 5
@export var restart_key_enabled: bool = true
@export var print_debug: bool = true

var shared_patron_manager: PatronRunManager = null
var runtime_adapter: IsoAuthoredRoomRuntimeAdapter = null
var rooms_completed: int = 0
var current_room_cycle: int = 1
var run_finished: bool = false
var _advance_in_progress: bool = false
var _t_down_previous: bool = false

var hud_layer: CanvasLayer = null
var hud_label: Label = null

func _ready() -> void:
	_setup_hud()
	_create_shared_manager()
	call_deferred("_wire_room_deferred")

func _process(_delta: float) -> void:
	if restart_key_enabled:
		if _key_pressed_once(KEY_T, _t_down_previous):
			_t_down_previous = true
			start_new_local_run()
		else:
			_t_down_previous = Input.is_physical_key_pressed(KEY_T)
	_update_hud()

func start_new_local_run() -> void:
	rooms_completed = 0
	current_room_cycle = 1
	run_finished = false
	_advance_in_progress = false
	if shared_patron_manager != null:
		shared_patron_manager.reset_run()
	if runtime_adapter != null:
		runtime_adapter.reset_runtime_for_next_room()
	_wire_patron_flow_signals()
	_debug("Local run restarted.")

func _create_shared_manager() -> void:
	shared_patron_manager = PatronRunManager.new()
	shared_patron_manager.name = "LocalSharedPatronRunManager"
	add_child(shared_patron_manager)
	if not shared_patron_manager.gate_choice_committed.is_connected(_on_gate_choice_committed):
		shared_patron_manager.gate_choice_committed.connect(_on_gate_choice_committed)
	if not shared_patron_manager.patron_lock_changed.is_connected(_on_patron_lock_changed):
		shared_patron_manager.patron_lock_changed.connect(_on_patron_lock_changed)

func _wire_room_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	runtime_adapter = _find_or_create_adapter()
	if runtime_adapter == null:
		push_error("[IsoLocalLoop] RuntimeAdapter missing and could not be created.")
		return

	runtime_adapter.set_shared_patron_manager(shared_patron_manager)
	_wire_patron_flow_signals()
	_debug("Active room local loop wired. Use this scene directly.")

func _find_or_create_adapter() -> IsoAuthoredRoomRuntimeAdapter:
	var found: Node = get_parent().find_child("RuntimeAdapter", true, false)
	if found is IsoAuthoredRoomRuntimeAdapter:
		return found as IsoAuthoredRoomRuntimeAdapter
	var adapter: IsoAuthoredRoomRuntimeAdapter = IsoAuthoredRoomRuntimeAdapter.new()
	adapter.name = "RuntimeAdapter"
	get_parent().add_child(adapter)
	return adapter

func _wire_patron_flow_signals() -> void:
	var flow: IsoPatronFlowController = _find_patron_flow()
	if flow == null:
		return
	flow.set_manager(shared_patron_manager)
	if not flow.next_room_choice_selected.is_connected(_on_flow_choice_selected):
		flow.next_room_choice_selected.connect(_on_flow_choice_selected)
	if not flow.patron_run_locked.is_connected(_on_patron_run_locked):
		flow.patron_run_locked.connect(_on_patron_run_locked)

func _find_patron_flow() -> IsoPatronFlowController:
	var root: Node = get_parent()
	var nodes: Array[Node] = []
	_collect_nodes(root, nodes)
	for node: Node in nodes:
		if node is IsoPatronFlowController:
			return node as IsoPatronFlowController
	return null

func _on_flow_choice_selected(choice_data: Dictionary) -> void:
	_debug("Choice signal received from PatronFlow.")
	_advance_same_scene(choice_data)

func _on_gate_choice_committed(choice_data: Dictionary) -> void:
	_debug("Choice signal received from shared PatronRunManager.")
	_advance_same_scene(choice_data)

func _advance_same_scene(choice_data: Dictionary) -> void:
	if run_finished:
		return
	if _advance_in_progress:
		_debug("Advance ignored; already advancing.")
		return

	_advance_in_progress = true
	rooms_completed += 1

	var choice_name: String = str(choice_data.get("display_name", "Unknown"))
	_debug("Choice selected: %s. Completed %d/%d." % [choice_name, rooms_completed, rooms_until_run_end])

	if rooms_completed >= rooms_until_run_end:
		_finish_local_run()
		return

	current_room_cycle += 1
	call_deferred("_reset_room_cycle_deferred")

func _reset_room_cycle_deferred() -> void:
	await get_tree().process_frame
	if runtime_adapter != null:
		runtime_adapter.reset_runtime_for_next_room()
	_wire_patron_flow_signals()
	_advance_in_progress = false
	_debug("Same room reset for cycle %d. Enemies respawned." % current_room_cycle)

func _finish_local_run() -> void:
	run_finished = true
	_debug("Local test run complete. Press T to restart.")
	_update_hud()

func _on_patron_lock_changed(is_locked: bool, patrons: Array) -> void:
	if is_locked:
		_debug("Patron run locked: " + str(patrons))

func _on_patron_run_locked(patrons: Array) -> void:
	_debug("PatronFlow lock signal: " + str(patrons))

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "LocalLoopHUD"
	add_child(hud_layer)
	hud_label = Label.new()
	hud_label.name = "LocalLoopStatus"
	hud_label.position = Vector2(18.0, 150.0)
	hud_label.size = Vector2(780.0, 150.0)
	hud_layer.add_child(hud_label)

func _update_hud() -> void:
	if hud_label == null:
		return

	var patron_text: String = "No patron manager."
	if shared_patron_manager != null:
		patron_text = shared_patron_manager.describe_run_lock()

	var status_text: String = "Running"
	if run_finished:
		status_text = "Run complete. Press T to restart."

	hud_label.text = "Active Room Local Loop V1\nScene: combat_ash_intake_hall_01_iso.tscn\nCycle: %d | Completed: %d/%d | %s\n%s\nT = restart local loop" % [
		current_room_cycle,
		rooms_completed,
		rooms_until_run_end,
		status_text,
		patron_text
	]

func _collect_nodes(root: Node, out_nodes: Array[Node]) -> void:
	for child: Node in root.get_children():
		out_nodes.append(child)
		_collect_nodes(child, out_nodes)

func _key_pressed_once(key: Key, was_down: bool) -> bool:
	var down: bool = Input.is_physical_key_pressed(key)
	return down and not was_down

func _debug(message: String) -> void:
	if print_debug:
		print("[IsoLocalLoop] " + message)
