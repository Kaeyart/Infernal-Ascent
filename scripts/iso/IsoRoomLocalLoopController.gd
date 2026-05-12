extends Node2D

class_name IsoRoomLocalLoopController
## V14 — Run Flow Consistency Pass.
## V19 — Reward Consistency Pass extends the existing loop with a standardized temporary reward catalogue.
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
	RUN_VICTORY,
	RUN_DEATH,
	RETURN_TO_HUB,
}

@export var rooms_until_run_end: int = 7
@export var restart_key_enabled: bool = true
@export var return_to_hub_enabled: bool = true
@export var hub_scene_path: String = "res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn"
@export var ash_sigils_per_completed_run: int = 1
@export var print_debug: bool = true
@export var auto_start_run_on_ready: bool = true

@export_category("V10 Route Loop")
@export var route_choice_enabled: bool = true
@export var gate_spawn_delay: float = 0.35
@export var reward_choices_per_room: int = 3
@export var heal_on_fountain_ratio: float = 0.55
@export var show_route_debug_labels: bool = true
@export var force_first_choice_reward: bool = true

@export_category("V11/V12/V13 Circle 0 Zone")
@export var enable_circle0_zone_variants: bool = true
@export var show_room_intro_toast: bool = true
@export var use_v12_run_hud: bool = true # Compatibility flag: true instantiates Circle0RunHUD / InfernalUIRoot.
@export var route_gate_room_variant: String = "route_gate_crossing"
@export var combat_variants: Array[String] = ["ash_intake_hall", "cinder_drain", "furnace_vestibule", "chain_reservoir", "ember_sorting_floor", "penitent_crossing"]
@export var elite_combat_variant_offset: int = 2

var shared_patron_manager: PatronRunManager = null
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
var _last_selected_gate_name: String = ""
var _room_completion_pending: bool = false
var _route_choice_spawn_pending: bool = false
var _phase_serial: int = 0
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var hud_controller: Circle0RunHUD = null
var intro_toast: IsoRoomIntroToast = null
var last_status: String = "Run state initializing."
var last_room_title: String = "Threshold Nave"

func _ready() -> void:
	_set_phase(RunPhase.HUB, "Local loop node created.")
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
	if run_finished and return_to_hub_enabled:
		_update_return_to_hub_input()
	_update_hud()

func start_new_local_run() -> void:
	_reset_run_counters()
	_set_phase(RunPhase.RUN_START, "Circle 0 run restarted.")
	if shared_patron_manager != null:
		shared_patron_manager.reset_run()
	_enter_combat_room("combat")
	_debug("Circle 0 route run restarted.")

func _reset_run_counters() -> void:
	_clear_route_runtime_nodes()
	rooms_completed = 0
	current_room_cycle = 1
	current_depth = 1
	current_room_type = "combat"
	current_room_variant = _select_combat_variant("combat")
	combat_rooms_cleared = 0
	reward_rooms_completed = 0
	fountain_rooms_completed = 0
	forge_rooms_seen = 0
	shop_rooms_seen = 0
	run_bonus_ash_sigils = 0
	heal_on_room_clear_amount = 0
	route_history.clear()
	_current_gate_choices.clear()
	_last_selected_gate_name = ""
	reward_history.clear()
	reward_display_history.clear()
	room_variant_history.clear()
	run_finished = false
	_advance_in_progress = false
	_room_completion_pending = false
	_route_choice_spawn_pending = false
	_return_input_armed = false

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
	if heal_on_room_clear_amount > 0:
		_heal_player_flat(heal_on_room_clear_amount)
	_complete_current_room("Combat cleared in %s" % _display_variant(current_room_variant))

func _complete_current_room(reason: String) -> void:
	if run_finished:
		return
	if not _phase_can_complete_room():
		_debug("Ignored room completion from invalid phase %s: %s" % [_phase_label(), reason])
		return
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
	_set_phase(RunPhase.ROOM_CLEAR, last_status)
	_debug(last_status)
	if rooms_completed >= rooms_until_run_end:
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
		or current_phase == RunPhase.BOSS_LOCKED_PLACEHOLDER

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
	var choices: Array[Dictionary] = _build_gate_choices()
	_current_gate_choices = choices.duplicate(true)
	var positions: Array[Vector2] = _get_gate_positions()
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(choices.size()):
		var gate: RunChoiceGate = RunChoiceGate.new()
		parent_node.add_child(gate)
		gate.setup(choices[i], positions[i % positions.size()])
		gate.gate_chosen.connect(_on_route_gate_chosen)
		if gate.has_signal("gate_focus_changed"):
			gate.gate_focus_changed.connect(_on_gate_focus_changed)
		_active_gates.append(gate)
	last_status = "Choose one of three physical gates. The HUD cards match the physical gates left-to-right."
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
	_last_selected_gate_name = str(choice_data.get("display_name", "Unknown Gate"))
	_clear_route_runtime_nodes()
	_current_gate_choices.clear()
	current_depth += 1
	current_room_type = str(choice_data.get("room_type", "combat"))
	last_status = "Entering: %s." % str(choice_data.get("display_name", current_room_type))
	match current_room_type:
		"combat", "elite_combat":
			_enter_combat_room(current_room_type)
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
	_show_intro(last_room_title, "Choose one physical upgrade")
	last_status = "Reward room. Pick exactly one physical upgrade, then new route gates appear."
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
		"description": "Restore HP once",
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
	var data: Dictionary = {
		"kind": "forge",
		"display_name": "Cold Forge",
		"description": "Weapon system reserved",
	}
	_spawn_single_interactable(data, _get_reward_position(), _on_forge_used)
	_show_intro(last_room_title, "The forge is cold")
	last_status = "Forge room placeholder. Use the cold forge to continue. Full weapon mutation comes later."
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
	var data: Dictionary = {
		"kind": "shop",
		"display_name": "Silent Merchant",
		"description": "Economy reserved",
	}
	_spawn_single_interactable(data, _get_reward_position(), _on_shop_used)
	_show_intro(last_room_title, "The merchant watches")
	last_status = "Shop room placeholder. Use the merchant marker to continue. Economy comes later."
	_set_phase(RunPhase.SHOP, last_status)
	_debug(last_status)

func _spawn_reward_choices() -> void:
	var rewards: Array[Dictionary] = _build_reward_choices()
	var center: Vector2 = _get_reward_position()
	var offsets: Array[Vector2] = [Vector2(-128.0, 8.0), Vector2(0.0, -34.0), Vector2(128.0, 8.0)]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(mini(reward_choices_per_room, rewards.size())):
		var item: RunRoomInteractable = RunRoomInteractable.new()
		parent_node.add_child(item)
		item.setup(rewards[i], center + offsets[i % offsets.size()])
		item.activated.connect(_on_reward_chosen)
		if item.has_signal("focus_changed"):
			item.focus_changed.connect(_on_interactable_focus_changed)
		_active_interactables.append(item)

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
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.mark_used()
	_apply_reward(payload)
	reward_rooms_completed += 1
	_complete_current_room("Reward claimed: %s" % str(payload.get("display_name", "Unknown")))

func _on_fountain_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.FOUNTAIN:
		return
	if _room_completion_pending:
		return
	fountain_rooms_completed += 1
	_heal_player_ratio(heal_on_fountain_ratio)
	_complete_current_room("Fountain used")

func _on_forge_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.FORGE:
		return
	if _room_completion_pending:
		return
	_complete_current_room("The forge is cold")

func _on_shop_used(_payload: Dictionary) -> void:
	if current_phase != RunPhase.SHOP:
		return
	if _room_completion_pending:
		return
	_complete_current_room("The silent merchant has nothing yet")

func _build_gate_choices() -> Array[Dictionary]:
	_choice_generation_index += 1
	var choices: Array[Dictionary] = []
	choices.append(_room_choice("combat"))
	if force_first_choice_reward and rooms_completed == 1 and reward_rooms_completed <= 0:
		choices.append(_room_choice("reward"))
		choices.append(_room_choice("fountain"))
		return choices
	var pool: Array[String] = ["reward", "fountain", "combat", "forge", "shop", "elite_combat"]
	var start: int = (_choice_generation_index + rooms_completed + combat_rooms_cleared) % pool.size()
	for i: int in range(pool.size()):
		if choices.size() >= 3:
			break
		var room_type: String = pool[(start + i) % pool.size()]
		if _should_skip_room_type(room_type, choices):
			continue
		choices.append(_room_choice(room_type))
	while choices.size() < 3:
		choices.append(_room_choice("combat"))
	return choices

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
			return {"room_type": "forge", "display_name": "Forge", "description": "Reserved weapon system", "icon": "G", "rarity": "rare"}
		"shop":
			return {"room_type": "shop", "display_name": "Shop", "description": "Reserved economy", "icon": "S", "rarity": "rare"}
	return {"room_type": "combat", "display_name": "Combat", "description": "More ash-born enemies", "icon": "C", "rarity": "common"}

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
			_add_player_float_clamped(player, "heavy_attack_arc_degrees", 15.0, 60.0, 190.0)
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
	_clear_route_runtime_nodes()
	if runtime_adapter != null:
		runtime_adapter.clear_runtime_dangers()
	if victory:
		_set_phase(RunPhase.RUN_VICTORY, reason if reason.strip_edges() != "" else "Run complete.")
		last_status = "Run complete. Press E to return to the Threshold Nave."
	else:
		_set_phase(RunPhase.RUN_DEATH, reason if reason.strip_edges() != "" else "The Penitent Knight fell.")
		last_status = "Run failed. Press E to return to the Threshold Nave."
	_record_run_results(victory)
	_update_hud()
	_debug(last_status)

func _record_run_results(victory: bool = true) -> void:
	var total_sigils: int = ash_sigils_per_completed_run + run_bonus_ash_sigils
	if not victory:
		total_sigils = max(0, run_bonus_ash_sigils)
	var summary: Dictionary = {
		"ash_sigils_earned": total_sigils,
		"rooms_cleared": rooms_completed,
		"patron": "Local Route Loop",
		"boon": _reward_display_summary(),
		"victory": victory,
		"notes": "V14 run state test returned to the Threshold Nave.",
	}
	RunSessionData.record_completed_run(summary)
	print("[IsoLocalLoop] Recorded V14 run results: " + str(summary))

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

func _find_player_node() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node: Node in players:
		if node != null:
			return node
	return null

func _clear_route_runtime_nodes() -> void:
	_clear_focus_panel()
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
		"currency": RunEconomyData.get_currency_summary_line(),
		"player": _player_ui_state(),
		"choices": _current_gate_choices.duplicate(true),
		"hazards_active": current_phase == RunPhase.COMBAT,
		"run_finished": run_finished,
		"victory": current_phase == RunPhase.RUN_VICTORY,
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
	hud_label.text = "Circle 0 - Run Flow V14\nRoom: %s | Type: %s | Phase: %s | Depth: %d | Completed: %d/%d\n%s\nObjective: %s\n%s\n%s" % [
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
		return {"current_health": 0, "max_health": 1}
	var current_hp: int = 0
	var max_hp: int = 1
	var current_value: Variant = player.get("current_health")
	if current_value != null:
		current_hp = int(current_value)
	var max_value: Variant = player.get("max_health")
	if max_value != null:
		max_hp = maxi(1, int(max_value))
	return {
		"current_health": current_hp,
		"max_health": max_hp,
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
			return "Use the cold forge marker to continue. Full forge mechanics come later."
		RunPhase.SHOP:
			return "Use the silent merchant marker to continue. Full economy comes later."
		RunPhase.BOSS_LOCKED_PLACEHOLDER:
			return "Boss route is locked until the demo boss milestone."
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

func _debug(message: String) -> void:
	if print_debug:
		print("[IsoLocalLoop] " + message)
