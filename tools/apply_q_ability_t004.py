#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path.cwd()
PLAYER_SCRIPT = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
TRACKER_JSON = ROOT / "data/production/demo_asset_tracker.json"
DOC_PATH = ROOT / "docs/Q_ABILITY_PLACEHOLDER_T004.md"

Q_CONFIG_BLOCK = '\n# T004_Q_ABILITY_PLACEHOLDER_START\n@export_group("T004 Q Ability Placeholder")\n@export var q_ability_enabled: bool = true\n@export var q_ability_cooldown: float = 4.25\n@export var q_ability_damage: int = 2\n@export var q_ability_radius: float = 82.0\n@export var q_ability_forward_dot: float = 0.18\n@export var q_ability_knockback: float = 210.0\n@export var q_ability_judgment_gain_on_hit: float = 12.0\n@export var q_ability_recovery_time: float = 0.34\n@export var q_ability_flash_time: float = 0.18\n@export var show_debug_q_ability: bool = true\n\nvar q_ability_cooldown_remaining: float = 0.0\nvar _t004_q_recovery_remaining: float = 0.0\nvar _t004_q_flash_remaining: float = 0.0\nvar _t004_q_key_was_down: bool = false\nvar _t004_q_hit_targets: Array = []\nvar _t004_q_last_direction: Vector2 = Vector2.DOWN\n# T004_Q_ABILITY_PLACEHOLDER_END\n'
Q_FUNCTIONS_BLOCK = '\n\n# T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_START\nfunc _t004_tick_q_ability(delta: float) -> void:\n\tif q_ability_cooldown_remaining > 0.0:\n\t\tq_ability_cooldown_remaining = maxf(0.0, q_ability_cooldown_remaining - delta)\n\tif _t004_q_recovery_remaining > 0.0:\n\t\t_t004_q_recovery_remaining = maxf(0.0, _t004_q_recovery_remaining - delta)\n\tif _t004_q_flash_remaining > 0.0:\n\t\t_t004_q_flash_remaining = maxf(0.0, _t004_q_flash_remaining - delta)\n\t\tqueue_redraw()\n\n\nfunc _t004_consume_q_input() -> bool:\n\tvar pressed_action: bool = false\n\tif InputMap.has_action("player_q"):\n\t\tpressed_action = Input.is_action_just_pressed("player_q")\n\n\tvar key_is_down: bool = Input.is_key_pressed(KEY_Q)\n\tvar pressed_key: bool = key_is_down and not _t004_q_key_was_down\n\t_t004_q_key_was_down = key_is_down\n\n\treturn pressed_action or pressed_key\n\n\nfunc _t004_try_start_q_ability() -> void:\n\tif not q_ability_enabled:\n\t\treturn\n\tif q_ability_cooldown_remaining > 0.0:\n\t\treturn\n\tif _t004_q_recovery_remaining > 0.0:\n\t\treturn\n\n\t_t004_q_last_direction = facing.normalized()\n\tif _t004_q_last_direction.length_squared() <= 0.001:\n\t\t_t004_q_last_direction = Vector2.DOWN\n\n\tq_ability_cooldown_remaining = q_ability_cooldown\n\t_t004_q_recovery_remaining = q_ability_recovery_time\n\t_t004_q_flash_remaining = q_ability_flash_time\n\t_t004_q_hit_targets.clear()\n\n\t_t004_apply_q_ability_hit()\n\tqueue_redraw()\n\n\nfunc _t004_apply_q_ability_hit() -> void:\n\tvar targets: Array = []\n\t_t004_append_group_nodes(targets, "attack_target")\n\t_t004_append_group_nodes(targets, "enemy")\n\t_t004_append_group_nodes(targets, "boss")\n\n\tvar hit_count: int = 0\n\tfor target_obj in targets:\n\t\tvar target: Node2D = target_obj as Node2D\n\t\tif target == null:\n\t\t\tcontinue\n\t\tif target == self:\n\t\t\tcontinue\n\t\tif not is_instance_valid(target):\n\t\t\tcontinue\n\n\t\tvar delta_to_target: Vector2 = target.global_position - global_position\n\t\tvar distance_to_target: float = delta_to_target.length()\n\t\tif distance_to_target > q_ability_radius:\n\t\t\tcontinue\n\n\t\tvar direction_to_target: Vector2 = delta_to_target.normalized()\n\t\tif distance_to_target <= 6.0:\n\t\t\tdirection_to_target = _t004_q_last_direction\n\n\t\tif direction_to_target.dot(_t004_q_last_direction) < q_ability_forward_dot:\n\t\t\tcontinue\n\n\t\tif _t004_apply_damage_to_target(target, q_ability_damage, q_ability_knockback):\n\t\t\t_t004_q_hit_targets.append(target)\n\t\t\thit_count += 1\n\n\tif hit_count > 0:\n\t\t_t004_gain_judgment_from_q(hit_count)\n\n\nfunc _t004_append_group_nodes(targets: Array, group_name: String) -> void:\n\tif not get_tree().has_group(group_name):\n\t\treturn\n\tvar group_nodes: Array = get_tree().get_nodes_in_group(group_name)\n\tfor node_obj in group_nodes:\n\t\tvar node: Node = node_obj as Node\n\t\tif node == null:\n\t\t\tcontinue\n\t\tif not targets.has(node):\n\t\t\ttargets.append(node)\n\n\nfunc _t004_apply_damage_to_target(target: Node2D, amount: int, knockback_force: float) -> bool:\n\tif target.has_method("take_damage"):\n\t\t_t004_call_damage_method(target, "take_damage", amount, knockback_force)\n\t\treturn true\n\tif target.has_method("receive_damage"):\n\t\t_t004_call_damage_method(target, "receive_damage", amount, knockback_force)\n\t\treturn true\n\tif target.has_method("apply_damage"):\n\t\t_t004_call_damage_method(target, "apply_damage", amount, knockback_force)\n\t\treturn true\n\tif target.has_method("damage"):\n\t\t_t004_call_damage_method(target, "damage", amount, knockback_force)\n\t\treturn true\n\tif target.has_method("take_hit"):\n\t\t_t004_call_damage_method(target, "take_hit", amount, knockback_force)\n\t\treturn true\n\tif target.has_method("hit"):\n\t\t_t004_call_damage_method(target, "hit", amount, knockback_force)\n\t\treturn true\n\treturn false\n\n\nfunc _t004_call_damage_method(target: Node2D, method_name: String, amount: int, knockback_force: float) -> void:\n\tvar method_arg_count: int = _t004_get_method_arg_count(target, method_name)\n\tvar hit_direction: Vector2 = (target.global_position - global_position).normalized()\n\tif hit_direction.length_squared() <= 0.001:\n\t\thit_direction = _t004_q_last_direction\n\n\tif method_arg_count <= 1:\n\t\ttarget.call(method_name, amount)\n\telif method_arg_count == 2:\n\t\ttarget.call(method_name, amount, global_position)\n\telif method_arg_count == 3:\n\t\ttarget.call(method_name, amount, global_position, knockback_force)\n\telse:\n\t\ttarget.call(method_name, amount, global_position, knockback_force, hit_direction)\n\n\nfunc _t004_get_method_arg_count(target: Node, method_name: String) -> int:\n\tvar methods: Array = target.get_method_list()\n\tfor method_obj in methods:\n\t\tvar method_data: Dictionary = method_obj as Dictionary\n\t\tif String(method_data.get("name", "")) != method_name:\n\t\t\tcontinue\n\t\tvar args: Array = method_data.get("args", [])\n\t\treturn args.size()\n\treturn 1\n\n\nfunc _t004_gain_judgment_from_q(hit_count: int) -> void:\n\tvar gain_amount: float = q_ability_judgment_gain_on_hit * float(hit_count)\n\tif has_method("gain_judgment"):\n\t\tcall("gain_judgment", gain_amount)\n\telif has_method("_gain_judgment"):\n\t\tcall("_gain_judgment", gain_amount)\n\telif "judgment_meter" in self:\n\t\tjudgment_meter = clampf(judgment_meter + gain_amount, 0.0, 100.0)\n\n\nfunc _t004_get_q_cooldown_ratio() -> float:\n\tif q_ability_cooldown <= 0.001:\n\t\treturn 0.0\n\treturn clampf(q_ability_cooldown_remaining / q_ability_cooldown, 0.0, 1.0)\n\n\nfunc _t004_draw_q_ability_debug() -> void:\n\tif not show_debug_q_ability:\n\t\treturn\n\tvar alpha: float = clampf(_t004_q_flash_remaining / maxf(q_ability_flash_time, 0.001), 0.0, 1.0)\n\tvar center_color: Color = Color(0.88, 0.72, 0.36, 0.18 * alpha)\n\tvar edge_color: Color = Color(1.0, 0.82, 0.38, 0.78 * alpha)\n\tvar dir: Vector2 = _t004_q_last_direction.normalized()\n\tif dir.length_squared() <= 0.001:\n\t\tdir = Vector2.DOWN\n\n\tdraw_circle(Vector2.ZERO, q_ability_radius, center_color)\n\tdraw_arc(Vector2.ZERO, q_ability_radius, -0.25 * PI, 0.25 * PI, 24, edge_color, 3.0)\n\n\tvar left_dir: Vector2 = dir.rotated(-0.95)\n\tvar right_dir: Vector2 = dir.rotated(0.95)\n\tdraw_line(Vector2.ZERO, left_dir * q_ability_radius, edge_color, 2.0)\n\tdraw_line(Vector2.ZERO, right_dir * q_ability_radius, edge_color, 2.0)\n\tdraw_line(Vector2.ZERO, dir * q_ability_radius, Color(1.0, 0.94, 0.62, 0.95 * alpha), 3.0)\n\n\nfunc _t004_draw_q_cooldown_debug() -> void:\n\tif not show_debug_q_ability:\n\t\treturn\n\tif q_ability_cooldown_remaining <= 0.0:\n\t\treturn\n\tvar ratio: float = _t004_get_q_cooldown_ratio()\n\tvar radius: float = 18.0\n\tvar start_angle: float = -PI * 0.5\n\tvar end_angle: float = start_angle + TAU * ratio\n\tdraw_arc(Vector2(0.0, -44.0), radius, start_angle, end_angle, 20, Color(0.82, 0.68, 0.32, 0.75), 2.0)\n# T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_END\n'
DOC_TEXT = '# T-004 — Q Ability Placeholder\n\n## Goal\n\nAdd the first real in-game Q ability so combat stops being left-click-only.\n\nThis is a placeholder implementation, not final combat polish.\n\n## Ability\n\nCurrent placeholder:\n\n```text\nPenitent Riposte / Ashen Cleave hybrid placeholder\n```\n\nCurrent behavior:\n\n```text\nPress Q.\nThe player performs a short forward judgment cleave in the current facing direction.\nEnemies in range and in front of the player take damage.\nSuccessful hits grant Judgment.\nQ goes on cooldown.\nA simple debug VFX arc appears.\n```\n\nThis gives us a gameplay-visible ability immediately while leaving room to convert it into the full timed riposte later.\n\n## Controls\n\n```text\nQ = use Q ability\n```\n\nThe script also supports an InputMap action named:\n\n```text\nplayer_q\n```\n\nIf that action is not present, the raw Q key fallback still works.\n\n## Current Values\n\n```text\nCooldown: 4.25s\nDamage: 2\nRadius: 82 px\nJudgment gain: 12 per enemy hit\nRecovery: 0.34s\n```\n\n## What This Touches\n\n```text\nscripts/iso/IsoPhysicsTestPlayer.gd\ndata/production/demo_asset_tracker.json\n```\n\n## What This Does Not Touch\n\n```text\nfinal Q animation\nfinal Q VFX\nultimate\npatron system\nforge system\nweapon ascension\nenemy art\nboss art\nroom flow\nsave system\n```\n\n## Test Checklist\n\n```text\nStart a run.\nFace an enemy.\nPress Q.\nConfirm the player emits a visible gold/ash arc.\nConfirm enemy takes damage.\nConfirm Judgment increases on hit.\nConfirm Q cannot be spammed during cooldown.\nConfirm normal light/heavy attacks still work.\nConfirm dash still works.\nConfirm death/return flow is not broken.\n```\n\n## Acceptance\n\nAccepted if:\n\n```text\nQ exists in-game.\nQ damages enemies.\nQ has a cooldown.\nQ grants Judgment on hit.\nQ uses the current facing direction.\nThe game still runs without parser errors.\n```\n\n## Known Limitations\n\n```text\nThe full timed riposte is not implemented yet.\nThe VFX is debug draw, not final art.\nThe HUD cooldown indicator is currently player-local debug art, not final UI.\n```\n\n## Next Ticket\n\n```text\nT-005 — Implement Ultimate Placeholder\n```\n'

def update_tracker_status(data: Any, item_id: str, new_status: str) -> bool:
    changed = False
    if isinstance(data, dict):
        if data.get("id") == item_id:
            data["status"] = new_status
            return True
        for value in data.values():
            if update_tracker_status(value, item_id, new_status):
                changed = True
    elif isinstance(data, list):
        for value in data:
            if update_tracker_status(value, item_id, new_status):
                changed = True
    return changed

def patch_player_script() -> None:
    if not PLAYER_SCRIPT.exists():
        raise SystemExit(f"Missing {PLAYER_SCRIPT}")

    text = PLAYER_SCRIPT.read_text(encoding="utf-8")
    original = text

    if "T004_Q_ABILITY_PLACEHOLDER_START" not in text:
        t003_end = "T003_JUDGMENT_METER_END"
        if t003_end in text:
            insert_at = text.index(t003_end) + len(t003_end)
            text = text[:insert_at] + "\n" + Q_CONFIG_BLOCK + text[insert_at:]
        else:
            lines = text.splitlines()
            insert_line = 1
            for idx, line in enumerate(lines[:80]):
                if line.startswith("func "):
                    insert_line = idx
                    break
            lines.insert(insert_line, Q_CONFIG_BLOCK.strip("\n"))
            text = "\n".join(lines) + "\n"

    if "T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_START" not in text:
        text = text.rstrip() + "\n" + Q_FUNCTIONS_BLOCK + "\n"

    hook = "\t_t004_tick_q_ability(delta)\n\tif _t004_consume_q_input():\n\t\t_t004_try_start_q_ability()\n"
    if "_t004_consume_q_input()" not in original:
        signature = "func _physics_process(delta: float) -> void:"
        if signature not in text:
            signature = "func _physics_process(delta) -> void:"
        if signature not in text:
            raise SystemExit("Could not find _physics_process to install T004 Q input hook.")
        pos = text.index(signature) + len(signature)
        text = text[:pos] + "\n" + hook + text[pos:]

    draw_hook = "\tif _t004_q_flash_remaining > 0.0:\n\t\t_t004_draw_q_ability_debug()\n\t_t004_draw_q_cooldown_debug()\n"
    if "_t004_draw_q_ability_debug()" not in original:
        draw_sig = "func _draw() -> void:"
        if draw_sig in text:
            pos = text.index(draw_sig) + len(draw_sig)
            text = text[:pos] + "\n" + draw_hook + text[pos:]
        else:
            print("WARNING: _draw() not found; Q works but has no debug draw hook.")

    PLAYER_SCRIPT.write_text(text, encoding="utf-8")

def write_doc() -> None:
    DOC_PATH.parent.mkdir(parents=True, exist_ok=True)
    DOC_PATH.write_text(DOC_TEXT, encoding="utf-8")

def patch_tracker() -> None:
    if not TRACKER_JSON.exists():
        print("WARNING: tracker JSON not found; skipping S-003 tracker status update.")
        return
    try:
        data = json.loads(TRACKER_JSON.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"WARNING: could not parse tracker JSON: {exc}")
        return
    if update_tracker_status(data, "S-003", "Placeholder"):
        TRACKER_JSON.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    else:
        print("WARNING: S-003 not found in tracker JSON; no status changed.")

def main() -> None:
    patch_player_script()
    patch_tracker()
    write_doc()
    print("Applied T-004 Q Ability Placeholder.")

if __name__ == "__main__":
    main()
