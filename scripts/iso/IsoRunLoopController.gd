extends Node2D
class_name IsoRunLoopController

@export var room_scene_paths: PackedStringArray = PackedStringArray([
	"res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn"
])

@export var rooms_until_run_end: int = 5
@export var auto_start: bool = true
@export var shared_manager_name: String = "SharedPatronRunManager"
@export var current_room_parent_name: String = "CurrentRoomHost"
@export var restart_key_enabled: bool = true
@export var print_loop_debug: bool = true

var shared_patron_manager: PatronRunManager = null
var current_room: Node = null
var current_room_host: Node2D = null
var current_room_number: int = 0
var rooms_completed: int = 0
var last_choice_data: Dictionary = {}
var last_status: String = "Room loop ready."
var run_finished: bool = false
var _t_down_previous: bool = false
var _advance_in_progress: bool = false

var hud_layer: CanvasLayer = null
var hud_label: Label = null

func _ready() -> void:
	_setup_hud()
	_create_shared_patron_manager()
	_ensure_room_host()

	if auto_start:
		start_new_run()

func _process(_delta: float) -> void:
	if restart_key_enabled:
		if _key_pressed_once(KEY_T, _t_down_previous):
			_t_down_previous = true
			start_new_run()
		else:
			_t_down_previous = Input.is_physical_key_pressed(KEY_T)

	_update_hud()

func start_new_run() -> void:
	rooms_completed = 0
	current_room_number = 0
	last_choice_data.clear()
	run_finished = false
	_advance_in_progress = false

	if shared_patron_manager != null:
		shared_patron_manager.reset_run()

	last_status = "New iso run started."
	_load_next_room()

func _create_shared_patron_manager() -> void:
	shared_patron_manager = PatronRunManager.new()
	shared_patron_manager.name = shared_manager_name
	add_child(shared_patron_manager)
	shared_patron_manager.patron_lock_changed.connect(_on_patron_lock_changed)

	if not shared_patron_manager.gate_choice_committed.is_connected(_on_shared_gate_choice_committed):
		shared_patron_manager.gate_choice_committed.connect(_on_shared_gate_choice_committed)

func _ensure_room_host() -> void:
	current_room_host = get_node_or_null(current_room_parent_name) as Node2D
	if current_room_host == null:
		current_room_host = Node2D.new()
		current_room_host.name = current_room_parent_name
		add_child(current_room_host)
		move_child(current_room_host, 0)

func _load_next_room() -> void:
	if run_finished:
		return

	if room_scene_paths.is_empty():
		last_status = "No room scene paths configured."
		push_warning("[IsoRunLoop] No room scene paths configured.")
		return

	_unload_current_room()

	current_room_number += 1
	var scene_path: String = _choose_room_scene_path()
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		last_status = "Failed to load room: " + scene_path
		push_error("[IsoRunLoop] Failed to load room: " + scene_path)
		return

	current_room = packed_scene.instantiate()
	current_room.name = "RunRoom_%02d" % current_room_number

	# Critical: the room/adapter reads this before or during _ready().
	current_room.set_meta("shared_patron_manager", shared_patron_manager)
	current_room.set_meta("iso_run_loop_controller", self)

	current_room_host.add_child(current_room)

	last_status = "Loaded room %d: %s" % [current_room_number, scene_path]
	_debug("Loaded room %d from %s" % [current_room_number, scene_path])
	call_deferred("_wire_current_room_deferred")

func _choose_room_scene_path() -> String:
	if room_scene_paths.size() == 1:
		return room_scene_paths[0]

	var index: int = (current_room_number - 1) % room_scene_paths.size()
	return room_scene_paths[index]

func _unload_current_room() -> void:
	if current_room != null and is_instance_valid(current_room):
		current_room_host.remove_child(current_room)
		current_room.queue_free()
	current_room = null

func _wire_current_room_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if current_room == null or not is_instance_valid(current_room):
		return

	var adapter: Node = current_room.find_child("RuntimeAdapter", true, false)
	if adapter == null:
		adapter = IsoAuthoredRoomRuntimeAdapter.new()
		adapter.name = "RuntimeAdapter"
		current_room.add_child(adapter)
		await get_tree().process_frame
		await get_tree().process_frame

	var flows: Array[IsoPatronFlowController] = _find_patron_flows(current_room)

	if flows.is_empty():
		var patron_flow: IsoPatronFlowController = IsoPatronFlowController.new()
		patron_flow.name = "PatronFlow"
		current_room.add_child(patron_flow)
		flows.append(patron_flow)

	for patron_flow: IsoPatronFlowController in flows:
		patron_flow.set_manager(shared_patron_manager)
		if not patron_flow.next_room_choice_selected.is_connected(_on_next_room_choice_selected):
			patron_flow.next_room_choice_selected.connect(_on_next_room_choice_selected)
		if not patron_flow.patron_run_locked.is_connected(_on_patron_run_locked):
			patron_flow.patron_run_locked.connect(_on_patron_run_locked)

	_debug("Linked %d PatronFlow node(s) to shared manager." % flows.size())

	_advance_in_progress = false
	last_status = "Room %d wired. Defeat enemies, claim boon, choose gate." % current_room_number
	_debug("Room %d wired. Advance guard reset." % current_room_number)
	_update_hud()

func _find_patron_flows(root: Node) -> Array[IsoPatronFlowController]:
	var result: Array[IsoPatronFlowController] = []
	var all_nodes: Array[Node] = []
	_collect_nodes(root, all_nodes)

	for node: Node in all_nodes:
		if node is IsoPatronFlowController:
			result.append(node as IsoPatronFlowController)

	return result

func _on_next_room_choice_selected(choice_data: Dictionary) -> void:
	_debug("Advance requested from PatronFlow signal.")
	_advance_from_choice(choice_data)

func _on_shared_gate_choice_committed(choice_data: Dictionary) -> void:
	_debug("Advance requested from shared manager gate_choice_committed signal.")
	_advance_from_choice(choice_data)

func _advance_from_choice(choice_data: Dictionary) -> void:
	if run_finished:
		return

	if _advance_in_progress:
		_debug("Advance ignored because one is already in progress.")
		return

	_advance_in_progress = true
	last_choice_data = choice_data.duplicate(true)
	rooms_completed += 1

	var choice_name: String = str(choice_data.get("display_name", "Unknown"))
	last_status = "Choice selected: %s. Loading next room... %d/%d complete." % [
		choice_name,
		rooms_completed,
		rooms_until_run_end
	]

	_debug(last_status)

	if rooms_completed >= rooms_until_run_end:
		call_deferred("_finish_test_run")
	else:
		call_deferred("_load_next_room")

func _finish_test_run() -> void:
	run_finished = true
	_unload_current_room()
	last_status = "Test run complete. Press T to start a new loop."
	_update_hud()
	print("[IsoRunLoop] Test run complete.")

func _on_patron_lock_changed(is_locked: bool, patrons: Array) -> void:
	if is_locked:
		print("[IsoRunLoop] Patron lock persisted across loop: " + str(patrons))

func _on_patron_run_locked(patrons: Array) -> void:
	print("[IsoRunLoop] Patron run locked: " + str(patrons))

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "LoopHUD"
	add_child(hud_layer)

	hud_label = Label.new()
	hud_label.name = "LoopStatus"
	hud_label.position = Vector2(18.0, 16.0)
	hud_label.size = Vector2(880.0, 190.0)
	hud_layer.add_child(hud_label)

func _update_hud() -> void:
	if hud_label == null:
		return

	var patron_text: String = "No patron manager."
	if shared_patron_manager != null:
		patron_text = shared_patron_manager.describe_run_lock()

	var choice_text: String = "Last choice: none"
	if not last_choice_data.is_empty():
		choice_text = "Last choice: %s" % str(last_choice_data.get("display_name", "Unknown"))

	hud_label.text = "Iso V2 Room Loop V1.2\\nRoom: %d | Completed: %d/%d\\n%s\\n%s\\n%s\\nT = restart loop" % [
		current_room_number,
		rooms_completed,
		rooms_until_run_end,
		last_status,
		patron_text,
		choice_text
	]

func _collect_nodes(root: Node, out_nodes: Array[Node]) -> void:
	for child: Node in root.get_children():
		out_nodes.append(child)
		_collect_nodes(child, out_nodes)

func _key_pressed_once(key: Key, was_down: bool) -> bool:
	var down: bool = Input.is_physical_key_pressed(key)
	return down and not was_down

func _debug(message: String) -> void:
	if print_loop_debug:
		print("[IsoRunLoop] " + message)
