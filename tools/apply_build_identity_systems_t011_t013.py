#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path.cwd()

def p(path: str) -> Path:
    return ROOT / path

def read(path: str) -> str:
    return p(path).read_text()

def write(path: str, text: str) -> None:
    p(path).parent.mkdir(parents=True, exist_ok=True)
    p(path).write_text(text)

def ensure_file(path: str, data: dict) -> None:
    target = p(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(data, indent=2) + "\n")

def insert_before(text: str, anchor: str, block: str, label: str) -> str:
    if block.strip() in text:
        return text
    if anchor not in text:
        raise SystemExit(f"ERROR: anchor not found for {label}: {anchor!r}")
    return text.replace(anchor, "\n" + block + "\n" + anchor, 1)

def insert_after(text: str, anchor: str, block: str, label: str) -> str:
    if block.strip() in text:
        return text
    if anchor not in text:
        raise SystemExit(f"ERROR: anchor not found for {label}: {anchor!r}")
    return text.replace(anchor, anchor + "\n" + block + "\n", 1)

def replace_function(text: str, function_name: str, new_body: str) -> str:
    pattern = re.compile(rf'\nfunc {re.escape(function_name)}\([^\n]*\) -> [^\n]+:\n(?:(?!\nfunc ).*\n)*', re.MULTILINE)
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"ERROR: function not found: {function_name}")
    return text[:match.start()] + "\n" + new_body.rstrip() + "\n" + text[match.end():]

def ensure_data() -> None:
    ensure_file("data/build_identity/forge_marks.json", {
        "forge_marks": [
            {"id":"forge_mark_serrated_edge","display_name":"Serrated Edge","rarity":"common","category":"forge_mark","exact_effect":"Your weapon bites deeper. Light-style hits and repeated strikes apply burning wound pressure.","tags":["forge","weapon","damage_over_time","mammon"]},
            {"id":"forge_mark_grave_weight","display_name":"Grave Weight","rarity":"common","category":"forge_mark","exact_effect":"Your heavy-style attacks hit harder and briefly bind enemies, but this mark favors slower committed attacks.","tags":["forge","weapon","heavy","stagger","azazel"]},
            {"id":"forge_mark_ash_step","display_name":"Ash Step","rarity":"common","category":"forge_mark","exact_effect":"Your dash leaves ash momentum. The next attack after movement gains fire pressure.","tags":["forge","weapon","dash","fire","mammon"]},
        ]
    })
    ensure_file("data/build_identity/weapon_ascensions.json", {
        "weapon_ascensions": [
            {"id":"weapon_ascension_martyr_blade","display_name":"Martyr Blade","rarity":"rare","category":"weapon_ascension","exact_effect":"Risk/reward evolution. Below half health, your Q and ultimate gain extra Judgment damage.","tags":["ascension","risk","judgment","minos"]},
            {"id":"weapon_ascension_warden_breaker","display_name":"Warden Breaker","rarity":"rare","category":"weapon_ascension","exact_effect":"Stagger evolution. Heavy-style hits and Judgment Break deal bonus pressure to bound or staggered enemies.","tags":["ascension","stagger","heavy","azazel"]},
            {"id":"weapon_ascension_ash_serpent_edge","display_name":"Ash Serpent Edge","rarity":"rare","category":"weapon_ascension","exact_effect":"Mobility/fire evolution. Q and ultimate send burning ash pressure through enemies.","tags":["ascension","fire","dash","mammon"]},
        ]
    })
    ensure_file("data/boons/azazel_mammon_synergies.json", {
        "synergies": [
            {"id":"synergy_azazel_mammon_burning_chains","display_name":"Burning Chains","rarity":"rare","category":"synergy","patrons":["patron_azazel_chains","patron_mammon_furnace"],"exact_effect":"Enemies you slow, root, or bind also burn for a short time.","tags":["azazel","mammon","chain","burn","control"]},
            {"id":"synergy_azazel_mammon_furnace_shackles","display_name":"Furnace Shackles","rarity":"rare","category":"synergy","patrons":["patron_azazel_chains","patron_mammon_furnace"],"exact_effect":"Heavy-style hits against burning enemies briefly bind them.","tags":["azazel","mammon","heavy","burn","root"]},
            {"id":"synergy_azazel_mammon_ashen_chain_reaction","display_name":"Ashen Chain Reaction","rarity":"rare","category":"synergy","patrons":["patron_azazel_chains","patron_mammon_furnace"],"exact_effect":"Killing a bound or burning enemy spreads a short burn to nearby enemies.","tags":["azazel","mammon","death","spread","burn"]},
        ]
    })

def patch_controller() -> None:
    path = "scripts/iso/IsoRoomLocalLoopController.gd"
    text = read(path)

    if 'var weapon_ascension_id: String = ""' not in text:
        text = text.replace('var active_forge_mark: String = ""\n',
            'var active_forge_mark: String = ""\nvar weapon_ascension_id: String = ""\nvar weapon_ascension_offer_used: bool = false\n')

    if "weapon_ascension_offer_used = false" not in text:
        if 'active_forge_mark = ""\n' in text:
            text = text.replace('active_forge_mark = ""\n',
                'active_forge_mark = ""\n\tweapon_ascension_id = ""\n\tweapon_ascension_offer_used = false\n', 1)
        else:
            text = text.replace('reward_display_history.clear()\n',
                'reward_display_history.clear()\n\tweapon_ascension_id = ""\n\tweapon_ascension_offer_used = false\n', 1)

    old_claim = "\tvar reward_kind: String = str(payload.get(\"reward_kind\", \"\"))\n\tif reward_kind == \"boon\":\n\t\t_claim_boon_payload(payload)\n\telif reward_kind == \"gold_payout\" or reward_kind == \"health_boost\":\n\t\t_claim_route_payout_payload(payload)\n\telse:\n\t\t_apply_reward(payload)\n"
    new_claim = "\tvar reward_kind: String = str(payload.get(\"reward_kind\", \"\"))\n\tif reward_kind == \"boon\" or reward_kind == \"synergy_boon\":\n\t\t_claim_boon_payload(payload)\n\telif reward_kind == \"forge_mark\" or reward_kind == \"weapon_ascension\":\n\t\t_claim_build_identity_payload(payload)\n\telif reward_kind == \"gold_payout\" or reward_kind == \"health_boost\":\n\t\t_claim_route_payout_payload(payload)\n\telse:\n\t\t_apply_reward(payload)\n"
    if old_claim in text:
        text = text.replace(old_claim, new_claim, 1)

    old_hook = "\tif completed_phase == RunPhase.COMBAT:\n\t\tif rooms_completed == 1 and _pending_reward_source.is_empty():\n\t\t\t_set_first_room_boon_source()\n\t\tif not _pending_reward_source.is_empty():\n\t\t\t_enter_pending_reward_source_room(reason)\n\t\t\treturn\n"
    new_hook = "\tif completed_phase == RunPhase.COMBAT:\n\t\tif rooms_completed == 1 and _pending_reward_source.is_empty():\n\t\t\t_set_first_room_boon_source()\n\t\tif not _pending_reward_source.is_empty():\n\t\t\t_enter_pending_reward_source_room(reason)\n\t\t\treturn\n\t\tif _should_offer_weapon_ascension():\n\t\t\t_enter_weapon_ascension_room(reason)\n\t\t\treturn\n"
    if old_hook in text:
        text = text.replace(old_hook, new_hook, 1)

    choice_anchor = "\tif choices.is_empty():\n\t\treturn _build_reward_choices()\n\treturn choices\n"
    choice_inject = "\tvar synergy_choices: Array[Dictionary] = _build_azazel_mammon_synergy_choices(patron_id)\n\tif not synergy_choices.is_empty() and choices.size() >= 3:\n\t\tchoices[choices.size() - 1] = synergy_choices[0]\n\telif not synergy_choices.is_empty() and choices.size() < reward_choices_per_room:\n\t\tchoices.append(synergy_choices[0])\n\n\tif choices.is_empty():\n\t\treturn _build_reward_choices()\n\treturn choices\n"
    if choice_anchor in text and "_build_azazel_mammon_synergy_choices" not in text:
        text = text.replace(choice_anchor, choice_inject, 1)

    helpers = r"""
func _load_json_dictionary(file_path: String) -> Dictionary:
	var json_text: String = FileAccess.get_file_as_string(file_path)
	if json_text == "":
		return {}
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

func _build_azazel_mammon_synergy_choices(patron_id: String) -> Array[Dictionary]:
	if patron_id != "patron_azazel_chains" and patron_id != "patron_mammon_furnace":
		return []
	if not (_has_claimed_patron_boon("patron_azazel_chains") and _has_claimed_patron_boon("patron_mammon_furnace")):
		return []

	var data: Dictionary = _load_json_dictionary("res://data/boons/azazel_mammon_synergies.json")
	var raw_synergies: Array = data.get("synergies", []) as Array
	var choices: Array[Dictionary] = []
	for raw_item: Variant in raw_synergies:
		if not (raw_item is Dictionary):
			continue
		var synergy: Dictionary = raw_item as Dictionary
		var synergy_id: String = str(synergy.get("id", ""))
		if reward_history.has(synergy_id):
			continue
		choices.append(_synergy_payload_from_data(synergy))
		if choices.size() >= 1:
			break
	return choices

func _has_claimed_patron_boon(patron_id: String) -> bool:
	for entry: String in reward_history:
		if patron_id == "patron_azazel_chains" and entry.find("azazel") >= 0:
			return true
		if patron_id == "patron_mammon_furnace" and entry.find("mammon") >= 0:
			return true
		if patron_id == "patron_minos_judge" and entry.find("minos") >= 0:
			return true
	return false

func _synergy_payload_from_data(synergy: Dictionary) -> Dictionary:
	var synergy_id: String = str(synergy.get("id", "unknown_synergy"))
	var display_name: String = str(synergy.get("display_name", synergy_id))
	var exact_effect: String = str(synergy.get("exact_effect", "Gain a rare cross-patron synergy."))
	return {
		"id": synergy_id,
		"reward_kind": "synergy_boon",
		"boon_id": synergy_id,
		"patron_id": "patron_synergy",
		"patron_name": "AZAZEL + MAMMON",
		"display_name": display_name,
		"rarity": str(synergy.get("rarity", "rare")),
		"category": "synergy",
		"exact_effect": exact_effect,
		"description": exact_effect,
		"body": exact_effect,
		"short_consequence": exact_effect,
		"current_consequence": "Cross-patron synergy: %s" % exact_effect,
		"prompt": "[E] Claim",
		"icon": "⛓",
		"raw_boon": synergy.duplicate(true),
	}

func _build_forge_mark_payloads() -> Array[Dictionary]:
	var data: Dictionary = _load_json_dictionary("res://data/build_identity/forge_marks.json")
	var raw_marks: Array = data.get("forge_marks", []) as Array
	var choices: Array[Dictionary] = []
	for raw_mark: Variant in raw_marks:
		if not (raw_mark is Dictionary):
			continue
		var mark: Dictionary = raw_mark as Dictionary
		var mark_id: String = str(mark.get("id", "unknown_mark"))
		var display_name: String = str(mark.get("display_name", mark_id))
		var exact_effect: String = str(mark.get("exact_effect", "Modify your weapon for this run."))
		choices.append({
			"id": mark_id,
			"reward_kind": "forge_mark",
			"forge_mark_id": mark_id,
			"display_name": display_name,
			"rarity": str(mark.get("rarity", "common")),
			"category": "forge",
			"exact_effect": exact_effect,
			"description": exact_effect,
			"body": exact_effect,
			"short_consequence": exact_effect,
			"current_consequence": "Run weapon mark: %s" % exact_effect,
			"prompt": "[E] Forge",
			"icon": "⌁",
			"raw_mark": mark.duplicate(true),
		})
	return choices

func _build_weapon_ascension_payloads() -> Array[Dictionary]:
	var data: Dictionary = _load_json_dictionary("res://data/build_identity/weapon_ascensions.json")
	var raw_ascensions: Array = data.get("weapon_ascensions", []) as Array
	var choices: Array[Dictionary] = []
	for raw_ascension: Variant in raw_ascensions:
		if not (raw_ascension is Dictionary):
			continue
		var ascension: Dictionary = raw_ascension as Dictionary
		var ascension_id: String = str(ascension.get("id", "unknown_ascension"))
		var display_name: String = str(ascension.get("display_name", ascension_id))
		var exact_effect: String = str(ascension.get("exact_effect", "Evolve your weapon for the rest of this run."))
		choices.append({
			"id": ascension_id,
			"reward_kind": "weapon_ascension",
			"weapon_ascension_id": ascension_id,
			"display_name": display_name,
			"rarity": str(ascension.get("rarity", "rare")),
			"category": "weapon_ascension",
			"exact_effect": exact_effect,
			"description": exact_effect,
			"body": exact_effect,
			"short_consequence": exact_effect,
			"current_consequence": "Weapon evolution: %s" % exact_effect,
			"prompt": "[E] Ascend",
			"icon": "✠",
			"raw_ascension": ascension.duplicate(true),
		})
	return choices

func _spawn_identity_choices(choices: Array[Dictionary], callback: Callable) -> void:
	var center: Vector2 = _get_reward_position()
	var offsets: Array[Vector2] = [Vector2(-128.0, 8.0), Vector2(0.0, -34.0), Vector2(128.0, 8.0)]
	var parent_node: Node = _get_runtime_parent()
	for i: int in range(mini(choices.size(), offsets.size())):
		var item: RunRoomInteractable = RunRoomInteractable.new()
		parent_node.add_child(item)
		item.setup(choices[i], center + offsets[i])
		item.activated.connect(callback)
		if item.has_signal("focus_changed"):
			item.focus_changed.connect(_on_interactable_focus_changed)
		_active_interactables.append(item)

func _enter_weapon_ascension_room(reason: String) -> void:
	weapon_ascension_offer_used = true
	current_room_type = "reward"
	current_room_variant = "weapon_ascension"
	last_room_title = "Weapon Ascension"
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "The Penitent Blade demands a form.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation("reward", current_depth, "reward_altar")
		runtime_adapter.prepare_non_combat_room()
	_spawn_identity_choices(_build_weapon_ascension_payloads(), _on_build_identity_chosen)
	_show_intro(last_room_title, "Choose one weapon evolution")
	last_status = "Weapon Ascension. Choose one evolution for the rest of this run."
	_room_completion_pending = false
	_set_phase(RunPhase.REWARD, last_status)
	_debug("%s after %s" % [last_status, reason])

func _should_offer_weapon_ascension() -> bool:
	if weapon_ascension_offer_used:
		return false
	if weapon_ascension_id != "":
		return false
	return rooms_completed >= 3

func _on_build_identity_chosen(payload: Dictionary) -> void:
	if _room_completion_pending:
		return
	for item: RunRoomInteractable in _active_interactables:
		if item != null and is_instance_valid(item):
			item.mark_used()
	_audio_event("reward_claim")
	_claim_build_identity_payload(payload)
	_clear_active_interactables()
	_set_phase(RunPhase.ROOM_CLEAR, "Claimed: %s." % str(payload.get("display_name", "Unknown")))
	_room_completion_pending = false
	if route_choice_enabled:
		_schedule_route_choice_spawn()
	else:
		current_depth += 1
		_enter_combat_room("combat")

func _claim_build_identity_payload(payload: Dictionary) -> void:
	var reward_kind: String = str(payload.get("reward_kind", ""))
	var display_name: String = str(payload.get("display_name", "Unknown"))

	if reward_kind == "forge_mark":
		active_forge_mark = str(payload.get("forge_mark_id", payload.get("id", "")))
		forge_marks_chosen.append(active_forge_mark)
		reward_history.append(active_forge_mark)
		reward_display_history.append("Forge: " + display_name)
	elif reward_kind == "weapon_ascension":
		weapon_ascension_id = str(payload.get("weapon_ascension_id", payload.get("id", "")))
		reward_history.append(weapon_ascension_id)
		reward_display_history.append("Ascension: " + display_name)

	_grant_build_identity_payload_to_player(payload)
	last_status = "Claimed %s." % display_name

func _grant_build_identity_payload_to_player(payload: Dictionary) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for player: Node in players:
		if player != null and is_instance_valid(player) and player.has_method("apply_build_identity_payload"):
			player.call("apply_build_identity_payload", payload)
"""
    text = insert_before(text, "\nfunc _build_gate_choices() -> Array[Dictionary]:\n", helpers, "identity helpers")

    forge_body = r"""func _enter_forge_room() -> void:
	current_room_type = "forge"
	current_room_variant = "cold_forge"
	last_room_title = "Cold Forge"
	_room_completion_pending = false
	_clear_route_runtime_nodes()
	_set_phase(RunPhase.ROOM_INTRO, "Entering the Cold Forge.")
	if runtime_adapter != null:
		runtime_adapter.configure_room_presentation(current_room_type, current_depth, current_room_variant)
		runtime_adapter.prepare_non_combat_room()
	_spawn_identity_choices(_build_forge_mark_payloads(), _on_build_identity_chosen)
	_show_intro(last_room_title, "Choose one weapon mark")
	last_status = "Cold Forge. Choose one run-only weapon mark."
	_set_phase(RunPhase.FORGE, last_status)
	_debug(last_status)
"""
    if "func _enter_forge_room() -> void:" in text:
        text = replace_function(text, "_enter_forge_room", forge_body)

    if "func _claim_boon_payload" in text and "_grant_build_identity_payload_to_player(payload)" not in text.split("func _claim_boon_payload",1)[-1][:1200]:
        text = text.replace('reward_display_history.append("%s: %s" % [patron_name, display_name])\n',
                            'reward_display_history.append("%s: %s" % [patron_name, display_name])\n\t_grant_build_identity_payload_to_player(payload)\n', 1)

    write(path, text)

def patch_player() -> None:
    path = "scripts/iso/IsoPhysicsTestPlayer.gd"
    text = read(path)

    if "var t011_build_identity_ids: Dictionary = {}" not in text:
        block = """
# T-011/T-012/T-013 build identity state.
var t011_build_identity_ids: Dictionary = {}
var t012_active_forge_mark_id: String = ""
var t013_weapon_ascension_id: String = ""
var t011_last_build_identity_debug: String = ""
"""
        if "class_name IsoPhysicsTestPlayer\n" in text:
            text = insert_after(text, "class_name IsoPhysicsTestPlayer\n", block, "player vars")
        else:
            text = block + "\n" + text

    funcs = r"""
func apply_build_identity_payload(payload: Dictionary) -> void:
	var reward_kind: String = str(payload.get("reward_kind", ""))
	var id_value: String = str(payload.get("boon_id", payload.get("forge_mark_id", payload.get("weapon_ascension_id", payload.get("id", "")))))
	var display_name: String = str(payload.get("display_name", id_value))

	if id_value == "":
		return

	t011_build_identity_ids[id_value] = true

	if reward_kind == "forge_mark":
		t012_active_forge_mark_id = id_value
	elif reward_kind == "weapon_ascension":
		t013_weapon_ascension_id = id_value

	t011_last_build_identity_debug = "%s gained" % display_name
	print("[BuildIdentity] Player received: %s (%s)" % [display_name, id_value])

func t011_has_build_identity(id_value: String) -> bool:
	return bool(t011_build_identity_ids.get(id_value, false))

func _t011_modify_damage_for_build_identity(base_damage: int, attack_kind: String) -> int:
	var modified: int = base_damage
	var kind: String = attack_kind.to_lower()

	if t012_active_forge_mark_id == "forge_mark_grave_weight" and (kind.find("heavy") >= 0 or kind.find("ultimate") >= 0):
		modified += 1
	if t012_active_forge_mark_id == "forge_mark_serrated_edge" and (kind.find("light") >= 0 or kind.find("attack") >= 0):
		modified += 1
	if t013_weapon_ascension_id == "weapon_ascension_warden_breaker" and (kind.find("heavy") >= 0 or kind.find("ultimate") >= 0):
		modified += 1
	if t013_weapon_ascension_id == "weapon_ascension_ash_serpent_edge" and (kind.find("q") >= 0 or kind.find("ultimate") >= 0):
		modified += 1

	return maxi(1, modified)

func _t011_apply_build_identity_status_to_target(target: Node, attack_kind: String, hit_position: Vector2) -> void:
	if target == null or not is_instance_valid(target):
		return

	var kind: String = attack_kind.to_lower()

	if t012_active_forge_mark_id == "forge_mark_serrated_edge" and target.has_method("t011_apply_burning_chains"):
		target.call("t011_apply_burning_chains", 1.5)

	if t012_active_forge_mark_id == "forge_mark_grave_weight" and (kind.find("heavy") >= 0 or kind.find("ultimate") >= 0):
		if target.has_method("t011_apply_furnace_shackles"):
			target.call("t011_apply_furnace_shackles", 0.75)

	if t013_weapon_ascension_id == "weapon_ascension_ash_serpent_edge" and (kind.find("q") >= 0 or kind.find("ultimate") >= 0):
		if target.has_method("t011_apply_burning_chains"):
			target.call("t011_apply_burning_chains", 2.0)

	if t011_has_build_identity("synergy_azazel_mammon_burning_chains"):
		if target.has_method("t011_apply_burning_chains") and (kind.find("q") >= 0 or kind.find("heavy") >= 0 or kind.find("ultimate") >= 0):
			target.call("t011_apply_burning_chains", 2.0)

	if t011_has_build_identity("synergy_azazel_mammon_furnace_shackles"):
		if target.has_method("t011_apply_furnace_shackles") and (kind.find("heavy") >= 0 or kind.find("ultimate") >= 0):
			target.call("t011_apply_furnace_shackles", 1.0)
"""
    if "func apply_build_identity_payload" not in text:
        if "\nfunc _draw" in text:
            text = insert_before(text, "\nfunc _draw", funcs, "player functions")
        else:
            text += "\n" + funcs

    if "func _t004_call_damage_method" in text:
        if "damage_amount = _t011_modify_damage_for_build_identity(damage_amount, attack_kind)" not in text:
            text = text.replace("\tvar method_args: Array = []\n\tfor raw_method_info: Dictionary in target.get_method_list():",
                                "\tdamage_amount = _t011_modify_damage_for_build_identity(damage_amount, attack_kind)\n\n\tvar method_args: Array = []\n\tfor raw_method_info: Dictionary in target.get_method_list():", 1)
        text = text.replace('target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\treturn',
                            'target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\t_t011_apply_build_identity_status_to_target(target, attack_kind, hit_position)\n\t\treturn')
        text = text.replace('target.call("take_damage", damage_amount)\n\t\treturn',
                            'target.call("take_damage", damage_amount)\n\t\t_t011_apply_build_identity_status_to_target(target, attack_kind, hit_position)\n\t\treturn')
        text = text.replace('Callable(target, "take_damage").callv(call_args)\n',
                            'Callable(target, "take_damage").callv(call_args)\n\t_t011_apply_build_identity_status_to_target(target, attack_kind, hit_position)\n')

    text = text.replace('enemy_node.call("take_damage", attack_damage)',
                        'enemy_node.call("take_damage", _t011_modify_damage_for_build_identity(attack_damage, "light_attack"))\n\t\t\t_t011_apply_build_identity_status_to_target(enemy_node, "light_attack", global_position)')

    write(path, text)

def patch_enemy() -> None:
    path = "scripts/iso/IsoTestEnemy.gd"
    text = read(path)

    if "var t011_burning_chains_timer: float = 0.0" not in text:
        block = """
# T-011/T-012/T-013 build identity status placeholders.
var t011_burning_chains_timer: float = 0.0
var t011_burning_tick_timer: float = 0.0
var t011_furnace_shackle_timer: float = 0.0
"""
        if "var t006_base_modulate_captured: bool = false\n" in text:
            text = insert_after(text, "var t006_base_modulate_captured: bool = false\n", block, "enemy vars")
        else:
            text = text.replace("class_name IsoTestEnemy\n", "class_name IsoTestEnemy\n" + block + "\n", 1)

    if "_t011_update_build_identity_status(delta)" not in text:
        text = text.replace("_t006_update_enemy_interaction(delta)\n",
                            "_t006_update_enemy_interaction(delta)\n\t_t011_update_build_identity_status(delta)\n", 1)

    if "_t011_apply_build_identity_modulate()" not in text:
        text = text.replace("_update_damage_numbers(delta)\n",
                            "_update_damage_numbers(delta)\n\t_t011_apply_build_identity_modulate()\n", 1)

    funcs = r"""
func t011_apply_burning_chains(duration: float = 2.0) -> void:
	t011_burning_chains_timer = maxf(t011_burning_chains_timer, duration)
	t011_burning_tick_timer = minf(t011_burning_tick_timer, 0.25)
	queue_redraw()

func t011_apply_furnace_shackles(duration: float = 0.8) -> void:
	t011_furnace_shackle_timer = maxf(t011_furnace_shackle_timer, duration)
	if "t009_azazel_root_timer" in self:
		set("t009_azazel_root_timer", maxf(float(get("t009_azazel_root_timer")), duration))
	queue_redraw()

func _t011_update_build_identity_status(delta: float) -> void:
	if is_dead:
		return

	if t011_furnace_shackle_timer > 0.0:
		t011_furnace_shackle_timer = maxf(0.0, t011_furnace_shackle_timer - delta)
		_knockback_velocity = Vector2.ZERO

	if t011_burning_chains_timer > 0.0:
		t011_burning_chains_timer = maxf(0.0, t011_burning_chains_timer - delta)
		t011_burning_tick_timer -= delta
		if t011_burning_tick_timer <= 0.0:
			t011_burning_tick_timer = 0.75
			take_damage(1)

func _t011_apply_build_identity_modulate() -> void:
	if t011_burning_chains_timer > 0.0:
		modulate = Color(1.25, 0.72, 0.38, 1.0)
	elif t011_furnace_shackle_timer > 0.0:
		modulate = Color(0.75, 0.88, 1.2, 1.0)
	elif t006_hit_react_timer <= 0.0 and t006_stagger_timer <= 0.0 and t006_vulnerability_timer <= 0.0:
		modulate = Color.WHITE
"""
    if "func t011_apply_burning_chains" not in text:
        if "\nfunc _draw" in text:
            text = insert_before(text, "\nfunc _draw", funcs, "enemy functions")
        else:
            text += "\n" + funcs

    write(path, text)

def patch_docs() -> None:
    if not p("docs/BUILD_IDENTITY_SYSTEMS_T011_T013.md").exists():
        write("docs/BUILD_IDENTITY_SYSTEMS_T011_T013.md", "# T-011/T-012/T-013 — Build Identity Systems Pass\n")

def main() -> None:
    ensure_data()
    patch_controller()
    patch_player()
    patch_enemy()
    patch_docs()
    print("Applied T-011/T-012/T-013 Build Identity Systems Pass.")

if __name__ == "__main__":
    main()
