#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
ENEMY = ROOT / "scripts/iso/IsoTestEnemy.gd"
CONTROLLER = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"

PLAYER_MEMBERS = r'''
# T-009 Azazel boon runtime. Placeholder combat hooks until final patron/VFX pass.
var t009_owned_boon_ids: Dictionary = {}
var t009_owned_boon_payloads: Dictionary = {}
var t009_light_hit_counter: int = 0
var t009_bound_step_touched: Dictionary = {}
'''

PLAYER_FUNCS = r'''

# T-009 — Called by the run controller when a boon is claimed.
func apply_run_boon(payload: Dictionary) -> void:
	var boon_id: String = str(payload.get("boon_id", payload.get("id", payload.get("reward_id", ""))))
	if boon_id == "":
		return
	t009_owned_boon_ids[boon_id] = true
	t009_owned_boon_payloads[boon_id] = payload.duplicate(true)
	queue_redraw()

func has_run_boon(boon_id: String) -> bool:
	return bool(t009_owned_boon_ids.get(boon_id, false))

func _t009_has_azazel_boon(boon_id: String) -> bool:
	return has_run_boon(boon_id)

func _t009_pre_damage_azazel_effects(target: Node, attack_kind: String, hit_position: Vector2, hit_direction: Vector2) -> void:
	if target == null or not is_instance_valid(target):
		return

	var kind: String = attack_kind.to_lower()

	if (kind.find("q") >= 0 or kind.find("riposte") >= 0) and _t009_has_azazel_boon("azazel_condemned_mark"):
		if target.has_method("apply_azazel_mark"):
			target.call("apply_azazel_mark")
		else:
			target.set_meta("t009_azazel_condemned_mark", true)

	if kind.find("heavy") >= 0:
		if _t009_has_azazel_boon("azazel_iron_sentence") and target.has_method("apply_azazel_bonus_stagger"):
			target.call("apply_azazel_bonus_stagger", 30.0)
		if _t009_has_azazel_boon("azazel_dragged_below") and target.has_method("apply_azazel_pull"):
			target.call("apply_azazel_pull", global_position, 42.0)

	if kind.find("ultimate") >= 0 and _t009_has_azazel_boon("azazel_final_shackle"):
		if target.has_method("apply_azazel_root"):
			target.call("apply_azazel_root", 2.0)

func _t009_modify_azazel_damage(target: Node, damage_amount: int, attack_kind: String) -> int:
	if target == null or not is_instance_valid(target):
		return damage_amount
	var kind: String = attack_kind.to_lower()
	var result: int = damage_amount

	if kind.find("heavy") >= 0 and _t009_has_azazel_boon("azazel_condemned_mark"):
		var marked: bool = false
		if target.has_method("consume_azazel_mark"):
			marked = bool(target.call("consume_azazel_mark"))
		elif target.has_meta("t009_azazel_condemned_mark"):
			marked = bool(target.get_meta("t009_azazel_condemned_mark"))
			target.remove_meta("t009_azazel_condemned_mark")
		if marked:
			result = max(1, int(ceil(float(result) * 1.2)))

	return result

func _t009_after_damage_azazel_effects(target: Node, attack_kind: String, damage_amount: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	var kind: String = attack_kind.to_lower()

	if kind.find("light") >= 0 and _t009_has_azazel_boon("azazel_chain_echo"):
		t009_light_hit_counter += 1
		if t009_light_hit_counter >= 3:
			t009_light_hit_counter = 0
			_t009_chain_lash_nearby(target)

func _t009_chain_lash_nearby(primary_target: Node) -> void:
	if primary_target == null or not is_instance_valid(primary_target):
		return
	if not primary_target is Node2D:
		return
	var origin: Vector2 = (primary_target as Node2D).global_position
	var best: Node = null
	var best_dist: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("iso_test_enemy"):
		if node == primary_target or node == null or not is_instance_valid(node):
			continue
		if not node is Node2D:
			continue
		if not node.has_method("take_damage"):
			continue
		var dist: float = origin.distance_to((node as Node2D).global_position)
		if dist <= 180.0 and dist < best_dist:
			best = node
			best_dist = dist
	if best != null:
		_t004_call_damage_method(best, 1, origin, ((best as Node2D).global_position - origin).normalized(), 60.0, "azazel_chain_echo")

func _t009_update_bound_step_dash_slow() -> void:
	if not _t009_has_azazel_boon("azazel_bound_step"):
		return
	if not has_method("_is_dash_invulnerable"):
		return
	var dash_active: bool = bool(call("_is_dash_invulnerable"))
	if not dash_active:
		t009_bound_step_touched.clear()
		return
	for node: Node in get_tree().get_nodes_in_group("iso_test_enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if not node is Node2D:
			continue
		var key: String = str(node.get_instance_id())
		if t009_bound_step_touched.has(key):
			continue
		if global_position.distance_to((node as Node2D).global_position) <= 48.0:
			t009_bound_step_touched[key] = true
			if node.has_method("apply_azazel_slow"):
				node.call("apply_azazel_slow", 1.5, 0.55)
'''

ENEMY_MEMBERS = r'''
# T-009 Azazel placeholder control state.
var t009_azazel_slow_timer: float = 0.0
var t009_azazel_slow_multiplier: float = 1.0
var t009_azazel_root_timer: float = 0.0
var t009_azazel_marked: bool = false
var t009_azazel_original_move_speed: float = -1.0
'''

ENEMY_FUNCS = r'''

# T-009 — Azazel placeholder enemy effect hooks.
func apply_azazel_mark() -> void:
	t009_azazel_marked = true
	set_meta("t009_azazel_condemned_mark", true)
	modulate = Color(0.82, 0.72, 1.0, 1.0)
	queue_redraw()

func consume_azazel_mark() -> bool:
	var was_marked: bool = t009_azazel_marked or (has_meta("t009_azazel_condemned_mark") and bool(get_meta("t009_azazel_condemned_mark")))
	t009_azazel_marked = false
	if has_meta("t009_azazel_condemned_mark"):
		remove_meta("t009_azazel_condemned_mark")
	return was_marked

func apply_azazel_slow(duration: float = 1.5, multiplier: float = 0.55) -> void:
	t009_azazel_slow_timer = max(t009_azazel_slow_timer, duration)
	t009_azazel_slow_multiplier = clampf(multiplier, 0.05, 1.0)
	_t009_capture_move_speed()

func apply_azazel_root(duration: float = 2.0) -> void:
	t009_azazel_root_timer = max(t009_azazel_root_timer, duration)
	_t009_capture_move_speed()

func apply_azazel_pull(source_position: Vector2, pull_distance: float = 42.0) -> void:
	var dir: Vector2 = (source_position - global_position).normalized()
	if dir.length_squared() <= 0.001:
		return
	global_position += dir * min(pull_distance, 64.0)
	queue_redraw()

func apply_azazel_bonus_stagger(amount: float = 30.0) -> void:
	if has_method("_t006_add_stagger"):
		call("_t006_add_stagger", amount)
	else:
		set_meta("t009_bonus_stagger", amount)

func _t009_capture_move_speed() -> void:
	if t009_azazel_original_move_speed >= 0.0:
		return
	for prop_info: Dictionary in get_property_list():
		if str(prop_info.get("name", "")) == "move_speed":
			t009_azazel_original_move_speed = float(get("move_speed"))
			return

func _t009_update_azazel_enemy_effects(delta: float) -> void:
	if t009_azazel_slow_timer > 0.0:
		t009_azazel_slow_timer = max(0.0, t009_azazel_slow_timer - delta)
	if t009_azazel_root_timer > 0.0:
		t009_azazel_root_timer = max(0.0, t009_azazel_root_timer - delta)

	if t009_azazel_original_move_speed >= 0.0:
		if t009_azazel_root_timer > 0.0:
			set("move_speed", 0.0)
		elif t009_azazel_slow_timer > 0.0:
			set("move_speed", t009_azazel_original_move_speed * t009_azazel_slow_multiplier)
		else:
			set("move_speed", t009_azazel_original_move_speed)

	if t009_azazel_marked:
		modulate = Color(0.82, 0.72, 1.0, 1.0)
	elif t009_azazel_root_timer > 0.0:
		modulate = Color(0.75, 0.78, 1.0, 1.0)
	elif t009_azazel_slow_timer > 0.0:
		modulate = Color(0.78, 0.92, 1.0, 1.0)
'''


def ensure(path: Path, label: str) -> None:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing {label}: {path}")


def insert_after_class_name(text: str, block: str, marker: str) -> str:
    if marker in text:
        return text
    lines = text.splitlines()
    insert_at = None
    for i, line in enumerate(lines):
        if line.strip().startswith("class_name "):
            insert_at = i + 1
            break
    if insert_at is None:
        for i, line in enumerate(lines):
            if line.strip().startswith("extends "):
                insert_at = i + 1
                break
    if insert_at is None:
        raise SystemExit("ERROR: Could not find class_name/extends insertion point")
    lines[insert_at:insert_at] = [""] + block.strip("\n").splitlines() + [""]
    return "\n".join(lines) + "\n"


def append_functions(text: str, funcs: str, marker: str) -> str:
    if marker in text:
        return text
    return text.rstrip() + "\n" + funcs + "\n"


def patch_player() -> None:
    text = PLAYER.read_text()
    text = insert_after_class_name(text, PLAYER_MEMBERS, "var t009_owned_boon_ids")
    text = append_functions(text, PLAYER_FUNCS, "func apply_run_boon")

    # Update dash slow every physics frame if possible.
    if "_t009_update_bound_step_dash_slow()" not in text:
        m = re.search(r'(func\s+_physics_process\s*\([^)]*\)\s*->\s*void:\n)', text)
        if m:
            text = text[:m.end()] + "\t_t009_update_bound_step_dash_slow()\n" + text[m.end():]
        else:
            m = re.search(r'(func\s+_process\s*\([^)]*\)\s*->\s*void:\n)', text)
            if m:
                text = text[:m.end()] + "\t_t009_update_bound_step_dash_slow()\n" + text[m.end():]

    # Route basic direct light attack damage through the ability dispatcher when present.
    text = text.replace(
        'enemy_node.call("take_damage", attack_damage)',
        '_t004_call_damage_method(enemy_node, attack_damage, global_position, facing.normalized(), 38.0, "light_attack")'
    )
    text = text.replace(
        'enemy.call("take_damage", attack_damage)',
        '_t004_call_damage_method(enemy, attack_damage, global_position, facing.normalized(), 38.0, "light_attack")'
    )

    # Inject Azazel hooks in the T-004/T-006 damage dispatcher.
    if "_t009_pre_damage_azazel_effects(target, attack_kind" not in text:
        needle = '''\t# T-006: allow normal enemies to react before damage is applied.\n'''
        repl = '''\t_t009_pre_damage_azazel_effects(target, attack_kind, hit_position, hit_direction)\n\tdamage_amount = _t009_modify_azazel_damage(target, damage_amount, attack_kind)\n\n\t# T-006: allow normal enemies to react before damage is applied.\n'''
        if needle in text:
            text = text.replace(needle, repl, 1)
        else:
            print("WARNING: Could not find T-006 damage dispatcher hook. Azazel damage hooks may not be connected.")

    if "_t009_after_damage_azazel_effects(target, attack_kind" not in text:
        # Add after known normal-enemy direct take_damage path.
        text = text.replace(
            '''\ttarget.call("take_damage", damage_amount)\n\t\treturn\n''',
            '''\ttarget.call("take_damage", damage_amount)\n\t\t_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)\n\t\treturn\n''',
            1
        )
        # Add after callv path.
        text = text.replace(
            '''\tCallable(target, "take_damage").callv(call_args)\n''',
            '''\tCallable(target, "take_damage").callv(call_args)\n\t_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)\n''',
            1
        )
        # Add after boss known signature too.
        text = text.replace(
            '''\t\ttarget.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\treturn\n''',
            '''\t\ttarget.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\t_t009_after_damage_azazel_effects(target, attack_kind, damage_amount)\n\t\treturn\n''',
            1
        )

    PLAYER.write_text(text)
    print("Patched IsoPhysicsTestPlayer.gd for T-009 Azazel boon hooks.")


def patch_enemy() -> None:
    text = ENEMY.read_text()
    text = insert_after_class_name(text, ENEMY_MEMBERS, "var t009_azazel_slow_timer")
    text = append_functions(text, ENEMY_FUNCS, "func apply_azazel_mark")
    if "_t009_update_azazel_enemy_effects(delta)" not in text:
        if "func _t006_update_enemy_interaction(delta: float) -> void:" in text:
            text = text.replace(
                "func _t006_update_enemy_interaction(delta: float) -> void:\n",
                "func _t006_update_enemy_interaction(delta: float) -> void:\n\t_t009_update_azazel_enemy_effects(delta)\n",
                1
            )
        else:
            m = re.search(r'(func\s+_process\s*\(([^)]*)\)\s*->\s*void:\n)', text)
            if m:
                delta_name = m.group(2).split(",")[0].split(":")[0].strip() or "delta"
                text = text[:m.end()] + f"\t_t009_update_azazel_enemy_effects({delta_name})\n" + text[m.end():]
    ENEMY.write_text(text)
    print("Patched IsoTestEnemy.gd for T-009 Azazel control effects.")


def patch_controller() -> None:
    text = CONTROLLER.read_text()

    # Add helper if missing.
    if "func _t009_notify_players_of_boon" not in text:
        insert_before = "\nfunc _claim_boon_payload(payload: Dictionary) -> void:\n"
        helper = r'''
func _t009_notify_players_of_boon(payload: Dictionary) -> void:
	for node: Node in get_tree().get_nodes_in_group("player"):
		if node != null and is_instance_valid(node) and node.has_method("apply_run_boon"):
			node.call("apply_run_boon", payload)
'''
        if insert_before in text:
            text = text.replace(insert_before, "\n" + helper + insert_before, 1)
        else:
            text += "\n" + helper + "\n"

    # Ensure route-gated _claim_boon_payload notifies player.
    if "_t009_notify_players_of_boon(payload)" not in text:
        if "func _claim_boon_payload(payload: Dictionary) -> void:" in text:
            # Prefer after reward_display_history append in the function.
            text = text.replace(
                '''\treward_display_history.append("%s: %s" % [patron_name, display_name])\n''',
                '''\treward_display_history.append("%s: %s" % [patron_name, display_name])\n\t_t009_notify_players_of_boon(payload)\n''',
                1
            )
        # Also notify from old T-008 try apply path if still used.
        text = text.replace(
            '''\t\t_t008_apply_immediate_boon_effect(payload)\n''',
            '''\t\t_t009_notify_players_of_boon(payload)\n\t\t_t008_apply_immediate_boon_effect(payload)\n''',
            1
        )

    CONTROLLER.write_text(text)
    print("Patched IsoRoomLocalLoopController.gd to notify player when boons are claimed.")


def patch_tracker() -> None:
    if not TRACKER.exists():
        return
    try:
        data = json.loads(TRACKER.read_text())
    except Exception:
        return
    def visit(value):
        if isinstance(value, list):
            for item in value:
                if isinstance(item, dict) and item.get("id") == "S-008":
                    item["status"] = "In Progress"
                    item["system"] = "Azazel Boon Mechanics V1"
                    item["need"] = "Make Azazel boons affect combat through stagger/control/Q/heavy/ultimate hooks."
        elif isinstance(value, dict):
            for sub in value.values():
                visit(sub)
    visit(data)
    TRACKER.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main() -> None:
    ensure(PLAYER, "IsoPhysicsTestPlayer.gd")
    ensure(ENEMY, "IsoTestEnemy.gd")
    ensure(CONTROLLER, "IsoRoomLocalLoopController.gd")
    patch_player()
    patch_enemy()
    patch_controller()
    patch_tracker()
    print("T-009 apply complete.")

if __name__ == "__main__":
    main()
