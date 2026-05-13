extends Node2D
const PERMANENT_UPGRADE_SCRIPT: Script = preload("res://scripts/run/PermanentUpgradeData.gd")
const SAVE_GAME_SCRIPT: Script = preload("res://scripts/run/SaveGameData.gd")
const INFERNAL_AUDIO_SCRIPT: Script = preload("res://scripts/audio/InfernalAudio.gd")
## V14 — Run Flow Consistency Pass.
## V19 — Reward Consistency Pass extends the existing loop with a standardized temporary reward catalogue.
## V20 — Demo Run Length Lock makes the run reach a predictable boss-antechamber placeholder after four rooms.
## V21 — Fountain / Shop / Forge Functional Pass makes support rooms useful instead of placeholders.
## V22.2 — Presentation cleanup removes residual debug overlays and anchors route/boss gates inside the room.
## V23 — Boss Arena V1 adds the Sentencing Furnace placeholder arena.
## V24 — Ash Warden Boss V1 replaces the placeholder seal with a playable boss fight.
## V25 — Demo Victory and Death Loop records clean victory/death outcomes and returns to hub.
## V28 — Save System V1 persists economy, upgrades, last run, best depth, and boss flags.
## Owns the local Circle 0 demo run state machine. This script intentionally does not add
## new enemies, art, boss logic, sound, or save logic.

enum RunPhase {
	HUB,
	RUN_START,
	ROOM_INTRO,
	COMBAT,
	ROOM_CLEAR,
	ROUTE_CHOICE,
	REWARD,
	FOUNTAIN,
	SHOP,
	FORGE,
	BOSS_LOCKED_PLACEHOLDER,
	BOSS_ARENA_PLACEHOLDER,
	BOSS,
	RUN_VICTORY,
	RUN_DEATH,
	RETURN_TO_HUB,
}

@export var rooms_until_run_end: int = 4
@export var restart_key_enabled: bool = true
@export var return_to_hub_enabled: bool = true
@export var hub_scene_path: String = "res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn"
@export var ash_sigils_per_completed_run: int = 1
@export var print_debug: bool = false
@export var auto_start_run_on_ready: bool = true

@export_category("V20 Demo Length Lock")
@export var demo_run_length_locked: bool = true
@export var demo_rooms_before_boss: int = 4
@export var boss_antechamber_variant: String = "boss_antechamber"
@export var boss_placeholder_completes_run: bool = true

@export_category("V23 Boss Arena")
@export var boss_arena_enabled_v23: bool = true
@export var boss_arena_variant: String = "sentencing_furnace"
@export var boss_placeholder_max_health: int = 100
@export var boss_exit_position_offset: Vector2 = Vector2(0.0, -170.0)

@export_category("V24 Ash Warden Boss")
@export var ash_warden_boss_enabled_v24: bool = true
@export var ash_warden_boss_script_path: String = "res://scripts/iso/AshWardenBoss.gd"
@export var ash_warden_max_health_v24: int = 90
@export var ash_warden_boss_can_end_run_on_player_death: bool = true
@export var force_demo_route_pattern: bool = true

@export_category("V25 Demo Victory / Death")
@export var demo_victory_ash_sigils: int = 4
@export var demo_death_base_ash_sigils: int = 1
@export var death_keeps_bonus_sigils: bool = true
@export var show_outcome_intro_panel: bool = true

@export_category("V21 Support Rooms")
@export var support_rooms_functional: bool = true
@export var fountain_heal_ratio_v21: float = 0.65
@export var starting_run_ash: int = 2
@export var run_ash_per_completed_combat: int = 1
@export var shop_heal_cost: int = 1
@export var shop_damage_cost: int = 2
@export var shop_mystery_boon_cost: int = 2

@export_category("V10 Route Loop")
@export var route_choice_enabled: bool = true
@export var gate_spawn_delay: float = 0.35
@export var reward_choices_per_room: int = 3
@export var heal_on_fountain_ratio: float = 0.55
@export var show_route_debug_labels: bool = false
@export var force_first_choice_reward: bool = true

@export_category("V11/V12/V13 Circle 0 Zone")
@export var enable_circle0_zone_variants: bool = true
@export var show_room_intro_toast: bool = true
@export var use_v12_run_hud: bool = true # Compatibility flag: true instantiates Circle0RunHUD / InfernalUIRoot.
@export var route_gate_room_variant: String = "route_gate_crossing"
@export var combat_variants: Array[String] = ["ash_intake_hall", "cinder_drain", "furnace_vestibule", "chain_reservoir", "ember_sorting_floor", "penitent_crossing"]
@export var elite_combat_variant_offset: int = 2

var shared_patron_manager: PatronRunManager = null
# T-008 boon reward pool state
var run_boon_state: Node = null
var runtime_adapter: IsoAuthoredRoomRuntimeAdapter = null
var rooms_completed: int = 0
var current_room_cycle: int = 1
var current_room_type: String = "combat"
var current_room_variant: String = "ash_intake_hall"
var current_depth: int = 1
var combat_rooms_cleared: int = 0
var reward_rooms_completed: int = 0
var fountain_rooms_completed: int = 0
var forge_rooms_seen: int = 0
var shop_rooms_seen: int = 0
var run_bonus_ash_sigils: int = 0
var heal_on_room_clear_amount: int = 0
var run_ash_shards: int = 0
var shop_purchases: int = 0
var active_forge_mark: String = ""
var forge_marks_chosen: Array[String] = []
var route_history: Array[Dictionary] = []
var reward_history: Array[String] = []
var reward_display_history: Array[String] = []
var room_variant_history: Array[String] = []
var run_finished: bool = false
var current_phase: int = RunPhase.HUB

var _advance_in_progress: bool = false
var _t_down_previous: bool = false
var _e_down_previous: bool = false
var _return_input_armed: bool = false
var _choice_generation_index: int = 0
var _active_gates: Array[RunChoiceGate] = []
var _active_interactables: Array[RunRoomInteractable] = []
var _current_gate_choices: Array[Dictionary] = []
var _pending_reward_source: Dictionary = {}
var _last_selected_gate_name: String = ""
var _room_completion_pending: bool = false
var _route_choice_spawn_pending: bool = false
var _boss_placeholder: Node2D = null
var _boss_exit: RunRoomInteractable = null
var _active_ash_warden_boss: Node2D = null
var _boss_health_current: int = 0
var _boss_health_max: int = 1
var boss_defeated_this_run: bool = false
var last_run_summary: Dictionary = {}
var _run_outcome_reason: String = ""
var _phase_serial: int = 0
var _base_reward_choices_per_room: int = 3
var _base_starting_run_ash: int = 2
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var hud_controller: Circle0RunHUD = null
var intro_toast: IsoRoomIntroToast = null
var last_status: String = "Run state initializing."
var last_room_title: String = "Threshold Nave"

func _ready() -> void:
	SaveGameData.load_or_create()
	_base_reward_choices_per_room = reward_choices_per_room
	_base_starting_run_ash = starting_run_ash
	_set_phase(RunPhase.HUB, "Local loop node created.")
	_audio_context("combat")
	_setup_hud()
	_create_shared_manager()
	_ensure_run_boon_state()
	call_deferred("_wire_room_deferred")

func _process(_delta: float) -> void:
	if restart_key_enabled:
		if _key_pressed_once(KEY_T, _t_down_previous):
			_t_down_previous = true
			start_new_local_run()
		else:
			_t_down_previous = Input.is_physical_key_pressed(KEY_T)
	if run_finished and return_to_hub_enabled:
		_update_return_to_hub_input()
	_update_hud()

func start_new_local_run() -> void:
	_reset_run_counters()
	_audio_context("combat")
	_set_phase(RunPhase.RUN_START, "Circle 0 run restarted.")
	if shared_patron_manager != null:
		shared_patron_manager.reset_run()
	_ensure_run_boon_state()
	if run_boon_state != null and run_boon_state.has_method("reset_for_new_run"):
		run_boon_state.call("reset_for_new_run")
	_enter_combat_room("combat")
	_debug("Circle 0 route run restarted.")

func _reset_run_counters() -> void:
	_clear_route_runtime_nodes()
	rooms_completed = 0
	current_room_cycle = 1
	current_depth = 1
	if demo_run_length_locked:
		rooms_until_run_end = maxi(1, demo_rooms_before_boss)
	current_room_type = "combat"
	current_room_variant = _select_combat_variant("combat")
	combat_rooms_cleared = 0
	reward_rooms_completed = 0
	fountain_rooms_completed = 0
	forge_rooms_seen = 0
	shop_rooms_seen = 0
	run_bonus_ash_sigils = 0
	heal_on_room_clear_amount = 0
	var permanent_modifiers: Dictionary = PERMANENT_UPGRADE_SCRIPT.get_run_start_modifiers()
	run_bonus_ash_sigils += int(permanent_modifiers.get("bonus_outcome_sigils", 0))
	run_ash_shards = maxi(0, _base_starting_run_ash + int(permanent_modifiers.get("bonus_starting_run_ash", 0)))
	reward_choices_per_room = clampi(_base_reward_choices_per_room + int(permanent_modifiers.get("bonus_reward_choices", 0)), 3, 4)
	shop_purchases = 0
	active_forge_mark = ""
	forge_marks_chosen.clear()
	route_history.clear()
	_current_gate_choices.clear()
	_last_selected_gate_name = ""
	reward_history.clear()
	reward_display_history.clear()
	_pending_reward_source.clear()
	room_variant_history.clear()
	run_finished = false
	_advance_in_progress = false
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_return_input_armed = false
	_boss_placeholder = null
	_boss_exit = null
	_active_ash_warden_boss = null
	_boss_health_current = 0
	_boss_health_max = 1
	boss_defeated_this_run = false
	last_run_summary.clear()
	_run_outcome_reason = ""

func _create_shared_manager() -> void:
	shared_patron_manager = PatronRunManager.new()
	shared_patron_manager.name = "LocalSharedPatronRunManager"
	add_child(shared_patron_manager)

func _wire_room_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	runtime_adapter = _find_or_create_adapter()
	if runtime_adapter == null:
		push_error("[IsoLocalLoop] RuntimeAdapter missing and could not be created.")
		return
	runtime_adapter.route_choice_flow_handles_room_clear = true
	runtime_adapter.set_encounter_cycle_index(current_room_cycle)
	runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
	runtime_adapter.set_shared_patron_manager(shared_patron_manager)
	if not runtime_adapter.combat_room_cleared.is_connected(_on_combat_room_cleared):
		runtime_adapter.combat_room_cleared.connect(_on_combat_room_cleared)
	_wire_patron_flow_signals_for_compatibility()
	_wire_player_death_signal()
	if auto_start_run_on_ready:
		start_new_local_run()
	else:
		last_status = "Circle 0 local loop ready. Press T to start a test run."
		_set_phase(RunPhase.HUB, last_status)
	_debug("V14 run flow consistency controller wired.")

func _find_or_create_adapter() -> IsoAuthoredRoomRuntimeAdapter:
	var found: Node = get_parent().find_child("RuntimeAdapter", true, false)
	if found is IsoAuthoredRoomRuntimeAdapter:
		return found as IsoAuthoredRoomRuntimeAdapter
	var adapter: IsoAuthoredRoomRuntimeAdapter = IsoAuthoredRoomRuntimeAdapter.new()
	adapter.name = "RuntimeAdapter"
	get_parent().add_child(adapter)
	return adapter

func _wire_patron_flow_signals_for_compatibility() -> void:
	var flow: IsoPatronFlowController = _find_patron_flow()
	if flow == null:
		return
	flow.set_manager(shared_patron_manager)
	flow.clear_runtime_elements()

func _find_patron_flow() -> IsoPatronFlowController:
	var root: Node = get_parent()
	var nodes: Array[Node] = []
	_collect_nodes(root, nodes)
	for node: Node in nodes:
		if node is IsoPatronFlowController:
			return node as IsoPatronFlowController
	return null

func _on_combat_room_cleared() -> void:
	if current_phase != RunPhase.COMBAT:
		_debug("Ignored combat clear signal outside COMBAT phase: %s" % _phase_label())
		return
	if current_room_type != "combat" and current_room_type != "elite_combat":
		return
	if _room_completion_pending or run_finished:
		return
	combat_rooms_cleared += 1
	run_ash_shards += maxi(0, run_ash_per_completed_combat)
	if current_room_type == "elite_combat":
		run_ash_shards += 1
	if heal_on_room_clear_amount > 0:
		_heal_player_flat(heal_on_room_clear_amount)
	_complete_current_room("Combat cleared in %s" % _display_variant(current_room_variant))

func _complete_current_room(reason: String) -> void:
	if run_finished:
		return
	if not _phase_can_complete_room():
		_debug("Ignored room completion from invalid phase %s: %s" % [_phase_label(), reason])
		return
	var completed_phase: int = current_phase
	_room_completion_pending = true
	_route_choice_spawn_pending = false
	rooms_completed += 1
	route_history.append({
		"depth": current_depth,
		"room_type": current_room_type,
		"variant": current_room_variant,
		"reason": reason,
	})
	last_status = "%s. Room %d/%d complete." % [reason, rooms_completed, rooms_until_run_end]

	if completed_phase == RunPhase.COMBAT:
		if rooms_completed == 1 and _pending_reward_source.is_empty():
			_set_first_room_boon_source()
		if not _pending_reward_source.is_empty():
			_enter_pending_reward_source_room(reason)
			return

	if completed_phase == RunPhase.BOSS_LOCKED_PLACEHOLDER:
		_finish_local_run(true, "Demo route complete. The Ash Warden gate has been reached.")
		return

	if demo_run_length_locked and rooms_completed >= maxi(1, demo_rooms_before_boss):
		_debug(last_status)
		_enter_boss_antechamber_placeholder()
		return

	_set_phase(RunPhase.ROOM_CLEAR, last_status)
	_debug(last_status)
	if not demo_run_length_locked and rooms_completed >= rooms_until_run_end:
		_finish_local_run(true, "Demo route complete")
		return
	if route_choice_enabled:
		_schedule_route_choice_spawn()
	else:
		current_depth += 1
		_enter_combat_room("combat")

func _phase_can_complete_room() -> bool:
	return current_phase == RunPhase.COMBAT \
		or current_phase == RunPhase.REWARD \
		or current_phase == RunPhase.FOUNTAIN \
		or current_phase == RunPhase.SHOP \
		or current_phase == RunPhase.FORGE \
		or current_phase == RunPhase.BOSS_LOCKED_PLACEHOLDER \
		or current_phase == RunPhase.BOSS

func _schedule_route_choice_spawn() -> void:
	if _route_choice_spawn_pending:
		return
	_route_choice_spawn_pending = true
	var token: int = _phase_serial
	call_deferred("_spawn_choice_gates_deferred", token)

func _spawn_choice_gates_deferred(expected_phase_serial: int) -> void:
	await get_tree().create_timer(gate_spawn_delay).timeout
	if run_finished:
		return
	if expected_phase_serial != _phase_serial:
		_debug("Cancelled stale route-choice spawn request.")
		return
	if current_phase != RunPhase.ROOM_CLEAR:
		_debug("Cancelled route-choice spawn because phase is %s." % _phase_label())
		return
	_route_choice_spawn_pending = false
	_clear_route_runtime_nodes()
	current_room_type = "choice"
	current_room_variant = route_gate_room_variant
	last_room_title = "Route Gate Crossing"
	_set_phase(RunPhase.ROUTE_CHOICE, "Choose the next chamber.")
	if runtime_adapter != null:
		runtime_adapter.refresh_room_presentation_only("choice", current_depth, current_room_variant)
		if runtime_adapter.has_method("hide_live_authoring_overlays"):
			runtime_adapter.call("hide_live_authoring_overlays")
	var choices: Array[Dictionary] = _build_gate_choices()
	_current_gate_choices = choices.duplicate(true)
	var positions: Array[Vector2] = _get_gate_positions()
	if choices.size() == 1 and positions.size() >= 2:
		positions = [positions[1]]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(choices.size()):
		var gate: RunChoiceGate = RunChoiceGate.new()
		parent_node.add_child(gate)
		gate.setup(choices[i], positions[i % positions.size()])
		gate.show_world_gate_label = true
		gate.show_focus_prompt = true
		gate.debug_draw_radius = false
		gate.gate_chosen.connect(_on_route_gate_chosen)
		if gate.has_signal("gate_focus_changed"):
			gate.gate_focus_changed.connect(_on_gate_focus_changed)
		_active_gates.append(gate)
	_audio_event("gate_open")
	last_status = "Choose one of the three physical gates. The bottom route cards match left, center, and right."
	_room_completion_pending = false
	_show_intro("Route Gate Crossing", "Choose the next chamber")
	_debug("Spawned V14 route gates: %s" % str(choices))

func _on_route_gate_chosen(choice_data: Dictionary) -> void:
	if run_finished or _advance_in_progress:
		return
	if current_phase != RunPhase.ROUTE_CHOICE:
		_debug("Ignored gate choice outside ROUTE_CHOICE phase.")
		return
	_advance_in_progress = true
	_audio_event("gate_open")
	_last_selected_gate_name = str(choice_data.get("display_name", "Unknown Gate"))

	if choice_data.has("reward_source") and choice_data.get("reward_source") is Dictionary:
		_pending_reward_source = (choice_data.get("reward_source") as Dictionary).duplicate(true)

	_clear_route_runtime_nodes()
	_current_gate_choices.clear()
	current_depth += 1
	current_room_type = str(choice_data.get("room_type", "combat"))
	last_status = "Entering: %s." % str(choice_data.get("display_name", current_room_type))
	match current_room_type:
		"combat", "elite_combat":
			_enter_combat_room(current_room_type)
		"patron_boon", "route_reward":
			_enter_combat_room("combat")
		"reward":
			_enter_reward_room()
		"fountain":
			_enter_fountain_room()
		"forge":
			_enter_forge_room()
		"shop":
			_enter_shop_room()
		_:
			_enter_combat_room("combat")
	_advance_in_progress = false

func _enter_combat_room(room_type: String) -> void:
	current_room_type = room_type
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_clear_route_runtime_nodes()
	current_room_cycle = combat_rooms_cleared + 1
	if room_type == "elite_combat":
		current_room_cycle += 2
	current_room_variant = _select_combat_variant(room_type)
	room_variant_history.append(current_room_variant)
	last_room_title = _display_variant(current_room_variant)
	_set_phase(RunPhase.ROOM_INTRO, "Entering %s." % last_room_title)
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(room_type, current_depth, current_room_variant)
		runtime_adapter.start_combat_encounter(current_room_cycle)
	last_status = "%s. Defeat all enemies. Watch the orange hazard warnings." % last_room_title
	if room_type == "elite_combat":
		last_status = "%s. Elite enemy cycle loaded." % last_room_title
	_show_intro(last_room_title, "%s | Depth %d | Hazards active" % [_display_room_type(room_type), current_depth])
	_set_phase(RunPhase.COMBAT, last_status)
	_debug(last_status)

func _enter_reward_room() -> void:
	current_room_type = "reward"
	current_room_variant = "reward_altar"
	last_room_title = "Penitent Reward Altar"
	_room_completion_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering reward room.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	_spawn_reward_choices()
	_show_intro(last_room_title, "Choose one boon or reward")
	last_status = "Reward room. Pick exactly one boon or reward, then new route gates appear."
	_set_phase(RunPhase.REWARD, last_status)
	_debug(last_status)

func _enter_fountain_room() -> void:
	current_room_type = "fountain"
	current_room_variant = "ash_fountain"
	last_room_title = "Ashen Fountain"
	_room_completion_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering fountain room.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	var data: Dictionary = {
		"kind": "fountain",
		"display_name": "Ashen Fountain",
		"description": "Restore 60% of max HP once.",
		"exact_effect": "Heal 60% of maximum HP now.",
		"current_consequence": "One safe recovery before the next route choice.",
	}
	_spawn_single_interactable(data, _get_reward_position(), _on_fountain_used)
	_show_intro(last_room_title, "Recovery room")
	last_status = "Fountain room. Use the fountain once, then choose the next route."
	_set_phase(RunPhase.FOUNTAIN, last_status)
	_debug(last_status)

func _enter_forge_room() -> void:
	current_room_type = "forge"
	current_room_variant = "cold_forge"
	last_room_title = "Cold Forge"
	forge_rooms_seen += 1
	_room_completion_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering forge room.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	_spawn_forge_marks()
	_show_intro(last_room_title, "Choose one run-only sword mark")
	last_status = "Forge room. Choose one sword mark for this run."
	_set_phase(RunPhase.FORGE, last_status)
	_debug(last_status)

func _enter_shop_room() -> void:
	current_room_type = "shop"
	current_room_variant = "silent_shop"
	last_room_title = "Silent Ash Merchant"
	shop_rooms_seen += 1
	_room_completion_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering shop room.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	_spawn_shop_items()
	_show_intro(last_room_title, "Buy one useful item with Run Ash")
	last_status = "Shop room. Buy one item with Run Ash, then continue."
	_set_phase(RunPhase.SHOP, last_status)
	_debug(last_status)

func _spawn_reward_choices() -> void:
	var rewards: Array[Dictionary] = _build_pending_reward_choices() if not _pending_reward_source.is_empty() else _build_reward_choices()
	var center: Vector2 = _get_reward_position()
	var offsets: Array[Vector2] = [Vector2(-128.0, 8.0), Vector2(0.0, -34.0), Vector2(128.0, 8.0)]
	if reward_choices_per_room >= 4:
		offsets = [Vector2(-168.0, 14.0), Vector2(-56.0, -36.0), Vector2(56.0, -36.0), Vector2(168.0, 14.0)]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(mini(reward_choices_per_room, rewards.size())):
		var item: RunRoomInteractable = RunRoomInteractable.new()
		parent_node.add_child(item)
		item.setup(rewards[i], center + offsets[i % offsets.size()])
		item.activated.connect(_on_reward_chosen)
		if item.has_signal("focus_changed"):
			item.focus_changed.connect(_on_interactable_focus_changed)
		_active_interactables.append(item)

func _clear_active_interactables() -> void:
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.queue_free()
	_active_interactables.clear()

func _spawn_single_interactable(data: Dictionary, position: Vector2, callback: Callable) -> void:
	var item: RunRoomInteractable = RunRoomInteractable.new()
	_get_runtime_parent().add_child(item)
	item.setup(data, position)
	item.activated.connect(callback)
	if item.has_signal("focus_changed"):
		item.focus_changed.connect(_on_interactable_focus_changed)
	_active_interactables.append(item)

func _on_reward_chosen(payload: Dictionary) -> void:
	if current_phase != RunPhase.REWARD:
		return
	if _room_completion_pending:
		return

	var had_pending_source: bool = not _pending_reward_source.is_empty()
	var pending_source_name: String = str(_pending_reward_source.get("display_name", "Patron"))

	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.mark_used()
	_audio_event("reward_claim")

	var reward_kind: String = str(payload.get("reward_kind", ""))
	if reward_kind == "boon":
		_claim_boon_payload(payload)
	elif reward_kind == "gold_payout" or reward_kind == "health_boost":
		_claim_route_payout_payload(payload)
	else:
		_apply_reward(payload)

	reward_rooms_completed += 1

	if had_pending_source:
		_pending_reward_source.clear()
		_clear_route_runtime_nodes()
		_clear_active_interactables()
		last_status = "%s boon claimed: %s." % [pending_source_name, str(payload.get("display_name", "Unknown"))]
		_set_phase(RunPhase.ROOM_CLEAR, last_status)
		_room_completion_pending = false

		if demo_run_length_locked and rooms_completed >= maxi(1, demo_rooms_before_boss):
			_enter_boss_antechamber_placeholder()
			return

		if route_choice_enabled:
			_schedule_route_choice_spawn()
		else:
			current_depth += 1
			_enter_combat_room("combat")
		return

	_complete_current_room("Reward claimed: %s" % str(payload.get("display_name", "Unknown")))

func _on_fountain_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.FOUNTAIN:
		return
	if _room_completion_pending:
		return
	_audio_event("fountain_use")
	fountain_rooms_completed += 1
	_heal_player_ratio(fountain_heal_ratio_v21)
	_complete_current_room("Fountain used: recovered 60% HP")

func _on_forge_used(_payload: Dictionary) -> void:
	# Legacy fallback path. V21 uses _on_forge_mark_chosen.
	if current_phase != RunPhase.FORGE:
		return
	if _room_completion_pending:
		return
	_complete_current_room("Forge inspected")

func _on_shop_used(_payload: Dictionary) -> void:
	# Legacy fallback path. V21 uses _on_shop_item_bought.
	if current_phase != RunPhase.SHOP:
		return
	if _room_completion_pending:
		return
	_complete_current_room("Merchant inspected")

func _spawn_forge_marks() -> void:
	var marks: Array[Dictionary] = _forge_mark_catalogue()
	var center: Vector2 = _get_reward_position()
	var offsets: Array[Vector2] = [Vector2(-132.0, 4.0), Vector2(0.0, -38.0), Vector2(132.0, 4.0)]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(marks.size()):
		var item: RunRoomInteractable = RunRoomInteractable.new()
		parent_node.add_child(item)
		item.setup(marks[i], center + offsets[i % offsets.size()])
		item.activated.connect(_on_forge_mark_chosen)
		if item.has_signal("focus_changed"):
			item.focus_changed.connect(_on_interactable_focus_changed)
		_active_interactables.append(item)

func _forge_mark_catalogue() -> Array[Dictionary]:
	return [
		_forge_mark_data("serrated_edge", "Serrated Edge", "Light attacks cut deeper", "Light attack damage +1 and attack arc +8°. Run-only forge mark."),
		_forge_mark_data("grave_weight", "Grave Weight", "Heavy attacks hit harder but recover slower", "Heavy attack damage +2, heavy cooldown +0.12s. Run-only forge mark."),
		_forge_mark_data("ash_step", "Ash Step", "Dash becomes safer and more mobile", "Dash cooldown -0.06s and dash duration +0.02s. Run-only forge mark."),
	]

func _forge_mark_data(mark_id: String, display_name: String, description: String, exact_effect: String) -> Dictionary:
	return {
		"kind": "forge_mark",
		"mark_id": mark_id,
		"display_name": display_name,
		"rarity": "forge",
		"category": "Weapon Mark",
		"description": description,
		"exact_effect": exact_effect,
		"current_consequence": "Only one forge mark can be chosen in this room.",
		"icon": "G",
	}

func _on_forge_mark_chosen(payload: Dictionary) -> void:
	if current_phase != RunPhase.FORGE:
		return
	if _room_completion_pending:
		return
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.mark_used()
	_audio_event("forge_use")
	_apply_forge_mark(payload)
	_complete_current_room("Forge mark chosen: %s" % str(payload.get("display_name", "Unknown")))

func _apply_forge_mark(payload: Dictionary) -> void:
	var player: Node = _find_player_node()
	var mark_id: String = str(payload.get("mark_id", ""))
	var display_name: String = str(payload.get("display_name", mark_id))
	active_forge_mark = mark_id
	forge_marks_chosen.append(mark_id)
	reward_display_history.append("Forge: " + display_name)
	if player == null:
		return
	match mark_id:
		"serrated_edge":
			_add_player_int(player, "attack_damage", 1)
			_add_player_float_clamped(player, "light_attack_arc_degrees", 8.0, 45.0, 175.0)
		"grave_weight":
			_add_player_int(player, "heavy_attack_damage", 2)
			_add_player_float_clamped(player, "heavy_attack_cooldown", 0.12, 0.24, 9.0)
		"ash_step":
			_add_player_float_clamped(player, "dash_cooldown", -0.06, 0.20, 9.0)
			_add_player_float_clamped(player, "dash_duration", 0.02, 0.05, 0.28)
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

func _spawn_shop_items() -> void:
	var items: Array[Dictionary] = _shop_catalogue()
	var center: Vector2 = _get_reward_position()
	var offsets: Array[Vector2] = [Vector2(-132.0, 4.0), Vector2(0.0, -38.0), Vector2(132.0, 4.0)]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(items.size()):
		var item: RunRoomInteractable = RunRoomInteractable.new()
		parent_node.add_child(item)
		item.setup(items[i], center + offsets[i % offsets.size()])
		item.activated.connect(_on_shop_item_bought)
		if item.has_signal("focus_changed"):
			item.focus_changed.connect(_on_interactable_focus_changed)
		_active_interactables.append(item)

func _shop_catalogue() -> Array[Dictionary]:
	return [
		_shop_item_data("shop_heal", "Blood Poultice", shop_heal_cost, "Heal 3 HP now", "Recover 3 HP immediately. Does not increase max HP."),
		_shop_item_data("shop_edge", "Pilgrim's Edge", shop_damage_cost, "Light attack damage +1", "Your light attacks deal 1 additional damage for this run."),
		_shop_item_data("shop_mystery", "Sealed Boon", shop_mystery_boon_cost, "Claim a mystery boon", "Gain one deterministic reward from the current run catalogue."),
	]

func _shop_item_data(item_id: String, display_name: String, cost: int, description: String, exact_effect: String) -> Dictionary:
	return {
		"kind": "shop_item",
		"item_id": item_id,
		"display_name": display_name,
		"rarity": "shop",
		"category": "Merchant",
		"cost": maxi(0, cost),
		"description": description,
		"exact_effect": exact_effect,
		"current_consequence": "Costs %d Run Ash. Current Run Ash: %d." % [maxi(0, cost), run_ash_shards],
		"icon": "S",
	}

func _on_shop_item_bought(payload: Dictionary) -> void:
	if current_phase != RunPhase.SHOP:
		return
	if _room_completion_pending:
		return
	var cost: int = int(payload.get("cost", 0))
	if not _spend_run_ash(cost):
		last_status = "Not enough Run Ash for %s. Current Run Ash: %d." % [str(payload.get("display_name", "item")), run_ash_shards]
		_update_hud()
		return
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.mark_used()
	_audio_event("shop_buy")
	_apply_shop_item(payload)
	shop_purchases += 1
	_complete_current_room("Shop purchase: %s" % str(payload.get("display_name", "Unknown")))

func _spend_run_ash(cost: int) -> bool:
	var safe_cost: int = maxi(0, cost)
	if run_ash_shards < safe_cost:
		return false
	run_ash_shards -= safe_cost
	return true

func _apply_shop_item(payload: Dictionary) -> void:
	var player: Node = _find_player_node()
	var item_id: String = str(payload.get("item_id", ""))
	var display_name: String = str(payload.get("display_name", item_id))
	reward_display_history.append("Shop: " + display_name)
	if item_id == "shop_mystery":
		var rewards: Array[Dictionary] = _build_reward_choices()
		if not rewards.is_empty():
			_apply_reward(rewards[0])
		return
	if player == null:
		return
	match item_id:
		"shop_heal":
			_heal_player_flat(3)
		"shop_edge":
			_add_player_int(player, "attack_damage", 1)
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

func _enter_boss_antechamber_placeholder() -> void:
	current_room_type = "boss_antechamber"
	current_room_variant = boss_antechamber_variant
	last_room_title = "Boss Antechamber"
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering the sealed gate before the Ash Warden.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	var data: Dictionary = {
		"kind": "boss_antechamber",
		"display_name": "Sealed Ash Warden Gate",
		"description": "The demo run length is now locked. The Ash Warden fight is reserved for the boss milestones.",
		"icon": "B",
	}
	_spawn_single_interactable(data, _get_boss_gate_position(), Callable(self, "_on_boss_antechamber_used"))
	_show_intro(last_room_title, "The first gatekeeper waits beyond this seal")
	last_status = "Boss Antechamber reached. Press E at the sealed gate to complete the current demo route."
	_set_phase(RunPhase.BOSS_LOCKED_PLACEHOLDER, last_status)
	_debug(last_status)

func _on_boss_antechamber_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.BOSS_LOCKED_PLACEHOLDER:
		return
	if not boss_arena_enabled_v23:
		if not boss_placeholder_completes_run:
			last_status = "The Ash Warden gate is sealed until the boss milestone."
			_update_hud()
			return
		_complete_current_room("Sealed Ash Warden gate reached")
		return
	_enter_boss_arena_placeholder()

func _enter_boss_arena_placeholder() -> void:
	current_room_type = "boss_arena"
	current_room_variant = boss_arena_variant
	last_room_title = "The Sentencing Furnace"
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering the Sentencing Furnace.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	_wire_player_death_signal()
	_show_intro(last_room_title, "Boss arena · The Ash Warden")
	_audio_context("boss")
	if ash_warden_boss_enabled_v24:
		_spawn_ash_warden_boss()
		last_status = "The Ash Warden judges the descent. Defeat him to open the victory exit."
		_set_phase(RunPhase.BOSS, last_status)
	else:
		_spawn_boss_placeholder()
		last_status = "The Ash Warden placeholder waits. Break the furnace seal to open the victory exit."
		_set_phase(RunPhase.BOSS_ARENA_PLACEHOLDER, last_status)
	_debug(last_status)

func _spawn_ash_warden_boss() -> void:
	_clear_boss_placeholder_nodes()
	var boss_script = load(ash_warden_boss_script_path)
	if boss_script == null:
		push_warning("[IsoLocalLoop] Missing AshWardenBoss.gd. Falling back to V23 seal placeholder.")
		_spawn_boss_placeholder()
		return
	var boss_node: Node = boss_script.new()
	if boss_node == null:
		push_warning("[IsoLocalLoop] Could not instantiate Ash Warden boss. Falling back to V23 seal placeholder.")
		_spawn_boss_placeholder()
		return
	_boss_health_current = ash_warden_max_health_v24
	_boss_health_max = ash_warden_max_health_v24
	boss_node.name = "AshWardenBoss"
	boss_node.add_to_group("ash_warden_boss")
	boss_node.add_to_group("boss_runtime")
	_get_runtime_parent().add_child(boss_node)
	if boss_node is Node2D:
		_active_ash_warden_boss = boss_node as Node2D
	else:
		_active_ash_warden_boss = null
	var spawn_position: Vector2 = _get_boss_spawn_position()
	var arena_origin: Vector2 = _get_room_center_position()
	if boss_node.has_method("setup_boss"):
		boss_node.call("setup_boss", spawn_position, ash_warden_max_health_v24, arena_origin)
	elif boss_node is Node2D:
		(boss_node as Node2D).global_position = spawn_position
	if boss_node.has_signal("health_changed"):
		boss_node.connect("health_changed", Callable(self, "_on_ash_warden_health_changed"))
	if boss_node.has_signal("phase_changed"):
		boss_node.connect("phase_changed", Callable(self, "_on_ash_warden_phase_changed"))
	if boss_node.has_signal("defeated"):
		boss_node.connect("defeated", Callable(self, "_on_ash_warden_defeated"))
	last_status = "The Ash Warden has awakened."
	_update_hud()

func _spawn_boss_placeholder() -> void:
	_clear_boss_placeholder_nodes()
	var data: Dictionary = {
		"kind": "boss_placeholder",
		"display_name": "Ash Warden Seal",
		"description": "Fallback placeholder. AshWardenBoss.gd could not be loaded.",
		"exact_effect": "Press E to break the fallback seal and open the victory exit.",
		"current_consequence": "This fallback should only appear if the V24 boss script is missing.",
		"icon": "W",
	}
	var boss: RunRoomInteractable = RunRoomInteractable.new()
	boss.name = "AshWardenBossPlaceholder"
	boss.add_to_group("boss_placeholder")
	_get_runtime_parent().add_child(boss)
	boss.setup(data, _get_boss_spawn_position())
	boss.activated.connect(_on_boss_placeholder_interactable_used)
	if boss.has_signal("focus_changed"):
		boss.focus_changed.connect(_on_interactable_focus_changed)
	_active_interactables.append(boss)
	_boss_placeholder = boss

func _on_ash_warden_health_changed(current_health: int, max_health: int) -> void:
	_boss_health_current = current_health
	_boss_health_max = maxi(1, max_health)
	last_status = "Ash Warden HP: %d/%d." % [_boss_health_current, _boss_health_max]
	_update_hud()

func _on_ash_warden_phase_changed(phase_index: int) -> void:
	_audio_event("boss_phase_changed")
	last_status = "The Ash Warden enters Phase %d." % phase_index
	_show_intro("Ash Warden", "Phase %d" % phase_index)
	_update_hud()

func _on_ash_warden_defeated() -> void:
	if current_phase != RunPhase.BOSS:
		return
	boss_defeated_this_run = true
	_audio_event("boss_death")
	last_status = "The Ash Warden has fallen. The exit has opened."
	if runtime_adapter != null:
		runtime_adapter.clear_runtime_dangers()
	_spawn_boss_victory_exit()
	_update_hud()

func _on_boss_placeholder_interactable_used(_payload: Dictionary) -> void:
	_on_boss_placeholder_defeated()

func _on_boss_placeholder_defeated() -> void:
	if current_phase != RunPhase.BOSS_ARENA_PLACEHOLDER:
		return
	last_status = "The Ash Warden placeholder seal breaks. The exit has opened."
	_spawn_boss_victory_exit()
	_update_hud()

func _spawn_boss_victory_exit() -> void:
	if _boss_exit != null and is_instance_valid(_boss_exit):
		return
	var data: Dictionary = {
		"kind": "boss_exit",
		"display_name": "Exit to Threshold Nave",
		"description": "The Ash Warden has fallen. Return with the current demo victory.",
		"exact_effect": "Complete the demo route and return to the hub.",
		"current_consequence": "The demo victory loop will be finalized in V25.",
		"icon": "X",
	}
	var item: RunRoomInteractable = RunRoomInteractable.new()
	_get_runtime_parent().add_child(item)
	item.setup(data, _get_boss_exit_position())
	item.activated.connect(_on_boss_victory_exit_used)
	if item.has_signal("focus_changed"):
		item.focus_changed.connect(_on_interactable_focus_changed)
	_active_interactables.append(item)
	_boss_exit = item

func _on_boss_victory_exit_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.BOSS_ARENA_PLACEHOLDER and current_phase != RunPhase.BOSS:
		return
	boss_defeated_this_run = true
	_finish_local_run(true, "The Ash Warden has been defeated. The descent returns with proof of victory.")

func _clear_boss_placeholder_nodes() -> void:
	if _boss_placeholder != null and is_instance_valid(_boss_placeholder):
		_boss_placeholder.queue_free()
	_boss_placeholder = null
	if _boss_exit != null and is_instance_valid(_boss_exit):
		_boss_exit.queue_free()
	_boss_exit = null
	_active_ash_warden_boss = null
	var nodes: Array[Node] = []
	_collect_nodes(get_parent(), nodes)
	for node: Node in nodes:
		if node.is_in_group("boss_placeholder") or node.is_in_group("ash_warden_boss") or node.is_in_group("boss_runtime"):
			node.queue_free()



func _route_reward_gate_choice(source_kind: String, display_name: String, consequence: String) -> Dictionary:
	return {
		"room_type": "route_reward",
		"display_name": display_name,
		"icon": "◆",
		"risk": "Standard",
		"risk_level": "Standard",
		"short_consequence": consequence,
		"current_consequence": consequence,
		"exact_effect": consequence,
		"prompt": "[E] Enter",
		"reward_source": {
			"kind": source_kind,
			"display_name": display_name,
		},
	}

func _gold_payout_payload() -> Dictionary:
	return {
		"id": "route_gold_payout",
		"reward_kind": "gold_payout",
		"display_name": "Run Gold",
		"rarity": "common",
		"category": "currency",
		"exact_effect": "Gain +4 run gold to spend in shops this run.",
		"description": "Gain +4 run gold to spend in shops this run.",
		"body": "Gain +4 run gold to spend in shops this run.",
		"short_consequence": "+4 run gold.",
		"current_consequence": "Gold can be spent in shops before the run ends.",
		"prompt": "[E] Claim",
		"icon": "¤",
		"amount": 4,
	}

func _health_boost_payload() -> Dictionary:
	return {
		"id": "route_health_boost",
		"reward_kind": "health_boost",
		"display_name": "Health Boon",
		"rarity": "common",
		"category": "survival",
		"exact_effect": "Recover 1 HP now. Later this can become max-health growth.",
		"description": "Recover 1 HP now. Later this can become max-health growth.",
		"body": "Recover 1 HP now. Later this can become max-health growth.",
		"short_consequence": "Recover 1 HP.",
		"current_consequence": "Immediate survival reward.",
		"prompt": "[E] Claim",
		"icon": "+",
		"amount": 1,
	}

func _claim_route_payout_payload(payload: Dictionary) -> void:
	var kind: String = str(payload.get("reward_kind", ""))
	if kind == "gold_payout":
		var amount: int = int(payload.get("amount", 4))
		run_ash_shards += amount
		reward_history.append(str(payload.get("id", "route_gold_payout")))
		reward_display_history.append("Gold: +%d" % amount)
		last_status = "Claimed +%d run gold." % amount
		return

	if kind == "health_boost":
		var heal_amount: int = int(payload.get("amount", 1))
		_heal_player_flat(heal_amount)
		reward_history.append(str(payload.get("id", "route_health_boost")))
		reward_display_history.append("Health: +%d" % heal_amount)
		last_status = "Recovered %d HP." % heal_amount
		return

func _build_first_patron_gate_choices() -> Array[Dictionary]:
	return [
		_patron_gate_choice("patron_azazel_chains", "AZAZEL", "Clear the next room to receive a boon from Azazel."),
		_patron_gate_choice("patron_mammon_furnace", "MAMMON", "Clear the next room to receive a boon from Mammon."),
		_patron_gate_choice("patron_minos_judge", "MINOS", "Clear the next room to receive a boon from Minos."),
	]

func _patron_gate_choice(patron_id: String, display_name: String, consequence: String) -> Dictionary:
	return {
		"room_type": "patron_boon",
		"display_name": display_name,
		"icon": "✦",
		"risk": "Standard",
		"risk_level": "Standard",
		"short_consequence": consequence,
		"current_consequence": consequence,
		"exact_effect": consequence,
		"prompt": "[E] Enter",
		"reward_source": {
			"kind": "patron",
			"patron_id": patron_id,
			"display_name": display_name,
		},
	}


func _set_first_room_boon_source() -> void:
	# First-room rule: the first combat clear always pays a patron boon before route gates.
	# Later route-gated patron rewards still use the chosen gate's reward_source.
	if not _pending_reward_source.is_empty():
		return

	var patron_options: Array[Dictionary] = [
		{
			"kind": "patron",
			"patron_id": "patron_azazel_chains",
			"display_name": "AZAZEL",
		},
		{
			"kind": "patron",
			"patron_id": "patron_mammon_furnace",
			"display_name": "MAMMON",
		},
		{
			"kind": "patron",
			"patron_id": "patron_minos_judge",
			"display_name": "MINOS",
		},
	]

	var index: int = abs(hash(str(Time.get_ticks_msec()) + ":" + str(rooms_completed) + ":" + str(current_depth))) % patron_options.size()
	_pending_reward_source = patron_options[index].duplicate(true)

func _enter_pending_reward_source_room(reason: String) -> void:
	var source_name: String = str(_pending_reward_source.get("display_name", "Patron"))
	current_room_type = "reward"
	current_room_variant = "patron_boon_reward"
	last_room_title = "%s Boon" % source_name
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "%s offers a boon." % source_name)
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation("reward", current_depth, "reward_altar")
		runtime_adapter.prepare_non_combat_room()
	_spawn_reward_choices()
	_show_intro(last_room_title, "Choose one boon from %s" % source_name)
	last_status = "%s reward. Pick exactly one boon." % source_name
	_room_completion_pending = false
	_set_phase(RunPhase.REWARD, last_status)
	_debug("%s after %s" % [last_status, reason])

func _build_pending_reward_choices() -> Array[Dictionary]:
	var source_kind: String = str(_pending_reward_source.get("kind", ""))
	var patron_id: String = str(_pending_reward_source.get("patron_id", ""))

	if source_kind == "gold":
		return [_gold_payout_payload()]
	if source_kind == "health":
		return [_health_boost_payload()]

	if source_kind != "patron" or patron_id == "":
		return _build_reward_choices()

	var file_path: String = _boon_file_for_patron(patron_id)
	if file_path == "":
		return _build_reward_choices()

	var json_text: String = FileAccess.get_file_as_string(file_path)
	var parsed: Variant = JSON.parse_string(json_text)
	var raw_boons: Array = []

	if parsed is Array:
		raw_boons = parsed as Array
	elif parsed is Dictionary:
		var parsed_dict: Dictionary = parsed as Dictionary
		if parsed_dict.get("boons", []) is Array:
			raw_boons = parsed_dict.get("boons", []) as Array

	var choices: Array[Dictionary] = []
	for raw_boon: Variant in raw_boons:
		if not (raw_boon is Dictionary):
			continue
		var boon: Dictionary = raw_boon as Dictionary
		choices.append(_boon_payload_from_data(boon, patron_id))
		if choices.size() >= reward_choices_per_room:
			break

	if choices.is_empty():
		return _build_reward_choices()
	return choices

func _boon_file_for_patron(patron_id: String) -> String:
	match patron_id:
		"patron_azazel_chains":
			return "res://data/boons/azazel_chains_boons.json"
		"patron_mammon_furnace":
			return "res://data/boons/mammon_furnace_boons.json"
		"patron_minos_judge":
			return "res://data/boons/minos_judge_boons.json"
	return ""

func _boon_payload_from_data(boon: Dictionary, patron_id: String) -> Dictionary:
	var source_name: String = str(_pending_reward_source.get("display_name", "Patron"))
	var boon_id: String = str(boon.get("id", boon.get("boon_id", "unknown_boon")))
	var boon_name: String = str(boon.get("name", boon.get("display_name", boon_id)))
	var rarity: String = str(boon.get("rarity", "common"))
	var category: String = str(boon.get("category", "boon"))
	var exact_effect: String = str(boon.get("description_exact", boon.get("exact_effect", boon.get("description", "Gain a patron boon for this run."))))

	return {
		"id": boon_id,
		"reward_kind": "boon",
		"boon_id": boon_id,
		"patron_id": patron_id,
		"patron_name": source_name,
		"display_name": boon_name,
		"rarity": rarity,
		"category": category,
		"exact_effect": exact_effect,
		"description": exact_effect,
		"body": exact_effect,
		"short_consequence": exact_effect,
		"current_consequence": "%s boon: %s" % [source_name, exact_effect],
		"prompt": "[E] Claim",
		"icon": str(boon.get("icon", "✦")),
		"raw_boon": boon.duplicate(true),
	}


func _t009_notify_players_of_boon(payload: Dictionary) -> void:
	for node: Node in get_tree().get_nodes_in_group("player"):
		if node != null and is_instance_valid(node) and node.has_method("apply_run_boon"):
			node.call("apply_run_boon", payload)

func _claim_boon_payload(payload: Dictionary) -> void:
	var boon_id: String = str(payload.get("boon_id", payload.get("id", "unknown_boon")))
	var patron_name: String = str(payload.get("patron_name", "Patron"))
	var display_name: String = str(payload.get("display_name", boon_id))

	reward_history.append(boon_id)
	reward_display_history.append("%s: %s" % [patron_name, display_name])
	_t010_grant_boon_to_player(payload)
	_grant_boon_payload_to_player(payload)
	_t009_notify_players_of_boon(payload)

	if run_boon_state != null and is_instance_valid(run_boon_state):
		if run_boon_state.has_method("claim_boon"):
			run_boon_state.call("claim_boon", payload)
		elif run_boon_state.has_method("add_boon"):
			run_boon_state.call("add_boon", payload)
		elif run_boon_state.has_method("record_boon"):
			run_boon_state.call("record_boon", payload)



func _t010_grant_boon_to_player(payload: Dictionary) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for player_node: Node in players:
		if player_node == null or not is_instance_valid(player_node):
			continue
		if player_node.has_method("receive_boon_payload"):
			player_node.call("receive_boon_payload", payload)
		elif player_node.has_method("grant_boon_payload"):
			player_node.call("grant_boon_payload", payload)
		elif player_node.has_method("t010_receive_boon_payload"):
			player_node.call("t010_receive_boon_payload", payload)


func _build_gate_choices() -> Array[Dictionary]:
	_choice_generation_index += 1

	if demo_run_length_locked and force_demo_route_pattern:
		return _build_locked_demo_gate_choices()

	if rooms_completed == 1 and reward_rooms_completed <= 0:
		return _build_first_patron_gate_choices()

	if rooms_completed >= maxi(1, demo_rooms_before_boss - 1):
		return [
			_room_choice_with_text("elite_combat", "ELITE", "Mandatory final trial before the Ash Warden."),
		]

	var patron_cycle: int = (_choice_generation_index + rooms_completed) % 3
	var patron_choice: Dictionary
	if patron_cycle == 0:
		patron_choice = _patron_gate_choice("patron_azazel_chains", "AZAZEL", "Clear the next room to receive a boon from Azazel.")
	elif patron_cycle == 1:
		patron_choice = _patron_gate_choice("patron_mammon_furnace", "MAMMON", "Clear the next room to receive a boon from Mammon.")
	else:
		patron_choice = _patron_gate_choice("patron_minos_judge", "MINOS", "Clear the next room to receive a boon from Minos.")

	var choices: Array[Dictionary] = [patron_choice]

	if rooms_completed % 3 == 0:
		choices.append(_room_choice_with_text("forge", "FORGE", "Modify your weapon for this run."))
	elif rooms_completed % 3 == 1:
		choices.append(_route_reward_gate_choice("gold", "GOLD", "Clear the next room to gain run gold for shops."))
	else:
		choices.append(_route_reward_gate_choice("health", "HEALTH", "Clear the next room to recover health."))

	if shop_rooms_seen <= 0 and rooms_completed >= 2:
		choices.append(_room_choice_with_text("shop", "SHOP", "Spend run gold on survival or power."))
	elif fountain_rooms_completed <= 0:
		choices.append(_room_choice_with_text("fountain", "FOUNTAIN", "Recover before the next chamber."))
	else:
		choices.append(_route_reward_gate_choice("gold", "GOLD", "Clear the next room to gain run gold for shops."))

	return choices

func _build_locked_demo_gate_choices() -> Array[Dictionary]:
	# Route gates advertise reward sources. Generic COMBAT gates are intentionally removed.
	# The room behind most reward-source gates is still combat, but the displayed promise is the reward.
	if rooms_completed >= maxi(1, demo_rooms_before_boss - 1):
		return [
			_room_choice_with_text("elite_combat", "ELITE", "Mandatory final trial before the Ash Warden."),
		]

	if rooms_completed <= 1:
		return [
			_patron_gate_choice("patron_azazel_chains", "AZAZEL", "Clear the next room to receive a boon from Azazel."),
			_route_reward_gate_choice("gold", "GOLD", "Clear the next room to gain run gold for shops."),
			_route_reward_gate_choice("health", "HEALTH", "Clear the next room to recover health."),
		]

	if rooms_completed == 2:
		return [
			_patron_gate_choice("patron_mammon_furnace", "MAMMON", "Clear the next room to receive a boon from Mammon."),
			_room_choice_with_text("shop", "SHOP", "Spend run gold on survival or power."),
			_route_reward_gate_choice("gold", "GOLD", "Clear the next room to gain run gold for shops."),
		]

	return [
		_patron_gate_choice("patron_minos_judge", "MINOS", "Clear the next room to receive a boon from Minos."),
		_room_choice_with_text("forge", "FORGE", "Modify your weapon for this run."),
		_room_choice_with_text("fountain", "FOUNTAIN", "Recover before the Ash Warden route."),
	]

func _room_choice_with_text(room_type: String, display_name: String, description: String) -> Dictionary:
	var choice: Dictionary = _room_choice(room_type)
	choice["display_name"] = display_name
	choice["description"] = description
	return choice

func _should_skip_room_type(room_type: String, existing_choices: Array[Dictionary]) -> bool:
	for choice: Dictionary in existing_choices:
		if str(choice.get("room_type", "")) == room_type:
			return true
	if room_type == "fountain" and fountain_rooms_completed > 0 and rooms_completed < 4:
		return true
	if room_type == "forge" and forge_rooms_seen > 0 and rooms_completed < 5:
		return true
	if room_type == "shop" and shop_rooms_seen > 0 and rooms_completed < 5:
		return true
	if room_type == "elite_combat" and combat_rooms_cleared < 2:
		return true
	return false

func _room_choice(room_type: String) -> Dictionary:
	match room_type:
		"combat":
			return {"room_type": "combat", "display_name": "Combat", "description": "Ash room + hazards", "icon": "C", "rarity": "common"}
		"elite_combat":
			return {"room_type": "elite_combat", "display_name": "Elite Combat", "description": "Harder fight", "icon": "E", "rarity": "rare"}
		"reward":
			return {"room_type": "reward", "display_name": "Reward", "description": "Claim one upgrade", "icon": "R", "rarity": "common"}
		"fountain":
			return {"room_type": "fountain", "display_name": "Fountain", "description": "Restore health", "icon": "F", "rarity": "safe"}
		"forge":
			return {"room_type": "forge", "display_name": "Forge", "description": "Choose one run-only sword mark", "icon": "G", "rarity": "rare"}
		"shop":
			return {"room_type": "shop", "display_name": "Shop", "description": "Buy one item with Run Ash", "icon": "S", "rarity": "rare"}
		"boss_antechamber":
			return {"room_type": "boss_antechamber", "display_name": "Boss Antechamber", "description": "The Ash Warden gate", "icon": "B", "rarity": "boss"}
		"boss_arena":
			return {"room_type": "boss_arena", "display_name": "The Sentencing Furnace", "description": "Ash Warden boss arena", "icon": "W", "rarity": "boss"}
	return {"room_type": "combat", "display_name": "Combat", "description": "More ash-born enemies", "icon": "C", "rarity": "common"}


func _ensure_run_boon_state() -> void:
	if run_boon_state != null and is_instance_valid(run_boon_state):
		return
	var state_script: Script = load("res://scripts/run/RunBoonState.gd") as Script
	if state_script == null:
		push_warning("[IsoLocalLoop] T-008 could not load RunBoonState.gd")
		return
	run_boon_state = state_script.new() as Node
	if run_boon_state == null:
		push_warning("[IsoLocalLoop] T-008 RunBoonState did not create a Node")
		return
	run_boon_state.name = "LocalRunBoonState"
	add_child(run_boon_state)

func _t008_build_boon_reward_choices() -> Array[Dictionary]:
	_ensure_run_boon_state()
	var pool_script: Script = load("res://scripts/run/BoonRewardPool.gd") as Script
	if pool_script == null:
		return []
	var pool: RefCounted = pool_script.new() as RefCounted
	if pool == null or not pool.has_method("build_choices"):
		return []
	var context: Dictionary = {
		"reward_history": reward_history.duplicate(true),
		"reward_display_history": reward_display_history.duplicate(true),
		"rooms_completed": rooms_completed,
		"reward_rooms_completed": reward_rooms_completed,
	}
	var choices: Variant = pool.call("build_choices", run_boon_state, rooms_completed, reward_rooms_completed, reward_choices_per_room, context)
	if typeof(choices) == TYPE_ARRAY:
		return choices as Array[Dictionary]
	return []

func _t008_try_apply_boon_reward(payload: Dictionary) -> bool:
	var kind: String = str(payload.get("kind", ""))
	if kind != "boon" and kind != "boon_upgrade" and kind != "synergy_boon" and kind != "neutral_reward":
		return false

	var reward_id: String = str(payload.get("reward_id", payload.get("boon_id", "")))
	var display_name: String = str(payload.get("display_name", reward_id))
	reward_history.append(reward_id)
	reward_display_history.append(display_name)

	if kind == "boon" or kind == "boon_upgrade" or kind == "synergy_boon":
		_ensure_run_boon_state()
		if run_boon_state != null and run_boon_state.has_method("add_boon"):
			run_boon_state.call("add_boon", payload)
		_t009_notify_players_of_boon(payload)
		_t008_apply_immediate_boon_effect(payload)
		last_status = "Boon claimed: %s." % display_name
		_debug(last_status)
		return true

	# Neutral rewards are still generated by the boon reward pool, but they map to existing run economy/player effects.
	match reward_id:
		"neutral_max_hp_minor":
			var player: Node = _find_player_node()
			if player != null:
				_add_player_int(player, "max_health", 1)
				_heal_player_flat(1)
		"neutral_ash_sigil_minor":
			run_bonus_ash_sigils += 1
		"neutral_gold_small":
			if Engine.has_singleton("RunEconomyData"):
				pass
		_:
			push_warning("[IsoLocalLoop] Unknown T-008 neutral reward id: %s" % reward_id)
	last_status = "Reward claimed: %s." % display_name
	_debug(last_status)
	return true

func _t008_apply_immediate_boon_effect(payload: Dictionary) -> void:
	# T-008 only applies safe immediate placeholder effects.
	# Full effect hooks arrive in patron-specific tickets.
	var player: Node = _find_player_node()
	if player == null:
		return
	var effect_id: String = str(payload.get("effect_id", ""))
	match effect_id:
		"final_appeal_ultimate_discount":
			if player.get("judgment_ultimate_cost") != null:
				_add_player_float_clamped(player, "judgment_ultimate_cost", -15.0, 35.0, 100.0)
		"heavy_stagger_multiplier":
			if player.get("heavy_stagger_multiplier") != null:
				_add_player_float_clamped(player, "heavy_stagger_multiplier", 0.30, 1.0, 3.0)
		"low_hp_damage_multiplier":
			# Stored in RunBoonState for later logic; no safe direct player stat yet.
			pass
		_:
			pass
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

func _reward_catalogue() -> Array[Dictionary]:
	return [
		_reward_data("light_damage", "Tempered Edge", "common", "Damage", "Light attack damage +1", "Your light attacks deal 1 additional damage for this run.", "Reliable basic sword damage.", "D"),
		_reward_data("light_damage_major", "Martyr's Edge", "rare", "Damage", "Light attack damage +2", "Your light attacks deal 2 additional damage for this run.", "Large increase to fast attack pressure.", "D"),
		_reward_data("heavy_damage", "Grave Weight", "common", "Damage", "Heavy attack damage +1", "Your heavy attacks deal 1 additional damage for this run.", "Safer punish after enemy recovery.", "D"),
		_reward_data("heavy_damage_major", "Executioner's Burden", "rare", "Damage", "Heavy attack damage +2", "Your heavy attacks deal 2 additional damage for this run.", "Heavy punish becomes a major kill tool.", "D"),
		_reward_data("attack_cooldown", "Quick Confession", "common", "Damage", "Light attack cooldown -0.04s", "Your light attacks recover 0.04 seconds faster for this run.", "Faster repeated light attacks.", "D"),
		_reward_data("heavy_recovery", "Condemned Momentum", "uncommon", "Damage", "Heavy attack cooldown -0.06s", "Your heavy attacks recover 0.06 seconds faster for this run.", "Heavy attacks are easier to weave into fights.", "D"),
		_reward_data("max_hp", "Ashen Vigor", "common", "Defense", "Max HP +1", "Increase max HP by 1 and heal 1 HP immediately.", "Small survivability increase.", "H"),
		_reward_data("max_hp_major", "Reliquary Heart", "rare", "Defense", "Max HP +2", "Increase max HP by 2 and heal 2 HP immediately.", "Large survivability increase.", "H"),
		_reward_data("contact_resist", "Iron Penance", "common", "Defense", "Hit i-frames +0.10s", "After taking damage, your invulnerability lasts 0.10 seconds longer.", "More forgiveness after mistakes.", "H"),
		_reward_data("contact_resist_major", "Blackened Aegis", "uncommon", "Defense", "Hit i-frames +0.18s", "After taking damage, your invulnerability lasts 0.18 seconds longer.", "Better protection from chain hits.", "H"),
		_reward_data("heal_now", "Mercy in Ash", "common", "Defense", "Heal 2 HP now", "Recover 2 HP immediately. This does not raise max HP.", "Immediate recovery if the run is bleeding out.", "H"),
		_reward_data("heal_on_clear", "Blood Vow", "uncommon", "Defense", "Heal 1 HP after combat", "After each cleared combat room, recover 1 HP.", "Long-run sustain.", "H"),
		_reward_data("heal_on_clear_major", "Redemption Tithe", "rare", "Defense", "Heal 2 HP after combat", "After each cleared combat room, recover 2 HP.", "Strong sustain for long routes.", "H"),
		_reward_data("dash_cooldown", "Quicker Dash", "common", "Mobility", "Dash cooldown -0.05s", "Your dash recovers 0.05 seconds faster for this run.", "More frequent dodges.", "M"),
		_reward_data("dash_cooldown_major", "Ash Step", "rare", "Mobility", "Dash cooldown -0.09s", "Your dash recovers 0.09 seconds faster for this run.", "High dodge uptime.", "M"),
		_reward_data("move_speed", "Ashen Stride", "common", "Mobility", "Move speed +15", "Move speed increases by 15 for this run.", "Better spacing and hazard avoidance.", "M"),
		_reward_data("move_speed_major", "Pilgrim's Haste", "uncommon", "Mobility", "Move speed +25", "Move speed increases by 25 for this run.", "Stronger repositioning.", "M"),
		_reward_data("dash_duration", "Long Step", "uncommon", "Mobility", "Dash duration +0.03s", "Dash movement lasts 0.03 seconds longer for this run.", "Longer escape and engage distance.", "M"),
		_reward_data("dash_speed", "Cinder Burst", "uncommon", "Mobility", "Dash speed +0.20x", "Dash speed multiplier increases by 0.20 for this run.", "Faster burst movement.", "M"),
		_reward_data("attack_range", "Longer Reach", "common", "Utility", "Attack radius +8", "Your attack radius increases by 8 for this run.", "More reliable sword contact.", "U"),
		_reward_data("attack_range_major", "Saint's Reach", "rare", "Utility", "Attack radius +14", "Your attack radius increases by 14 for this run.", "Large reach boost for safer spacing.", "U"),
		_reward_data("attack_arc", "Wide Judgment", "uncommon", "Utility", "Attack arcs +15°", "Light and heavy attack cones widen by 15 degrees for this run.", "More forgiving directional attacks.", "U"),
		_reward_data("ash_bonus", "Ash Tithe", "common", "Utility", "Bonus Ash Sigils +1", "Gain 1 additional Ash Sigil when the run returns to hub.", "More permanent progress reward.", "U"),
		_reward_data("ash_bonus_major", "Tithe of the Damned", "rare", "Utility", "Bonus Ash Sigils +2", "Gain 2 additional Ash Sigils when the run returns to hub.", "Strong permanent progress reward.", "U"),
		_reward_data("balanced_penance", "Balanced Penance", "uncommon", "Special", "Max HP +1, move speed +10", "Increase max HP by 1, heal 1 HP, and gain 10 move speed for this run.", "Small defense and mobility hybrid.", "S"),
		_reward_data("brutal_penance", "Brutal Penance", "rare", "Special", "Heavy damage +2, move speed -10", "Heavy attacks deal 2 additional damage, but move speed decreases by 10 for this run.", "Risk/reward heavy build.", "S"),
	]

func _reward_data(reward_id: String, display_name: String, rarity: String, category: String, description: String, exact_effect: String, consequence: String, icon: String) -> Dictionary:
	return {
		"kind": "reward",
		"reward_id": reward_id,
		"display_name": display_name,
		"rarity": rarity,
		"category": category,
		"description": description,
		"exact_effect": exact_effect,
		"current_consequence": consequence,
		"icon": icon,
	}

func _build_reward_choices() -> Array[Dictionary]:
	var boon_choices: Array[Dictionary] = _t008_build_boon_reward_choices()
	if not boon_choices.is_empty():
		return boon_choices
	var all_rewards: Array[Dictionary] = _reward_catalogue()
	var picked: Array[Dictionary] = []
	var start: int = (rooms_completed * 3 + reward_rooms_completed * 5 + _choice_generation_index) % all_rewards.size()
	var category_seen: Dictionary = {}
	for i: int in range(all_rewards.size()):
		if picked.size() >= reward_choices_per_room:
			break
		var reward: Dictionary = all_rewards[(start + i) % all_rewards.size()]
		var reward_id: String = str(reward.get("reward_id", ""))
		var category: String = str(reward.get("category", ""))
		if reward_history.has(reward_id) and picked.size() < reward_choices_per_room - 1:
			continue
		if category_seen.has(category) and picked.size() < reward_choices_per_room - 1:
			continue
		picked.append(reward)
		category_seen[category] = true
	if picked.size() < reward_choices_per_room:
		for reward: Dictionary in all_rewards:
			if picked.size() >= reward_choices_per_room:
				break
			var reward_id: String = str(reward.get("reward_id", ""))
			if reward_history.has(reward_id):
				continue
			if not picked.has(reward):
				picked.append(reward)
	while picked.size() < reward_choices_per_room and picked.size() < all_rewards.size():
		picked.append(all_rewards[picked.size()])
	return picked

func _apply_reward(payload: Dictionary) -> void:
	if _t008_try_apply_boon_reward(payload):
		return
	var player: Node = _find_player_node()
	var reward_id: String = str(payload.get("reward_id", ""))
	var display_name: String = str(payload.get("display_name", reward_id))
	reward_history.append(reward_id)
	reward_display_history.append(display_name)
	if player == null:
		last_status = "Reward stored, but player was not found."
		return
	match reward_id:
		"max_hp":
			_add_player_int(player, "max_health", 1)
			_heal_player_flat(1)
		"max_hp_major":
			_add_player_int(player, "max_health", 2)
			_heal_player_flat(2)
		"light_damage":
			_add_player_int(player, "attack_damage", 1)
		"light_damage_major":
			_add_player_int(player, "attack_damage", 2)
		"heavy_damage":
			_add_player_int(player, "heavy_attack_damage", 1)
		"heavy_damage_major":
			_add_player_int(player, "heavy_attack_damage", 2)
		"attack_cooldown":
			_add_player_float_clamped(player, "attack_cooldown", -0.04, 0.14, 9.0)
		"heavy_recovery":
			_add_player_float_clamped(player, "heavy_attack_cooldown", -0.06, 0.24, 9.0)
		"dash_cooldown":
			_add_player_float_clamped(player, "dash_cooldown", -0.05, 0.25, 9.0)
		"dash_cooldown_major":
			_add_player_float_clamped(player, "dash_cooldown", -0.09, 0.22, 9.0)
		"move_speed":
			_add_player_float(player, "move_speed", 15.0)
		"move_speed_major":
			_add_player_float(player, "move_speed", 25.0)
		"dash_duration":
			_add_player_float_clamped(player, "dash_duration", 0.03, 0.05, 0.25)
		"dash_speed":
			_add_player_float_clamped(player, "dash_speed_multiplier", 0.20, 1.0, 4.5)
		"attack_range":
			_add_player_float(player, "attack_radius", 8.0)
		"attack_range_major":
			_add_player_float(player, "attack_radius", 14.0)
		"attack_arc":
			_add_player_float_clamped(player, "light_attack_arc_degrees", 15.0, 45.0, 170.0)
			_add_player_float_clamped(player, "heavy_attack_arawc_degrees", 15.0, 60.0, 190.0)
		"contact_resist":
			_add_player_float(player, "contact_damage_iframe_duration", 0.10)
		"contact_resist_major":
			_add_player_float(player, "contact_damage_iframe_duration", 0.18)
		"heal_now":
			_heal_player_flat(2)
		"heal_on_clear":
			heal_on_room_clear_amount += 1
		"heal_on_clear_major":
			heal_on_room_clear_amount += 2
		"ash_bonus":
			run_bonus_ash_sigils += 1
		"ash_bonus_major":
			run_bonus_ash_sigils += 2
		"balanced_penance":
			_add_player_int(player, "max_health", 1)
			_heal_player_flat(1)
			_add_player_float(player, "move_speed", 10.0)
		"brutal_penance":
			_add_player_int(player, "heavy_attack_damage", 2)
			_add_player_float(player, "move_speed", -10.0)
		_:
			push_warning("[IsoLocalLoop] Unknown reward id: %s" % reward_id)
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()
	last_status = "Reward applied: %s." % display_name
	_debug(last_status)

func _add_player_int(player: Node, property_name: String, delta: int) -> void:
	player.set(property_name, int(player.get(property_name)) + delta)

func _add_player_float(player: Node, property_name: String, delta: float) -> void:
	player.set(property_name, float(player.get(property_name)) + delta)

func _add_player_float_clamped(player: Node, property_name: String, delta: float, minimum: float, maximum: float) -> void:
	var value: float = clampf(float(player.get(property_name)) + delta, minimum, maximum)
	player.set(property_name, value)

func _heal_player_ratio(ratio: float) -> void:
	var player: Node = _find_player_node()
	if player == null:
		return
	var max_hp: int = int(player.get("max_health"))
	var current_hp: int = int(player.get("current_health"))
	var heal_amount: int = maxi(1, int(ceil(float(max_hp) * ratio)))
	player.set("current_health", mini(max_hp, current_hp + heal_amount))
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

func _heal_player_flat(amount: int) -> void:
	var player: Node = _find_player_node()
	if player == null:
		return
	var max_hp: int = int(player.get("max_health"))
	var current_hp: int = int(player.get("current_health"))
	player.set("current_health", mini(max_hp, current_hp + maxi(0, amount)))
	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

func _finish_local_run(victory: bool = true, reason: String = "") -> void:
	run_finished = true
	_advance_in_progress = false
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_return_input_armed = false
	_run_outcome_reason = reason if reason.strip_edges() != "" else ("The Ash Warden has been defeated." if victory else "The Penitent Knight fell.")
	_boss_placeholder = null
	_boss_exit = null
	_clear_route_runtime_nodes()
	if runtime_adapter != null:
		runtime_adapter.clear_runtime_dangers()
	if victory:
		_audio_context("victory")
		_audio_event("victory_sting")
		_set_phase(RunPhase.RUN_VICTORY, _run_outcome_reason)
		last_status = "Demo victory. Press E to return to the Threshold Nave."
		if show_outcome_intro_panel:
			_show_intro("DEMO VICTORY", "The Ash Warden has fallen · Press E to return")
	else:
		_audio_context("death")
		_audio_event("death_sting")
		_set_phase(RunPhase.RUN_DEATH, _run_outcome_reason)
		last_status = "Run ended in death. Press E to return to the Threshold Nave."
		if show_outcome_intro_panel:
			_show_intro("YOU DIED", "The descent rejects the Penitent · Press E to return")
	_record_run_results(victory)
	_update_hud()
	_debug(last_status)

func _record_run_results(victory: bool = true) -> void:
	var total_sigils: int = 0
	if victory:
		total_sigils = maxi(0, demo_victory_ash_sigils + run_bonus_ash_sigils)
	else:
		total_sigils = maxi(0, demo_death_base_ash_sigils + (run_bonus_ash_sigils if death_keeps_bonus_sigils else 0))
	var ash_gained: int = RunEconomyData.add_ash_sigils(total_sigils)
	var summary: Dictionary = {
		"status": "Demo Victory" if victory else "Run Failed",
		"outcome": "victory" if victory else "death",
		"reason": _run_outcome_reason,
		"ash_sigils_earned": ash_gained,
		"ash_sigils_total": RunEconomyData.get_ash_sigils(),
		"rooms_cleared": rooms_completed,
		"rooms_required": rooms_until_run_end,
		"combat_rooms_cleared": combat_rooms_cleared,
		"reward_rooms_completed": reward_rooms_completed,
		"fountain_rooms_completed": fountain_rooms_completed,
		"shop_purchases": shop_purchases,
		"forge_mark": active_forge_mark,
		"boss_defeated": boss_defeated_this_run and victory,
		"patron": "Local Route Loop",
		"boon": _reward_display_summary(),
		"boons": reward_display_history.duplicate(true),
		"route_history": route_history.duplicate(true),
		"room_variant_history": room_variant_history.duplicate(true),
		"run_ash_remaining": run_ash_shards,
		"reward_text": "Ash Sigils +%d" % ash_gained,
		"notes": "V25 demo victory/death loop returned to the Threshold Nave.",
	}
	last_run_summary = summary.duplicate(true)
	RunSessionData.record_completed_run(summary)
	SaveGameData.save_game("run_outcome")
	print("[IsoLocalLoop] Recorded V25/V28 run results: " + str(summary))

func _reward_display_summary() -> String:
	if reward_display_history.is_empty():
		return "No boon claimed"
	var output: String = ""
	for i: int in range(reward_display_history.size()):
		if i > 0:
			output += ", "
		output += reward_display_history[i]
	return output

func _update_return_to_hub_input() -> void:
	var interact_down: bool = _is_interact_down()
	if not interact_down:
		_return_input_armed = true
	if _return_input_armed and _interact_pressed_once():
		_return_to_hub()
	_e_down_previous = interact_down

func _return_to_hub() -> void:
	if hub_scene_path.strip_edges() == "":
		push_warning("[IsoLocalLoop] Cannot return to hub because hub_scene_path is empty.")
		return
	_set_phase(RunPhase.RETURN_TO_HUB, "Returning to hub...")
	last_status = "Returning to hub..."
	_update_hud()
	print("[IsoLocalLoop] Returning to hub: " + hub_scene_path)
	get_tree().change_scene_to_file(hub_scene_path)

func _select_combat_variant(room_type: String) -> String:
	if not enable_circle0_zone_variants or combat_variants.is_empty():
		return "ash_intake_hall"
	var offset: int = elite_combat_variant_offset if room_type == "elite_combat" else 0
	var index: int = (current_depth + combat_rooms_cleared + offset - 1) % combat_variants.size()
	return combat_variants[index]

func _display_variant(variant: String) -> String:
	match variant:
		"ash_intake_hall":
			return "Ash Intake Hall"
		"cinder_drain":
			return "Cinder Drain"
		"furnace_vestibule":
			return "Furnace Vestibule"
		"chain_reservoir":
			return "Chain Reservoir"
		"ember_sorting_floor":
			return "Ember Sorting Floor"
		"reward_altar":
			return "Penitent Reward Altar"
		"ash_fountain":
			return "Ashen Fountain"
		"cold_forge":
			return "Cold Forge"
		"silent_shop":
			return "Silent Ash Merchant"
		"route_gate_crossing":
			return "Route Gate Crossing"
	return variant.capitalize()

func _display_room_type(room_type: String) -> String:
	match room_type:
		"combat":
			return "Combat"
		"elite_combat":
			return "Elite Combat"
		"reward":
			return "Reward"
		"fountain":
			return "Fountain"
		"forge":
			return "Forge"
		"shop":
			return "Shop"
		"choice":
			return "Route Choice"
		"boss_antechamber":
			return "Boss Antechamber"
		"boss_arena":
			return "Boss Arena"
	return room_type.capitalize()

func _show_intro(title: String, subtitle: String) -> void:
	if not show_room_intro_toast:
		return
	if hud_controller != null and is_instance_valid(hud_controller) and hud_controller.has_method("show_room_intro"):
		hud_controller.call("show_room_intro", title, subtitle)
		return
	if hud_layer == null:
		return
	if intro_toast == null or not is_instance_valid(intro_toast):
		intro_toast = IsoRoomIntroToast.new()
		intro_toast.name = "RoomIntroToast"
		hud_layer.add_child(intro_toast)
	intro_toast.show_intro(title, subtitle)

func _get_gate_positions() -> Array[Vector2]:
	if runtime_adapter != null:
		return runtime_adapter.get_choice_gate_positions()
	var center: Vector2 = _get_reward_position()
	return [center + Vector2(-150.0, -95.0), center + Vector2(0.0, -130.0), center + Vector2(150.0, -95.0)]

func _get_reward_position() -> Vector2:
	if runtime_adapter != null:
		return runtime_adapter.get_reward_socket_position()
	return Vector2.ZERO

func _get_boss_spawn_position() -> Vector2:
	if runtime_adapter != null and runtime_adapter.has_method("get_boss_spawn_position"):
		var adapter_pos: Variant = runtime_adapter.call("get_boss_spawn_position")
		if adapter_pos is Vector2:
			return adapter_pos
	return _get_boss_gate_position()

func _get_boss_exit_position() -> Vector2:
	if runtime_adapter != null and runtime_adapter.has_method("get_boss_exit_position"):
		var adapter_pos: Variant = runtime_adapter.call("get_boss_exit_position")
		if adapter_pos is Vector2:
			return adapter_pos
	return _get_boss_gate_position() + boss_exit_position_offset

func _get_boss_gate_position() -> Vector2:
	# V22.3 parser hotfix: V22.2 called this helper but did not define it.
	# Keep the sealed Ash Warden gate inside the current room using the adapter's safe socket.
	if runtime_adapter != null:
		if runtime_adapter.has_method("get_boss_gate_position"):
			var adapter_pos: Variant = runtime_adapter.call("get_boss_gate_position")
			if adapter_pos is Vector2:
				return adapter_pos
		if runtime_adapter.has_method("get_reward_socket_position"):
			var fallback_pos: Variant = runtime_adapter.call("get_reward_socket_position")
			if fallback_pos is Vector2:
				return fallback_pos
	return _get_reward_position()


func _get_room_center_position() -> Vector2:
	if runtime_adapter != null and runtime_adapter.has_method("get_room_center_position"):
		var adapter_pos: Variant = runtime_adapter.call("get_room_center_position")
		if adapter_pos is Vector2:
			return adapter_pos
	return _get_boss_gate_position()

func _get_runtime_parent() -> Node:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return self
	var ysorted: Node = parent_node.find_child("L3_YSorted", true, false)
	if ysorted != null:
		return ysorted
	var runtime: Node = parent_node.find_child("Runtime", true, false)
	if runtime != null:
		return runtime
	return parent_node

func _wire_player_death_signal() -> void:
	var player: Node = _find_player_node()
	if player == null:
		return
	var callback: Callable = Callable(self, "_on_player_died")
	if player.has_signal("died") and not player.is_connected("died", callback):
		player.connect("died", callback)

func _on_player_died() -> void:
	if run_finished:
		return
	if current_phase == RunPhase.HUB or current_phase == RunPhase.RETURN_TO_HUB:
		return
	if current_phase == RunPhase.BOSS and not ash_warden_boss_can_end_run_on_player_death:
		return
	var death_reason: String = "The Penitent Knight fell in Circle 0."
	if current_phase == RunPhase.BOSS:
		death_reason = "The Ash Warden delivered judgment. The run ends in death."
	_finish_local_run(false, death_reason)

func _find_player_node() -> Node:
	var players: Array = get_tree().get_nodes_in_group("player")
	for node: Node in players:
		if node != null:
			return node
	return null

func _clear_route_runtime_nodes() -> void:
	_clear_focus_panel()
	_clear_boss_placeholder_nodes()
	for gate: RunChoiceGate in _active_gates:
		if gate != null and is_instance_valid(gate):
			gate.queue_free()
	_active_gates.clear()
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.queue_free()
	_active_interactables.clear()
	var nodes: Array[Node] = []
	_collect_nodes(get_parent(), nodes)
	for node: Node in nodes:
		if (node is RunChoiceGate) or (node is RunRoomInteractable):
			node.queue_free()

func _setup_hud() -> void:
	if use_v12_run_hud:
		hud_controller = Circle0RunHUD.new()
		hud_controller.name = "Circle0RunHUD"
		add_child(hud_controller)
		hud_layer = hud_controller
		return
	hud_layer = CanvasLayer.new()
	hud_layer.name = "LocalLoopHUD"
	add_child(hud_layer)
	hud_label = Label.new()
	hud_label.name = "LocalLoopStatus"
	hud_label.position = Vector2(18.0, 150.0)
	hud_label.size = Vector2(1040.0, 250.0)
	hud_layer.add_child(hud_label)

func _update_hud() -> void:
	var status_text: String = last_status
	if current_phase == RunPhase.HUB and auto_start_run_on_ready:
		status_text = "Run initialization pending..."
	if run_finished:
		status_text = last_status
	var data: Dictionary = {
		"room_title": last_room_title,
		"room_type": _display_room_type(current_room_type),
		"phase": _phase_label(),
		"depth": current_depth,
		"completed": rooms_completed,
		"total": rooms_until_run_end,
		"status": status_text,
		"objective": _objective_text(),
		"route": _route_summary(),
		"rewards": reward_history.duplicate(true),
		"reward_names": reward_display_history.duplicate(true),
		"fountains": fountain_rooms_completed,
		"bonus_sigils": run_bonus_ash_sigils,
		"currency": "%s | Run Ash: %d | %s" % [RunEconomyData.get_currency_summary_line(), run_ash_shards, PERMANENT_UPGRADE_SCRIPT.build_summary_line()],
		"player": _player_ui_state(),
		"choices": _current_gate_choices.duplicate(true),
		"hazards_active": current_phase == RunPhase.COMBAT,
		"run_finished": run_finished,
		"victory": current_phase == RunPhase.RUN_VICTORY,
		"outcome": last_run_summary.duplicate(true),
		"ash_sigils_earned": int(last_run_summary.get("ash_sigils_earned", 0)),
		"ash_sigils_total": int(last_run_summary.get("ash_sigils_total", RunEconomyData.get_ash_sigils())),
		"boss": {"current_health": _boss_health_current, "max_health": _boss_health_max, "active": current_phase == RunPhase.BOSS, "defeated": boss_defeated_this_run},
	}
	if hud_controller != null and is_instance_valid(hud_controller):
		if current_phase == RunPhase.HUB and not auto_start_run_on_ready:
			hud_controller.visible = false
		else:
			hud_controller.visible = true
		hud_controller.update_from_run_state(data)
		return
	if hud_label == null:
		return
	hud_label.text = "Circle 0 - Demo Route V20\nRoom: %s | Type: %s | Phase: %s | Depth: %d | Completed: %d/%d\n%s\nObjective: %s\n%s\n%s" % [
		last_room_title,
		_display_room_type(current_room_type),
		_phase_label(),
		current_depth,
		rooms_completed,
		rooms_until_run_end,
		status_text,
		_objective_text(),
		"Route: " + _route_summary(),
		RunEconomyData.get_currency_summary_line()
	]

func _player_ui_state() -> Dictionary:
	var player: Node = _find_player_node()
	if player == null:
		return {"current_health": 0, "max_health": 1, "judgment": {"current": 0.0, "max": 100.0, "ratio": 0.0, "is_full": false}}
	var current_hp: int = 0
	var max_hp: int = 1
	var current_value: Variant = player.get("current_health")
	if current_value != null:
		current_hp = int(current_value)
	var max_value: Variant = player.get("max_health")
	if max_value != null:
		max_hp = maxi(1, int(max_value))
	var judgment_state: Dictionary = {"current": 0.0, "max": 100.0, "ratio": 0.0, "is_full": false}
	if player.has_method("get_judgment_ui_state"):
		var judgment_variant: Variant = player.call("get_judgment_ui_state")
		if judgment_variant is Dictionary:
			judgment_state = judgment_variant as Dictionary
	return {
		"current_health": current_hp,
		"max_health": max_hp,
		"judgment": judgment_state,
	}

func _on_interactable_focus_changed(payload: Dictionary, focused: bool) -> void:
	if hud_controller != null and is_instance_valid(hud_controller) and hud_controller.has_method("set_focus_payload"):
		hud_controller.call("set_focus_payload", payload, focused)

func _on_gate_focus_changed(_choice_data: Dictionary, _focused: bool) -> void:
	# Route cards already show left-to-right gate mapping during the route-choice phase.
	pass

func _clear_focus_panel() -> void:
	if hud_controller != null and is_instance_valid(hud_controller) and hud_controller.has_method("clear_focus_payload"):
		hud_controller.call("clear_focus_payload")

func _set_phase(new_phase: int, reason: String = "") -> void:
	if current_phase == new_phase and reason.strip_edges() == "":
		return
	current_phase = new_phase
	_phase_serial += 1
	if reason.strip_edges() != "":
		last_status = reason
	_debug("Phase -> %s | %s" % [_phase_label(), reason])

func _phase_label() -> String:
	match current_phase:
		RunPhase.HUB:
			return "HUB"
		RunPhase.RUN_START:
			return "RUN START"
		RunPhase.ROOM_INTRO:
			return "ROOM INTRO"
		RunPhase.COMBAT:
			return "COMBAT"
		RunPhase.ROOM_CLEAR:
			return "ROOM CLEAR"
		RunPhase.ROUTE_CHOICE:
			return "ROUTE CHOICE"
		RunPhase.REWARD:
			return "REWARD"
		RunPhase.FOUNTAIN:
			return "FOUNTAIN"
		RunPhase.SHOP:
			return "SHOP"
		RunPhase.FORGE:
			return "FORGE"
		RunPhase.BOSS_LOCKED_PLACEHOLDER:
			return "BOSS LOCKED PLACEHOLDER"
		RunPhase.BOSS_ARENA_PLACEHOLDER:
			return "BOSS ARENA PLACEHOLDER"
		RunPhase.BOSS:
			return "BOSS"
		RunPhase.RUN_VICTORY:
			return "RUN VICTORY"
		RunPhase.RUN_DEATH:
			return "RUN DEATH"
		RunPhase.RETURN_TO_HUB:
			return "RETURN TO HUB"
	return "UNKNOWN"

func _objective_text() -> String:
	match current_phase:
		RunPhase.HUB:
			return "Start a run from the Hell Gate."
		RunPhase.RUN_START:
			return "The descent is opening."
		RunPhase.ROOM_INTRO:
			return "Entering chamber."
		RunPhase.COMBAT:
			if current_room_type == "elite_combat":
				return "Defeat the elite encounter. Hazards and enemy telegraphs overlap; do not stand in orange."
			return "Defeat the encounter. Orange hazard rings show where the room will damage you."
		RunPhase.ROOM_CLEAR:
			return "Room clear. Awaiting route gates."
		RunPhase.ROUTE_CHOICE:
			return "Walk into one of the three physical gates and press E. Match them with the HUD cards."
		RunPhase.REWARD:
			return "Choose one boon. Each pedestal shows rarity, category, and exact effect."
		RunPhase.FOUNTAIN:
			return "Use the fountain once to recover health."
		RunPhase.FORGE:
			return "Choose one forge mark for this run."
		RunPhase.SHOP:
			return "Buy one merchant item with Run Ash."
		RunPhase.BOSS_LOCKED_PLACEHOLDER:
			return "You reached the Ash Warden gate. Press E at the seal to enter the Sentencing Furnace placeholder."
		RunPhase.BOSS_ARENA_PLACEHOLDER:
			return "Break the Ash Warden placeholder seal, then use the exit marker."
		RunPhase.BOSS:
			return "Defeat the Ash Warden. Bait him into armed furnace seals to stagger him."
		RunPhase.RUN_VICTORY:
			return "Run complete. Press E to return to the Threshold Nave."
		RunPhase.RUN_DEATH:
			return "The run ended in death. Press E to return to the Threshold Nave."
		RunPhase.RETURN_TO_HUB:
			return "Returning to hub."
	return "Proceed."

func _route_summary() -> String:
	var parts: Array[String] = []
	for entry: Dictionary in route_history:
		if entry.has("room_type"):
			var room_text: String = _display_room_type(str(entry.get("room_type", "?")))
			if entry.has("variant"):
				room_text += "(" + _display_variant(str(entry.get("variant", ""))) + ")"
			parts.append(room_text)
		if parts.size() >= 6:
			break
	if current_phase == RunPhase.ROUTE_CHOICE:
		parts.append("NOW:Choose Gate")
	elif current_phase != RunPhase.HUB and not run_finished:
		parts.append("NOW:" + _display_room_type(current_room_type))
	if parts.is_empty():
		return "NOW:Run Start"
	var output: String = ""
	for i: int in range(parts.size()):
		if i > 0:
			output += "  ->  "
		output += parts[i]
	return output

func _collect_nodes(root: Node, out_nodes: Array[Node]) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		out_nodes.append(child)
		_collect_nodes(child, out_nodes)

func _key_pressed_once(key: Key, was_down: bool) -> bool:
	var down: bool = Input.is_physical_key_pressed(key)
	return down and not was_down

func _is_interact_down() -> bool:
	if InputMap.has_action("interact") and Input.is_action_pressed("interact"):
		return true
	return Input.is_physical_key_pressed(KEY_E)

func _interact_pressed_once() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true
	return Input.is_physical_key_pressed(KEY_E) and not _e_down_previous

func _audio_event(event_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	INFERNAL_AUDIO_SCRIPT.play_event_from_node(self, event_name, _get_room_center_position())

func _audio_context(context_name: String) -> void:
	if INFERNAL_AUDIO_SCRIPT == null:
		return
	INFERNAL_AUDIO_SCRIPT.set_context_from_node(self, context_name)

func _debug(message: String) -> void:
	if print_debug:
		print("[IsoLocalLoop] " + message)

func _grant_boon_payload_to_player(payload: Dictionary) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for player_node: Node in players:
		if player_node != null and is_instance_valid(player_node) and player_node.has_method("receive_run_boon"):
			player_node.call("receive_run_boon", payload)
