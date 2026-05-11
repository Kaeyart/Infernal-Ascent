extends Node2D

const HubScene := preload("res://scenes/hub/HubV2.tscn")
const CombatRoomScene := preload("res://scenes/run/CombatRoom.tscn")
const RewardRoomScene := preload("res://scenes/run/RewardRoom.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const DefaultWeapon := preload("res://data/weapons/PenitentBlade.tres")

@onready var world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UILayer

var current_scene: Node = null
var hud: Node = null

func _ready() -> void:
	_ensure_input_actions()

	if GameState.selected_weapon == null:
		GameState.selected_weapon = DefaultWeapon

	hud = HUDScene.instantiate()
	ui_layer.add_child(hud)

	load_hub()

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")

	if hud and player and hud.has_method("set_player"):
		hud.set_player(player)

func start_run() -> void:
	RunState.start_run()
	load_room_by_type(RunState.current_room_type)

func load_hub() -> void:
	_clear_world()
	RunState.end_run()

	current_scene = HubScene.instantiate()
	world.add_child(current_scene)

	if current_scene.has_signal("enter_run_requested"):
		current_scene.enter_run_requested.connect(start_run)

func load_room_by_type(room_type: String) -> void:
	_clear_world()

	var scene_to_load: PackedScene = CombatRoomScene
	var resolved_room_type: String = room_type

	match room_type:
		RunState.ROOM_COMBAT, RunState.ROOM_ELITE, RunState.ROOM_MINIBOSS, RunState.ROOM_BOSS:
			scene_to_load = CombatRoomScene

		RunState.ROOM_UPGRADE, RunState.ROOM_FORGE, RunState.ROOM_SHRINE:
			scene_to_load = CombatRoomScene

		RunState.ROOM_SHOP, RunState.ROOM_FOUNTAIN:
			scene_to_load = RewardRoomScene

		_:
			push_warning("Unknown room_type '%s'. Falling back to combat." % room_type)
			resolved_room_type = RunState.ROOM_COMBAT
			scene_to_load = CombatRoomScene

	current_scene = scene_to_load.instantiate()

	if current_scene == null:
		push_error("Failed to instantiate scene for room_type '%s'." % resolved_room_type)
		return

	if current_scene.has_method("set_room_type"):
		current_scene.set_room_type(resolved_room_type)
	else:
		push_warning("Loaded room has no set_room_type() method: %s" % current_scene.name)

	world.add_child(current_scene)

	if current_scene.has_signal("return_to_hub_requested"):
		current_scene.return_to_hub_requested.connect(load_hub)

	if current_scene.has_signal("room_choice_requested"):
		current_scene.room_choice_requested.connect(_on_room_choice_requested)

	if current_scene.has_signal("reward_room_requested"):
		current_scene.reward_room_requested.connect(_on_legacy_reward_room_requested)

func load_combat_room() -> void:
	if not RunState.in_run:
		RunState.start_run()

	RunState.current_room_type = RunState.ROOM_COMBAT
	load_room_by_type(RunState.ROOM_COMBAT)

func load_reward_room(reward_type: String = "upgrade") -> void:
	if not RunState.in_run:
		RunState.start_run()
		RunState.current_room_type = reward_type

	load_room_by_type(reward_type)

func _on_room_choice_requested(room_type: String) -> void:
	print("ROOM CHOICE SELECTED: ", room_type)
	RunState.choose_room(room_type)
	load_room_by_type(room_type)

func _on_legacy_reward_room_requested(reward_type: String) -> void:
	RunState.choose_room(reward_type)
	load_room_by_type(reward_type)

func _clear_world() -> void:
	for child in world.get_children():
		child.queue_free()

func _ensure_input_actions() -> void:
	_add_key_action("move_up", [KEY_W])
	_add_key_action("move_down", [KEY_S])
	_add_key_action("move_left", [KEY_A])
	_add_key_action("move_right", [KEY_D])

	_remove_key_from_action("move_up", KEY_UP)
	_remove_key_from_action("move_down", KEY_DOWN)
	_remove_key_from_action("move_left", KEY_LEFT)
	_remove_key_from_action("move_right", KEY_RIGHT)

	_add_key_action("dash", [KEY_SHIFT])
	_add_key_action("heavy_attack", [KEY_R])
	_add_key_action("skill_q", [KEY_Q])
	_add_key_action("ultimate", [KEY_F])
	_add_key_action("interact", [KEY_E])
	_add_key_action("light_attack", [KEY_SPACE])

	_add_mouse_action("light_attack", MOUSE_BUTTON_LEFT)
	_add_mouse_action("heavy_attack", MOUSE_BUTTON_RIGHT)

func _remove_key_from_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		return

	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and ev.keycode == key:
			InputMap.action_erase_event(action_name, ev)
			return

func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for key in keys:
		var already_exists := false

		for ev in InputMap.action_get_events(action_name):
			if ev is InputEventKey and ev.keycode == key:
				already_exists = true

		if not already_exists:
			var event := InputEventKey.new()
			event.keycode = key
			InputMap.action_add_event(action_name, event)

func _add_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var already_exists := false

	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventMouseButton and ev.button_index == button:
			already_exists = true

	if not already_exists:
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action_name, event)
