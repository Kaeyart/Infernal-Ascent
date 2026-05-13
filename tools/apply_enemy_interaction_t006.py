#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
ENEMY = ROOT / "scripts/iso/IsoTestEnemy.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"
DOC_SRC = ROOT / "docs/ENEMY_INTERACTION_PASS_T006.md"

PLAYER_DISPATCHER = r'''
func _t004_call_damage_method(target: Node, arg1: Variant = null, arg2: Variant = null, arg3: Variant = null, arg4: Variant = null, arg5: Variant = null) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var raw_args: Array = [arg1, arg2, arg3, arg4, arg5]

	var damage_amount: int = 1
	var damage_found: bool = false
	var hit_position: Vector2 = global_position
	var hit_direction: Vector2 = facing.normalized()
	var knockback_force: float = 0.0
	var stagger_amount: float = 0.0
	var attack_kind: String = "player_ability"
	var vector_values: Array = []

	for raw_value: Variant in raw_args:
		if raw_value == null:
			continue

		var raw_type: int = typeof(raw_value)

		if raw_type == TYPE_STRING:
			attack_kind = str(raw_value)
		elif raw_type == TYPE_INT:
			if not damage_found:
				damage_amount = int(raw_value)
				damage_found = true
			else:
				stagger_amount = float(raw_value)
		elif raw_type == TYPE_FLOAT:
			if not damage_found:
				damage_amount = int(round(float(raw_value)))
				damage_found = true
			elif knockback_force == 0.0:
				knockback_force = float(raw_value)
			else:
				stagger_amount = float(raw_value)
		elif raw_type == TYPE_VECTOR2:
			vector_values.append(raw_value)

	if vector_values.size() == 1:
		var only_vector: Vector2 = vector_values[0] as Vector2
		if only_vector.length() <= 2.0:
			hit_direction = only_vector.normalized()
			hit_position = global_position
		else:
			hit_position = only_vector
	elif vector_values.size() >= 2:
		hit_position = vector_values[0] as Vector2
		hit_direction = (vector_values[1] as Vector2).normalized()

	if hit_direction.length_squared() <= 0.001:
		if target is Node2D:
			hit_direction = ((target as Node2D).global_position - hit_position).normalized()
		if hit_direction.length_squared() <= 0.001:
			hit_direction = facing.normalized()
		if hit_direction.length_squared() <= 0.001:
			hit_direction = Vector2.RIGHT

	# T-006: allow normal enemies to react before damage is applied.
	if target.has_method("receive_player_ability_interaction"):
		target.call("receive_player_ability_interaction", attack_kind, damage_amount, hit_position, hit_direction, knockback_force, stagger_amount)

	# T-006: let enemies expose temporary vulnerability without changing every take_damage signature.
	if target.has_method("get_player_ability_damage_multiplier"):
		var multiplier: float = float(target.call("get_player_ability_damage_multiplier", attack_kind))
		damage_amount = max(1, int(ceil(float(damage_amount) * multiplier)))

	var method_args: Array = []
	for raw_method_info: Dictionary in target.get_method_list():
		var method_info: Dictionary = raw_method_info
		if str(method_info.get("name", "")) == "take_damage":
			method_args = method_info.get("args", [])
			break

	var script_path: String = ""
	var script_resource: Script = target.get_script() as Script
	if script_resource != null:
		script_path = script_resource.resource_path

	# Known boss signature:
	# take_damage(amount: int, source_global_position: Vector2, hit_direction: Vector2, attack_kind: String)
	if script_path.ends_with("AshWardenBoss.gd"):
		target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)
		return

	# Known normal enemy signature:
	# take_damage(amount: int)
	if method_args.size() <= 1:
		target.call("take_damage", damage_amount)
		return

	var call_args: Array = []
	for i: int in range(method_args.size()):
		var arg_info: Dictionary = method_args[i] as Dictionary
		var arg_name: String = str(arg_info.get("name", "")).to_lower()
		var arg_type: int = int(arg_info.get("type", TYPE_NIL))

		if i == 0:
			call_args.append(damage_amount)
			continue

		match arg_type:
			TYPE_VECTOR2:
				if arg_name.find("dir") >= 0 or arg_name.find("normal") >= 0:
					call_args.append(hit_direction)
				elif arg_name.find("source") >= 0 or arg_name.find("pos") >= 0 or arg_name.find("origin") >= 0 or arg_name.find("global") >= 0:
					call_args.append(hit_position)
				else:
					call_args.append(hit_position)
			TYPE_STRING:
				call_args.append(attack_kind)
			TYPE_INT:
				if arg_name.find("stagger") >= 0:
					call_args.append(int(round(stagger_amount)))
				else:
					call_args.append(int(round(knockback_force)))
			TYPE_FLOAT:
				if arg_name.find("stagger") >= 0:
					call_args.append(stagger_amount)
				else:
					call_args.append(knockback_force)
			TYPE_BOOL:
				call_args.append(false)
			TYPE_OBJECT:
				call_args.append(self)
			_:
				if arg_name.find("kind") >= 0 or arg_name.find("type") >= 0:
					call_args.append(attack_kind)
				elif arg_name.find("dir") >= 0:
					call_args.append(hit_direction)
				elif arg_name.find("pos") >= 0 or arg_name.find("source") >= 0:
					call_args.append(hit_position)
				else:
					call_args.append(damage_amount)

	Callable(target, "take_damage").callv(call_args)
'''

ENEMY_MEMBERS = r'''
# T-006 enemy interaction state. Placeholder logic until final enemy art/animations exist.
var t006_stagger_value: float = 0.0
var t006_stagger_threshold: float = 100.0
var t006_stagger_recover_rate: float = 24.0
var t006_stagger_timer: float = 0.0
var t006_hit_react_timer: float = 0.0
var t006_vulnerability_timer: float = 0.0
var t006_last_player_attack_kind: String = ""
var t006_base_modulate: Color = Color.WHITE
var t006_base_modulate_captured: bool = false
'''

ENEMY_FUNCTIONS = r'''

# T-006 — Called by IsoPhysicsTestPlayer before take_damage().
func receive_player_ability_interaction(attack_kind: String = "attack", damage_amount: int = 1, source_position: Vector2 = Vector2.ZERO, hit_direction: Vector2 = Vector2.RIGHT, knockback_force: float = 0.0, stagger_amount: float = 0.0) -> void:
	if not t006_base_modulate_captured:
		t006_base_modulate = modulate
		t006_base_modulate_captured = true

	t006_last_player_attack_kind = attack_kind
	var role_id: String = _t006_get_enemy_role_id()
	var stagger_gain: float = _t006_get_base_stagger_for_attack(attack_kind, stagger_amount)

	if role_id.find("cinder") >= 0 or role_id.find("lunger") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0 or attack_kind.find("ultimate") >= 0:
			stagger_gain *= 1.45
	elif role_id.find("ember") >= 0 or role_id.find("spitter") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("ultimate") >= 0:
			stagger_gain *= 1.25
	elif role_id.find("ash") >= 0 or role_id.find("grunt") >= 0:
		if attack_kind.find("heavy") >= 0:
			stagger_gain *= 1.20

	_t006_add_stagger(stagger_gain)
	t006_hit_react_timer = max(t006_hit_react_timer, 0.10)

	if attack_kind.find("ultimate") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 1.25)
	elif attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 0.65)
	elif attack_kind.find("heavy") >= 0:
		t006_vulnerability_timer = max(t006_vulnerability_timer, 0.35)

	_t006_apply_placeholder_knockback(hit_direction, knockback_force, attack_kind)
	_t006_apply_placeholder_modulate()

func get_player_ability_damage_multiplier(attack_kind: String = "attack") -> float:
	var role_id: String = _t006_get_enemy_role_id()
	var multiplier: float = 1.0
	if t006_stagger_timer > 0.0:
		multiplier += 0.20
	if t006_vulnerability_timer > 0.0:
		multiplier += 0.10
	if role_id.find("cinder") >= 0 or role_id.find("lunger") >= 0:
		if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
			multiplier += 0.15
	if role_id.find("ember") >= 0 or role_id.find("spitter") >= 0:
		if attack_kind.find("ultimate") >= 0:
			multiplier += 0.15
	return multiplier

func is_t006_staggered() -> bool:
	return t006_stagger_timer > 0.0

func _t006_add_stagger(amount: float) -> void:
	t006_stagger_value = clamp(t006_stagger_value + amount, 0.0, t006_stagger_threshold)
	if t006_stagger_value >= t006_stagger_threshold:
		t006_stagger_timer = max(t006_stagger_timer, 0.80)
		t006_stagger_value = max(0.0, t006_stagger_threshold * 0.35)

func _t006_get_base_stagger_for_attack(attack_kind: String, explicit_stagger: float) -> float:
	if explicit_stagger > 0.0:
		return explicit_stagger
	if attack_kind.find("ultimate") >= 0:
		return 70.0
	if attack_kind.find("q") >= 0 or attack_kind.find("riposte") >= 0:
		return 42.0
	if attack_kind.find("heavy") >= 0:
		return 36.0
	return 16.0

func _t006_apply_placeholder_knockback(hit_direction: Vector2, knockback_force: float, attack_kind: String) -> void:
	var dir: Vector2 = hit_direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var force: float = knockback_force
	if force <= 0.0:
		if attack_kind.find("ultimate") >= 0:
			force = 180.0
		elif attack_kind.find("q") >= 0 or attack_kind.find("heavy") >= 0:
			force = 95.0
		else:
			force = 38.0

	if _t006_has_property("velocity"):
		var current_velocity: Variant = get("velocity")
		if typeof(current_velocity) == TYPE_VECTOR2:
			set("velocity", (current_velocity as Vector2) + dir * force)
	else:
		global_position += dir * min(force * 0.035, 10.0)

func _t006_update_enemy_interaction(delta: float) -> void:
	if not t006_base_modulate_captured:
		t006_base_modulate = modulate
		t006_base_modulate_captured = true

	if t006_stagger_timer > 0.0:
		t006_stagger_timer = max(0.0, t006_stagger_timer - delta)
	if t006_hit_react_timer > 0.0:
		t006_hit_react_timer = max(0.0, t006_hit_react_timer - delta)
	if t006_vulnerability_timer > 0.0:
		t006_vulnerability_timer = max(0.0, t006_vulnerability_timer - delta)

	if t006_stagger_timer <= 0.0 and t006_stagger_value > 0.0:
		t006_stagger_value = max(0.0, t006_stagger_value - t006_stagger_recover_rate * delta)

	_t006_apply_placeholder_modulate()

func _t006_apply_placeholder_modulate() -> void:
	if t006_stagger_timer > 0.0:
		modulate = Color(1.0, 0.86, 0.48, 1.0)
	elif t006_hit_react_timer > 0.0:
		modulate = Color(1.0, 0.72, 0.58, 1.0)
	elif t006_vulnerability_timer > 0.0:
		modulate = Color(0.95, 0.88, 1.0, 1.0)
	elif t006_base_modulate_captured:
		modulate = t006_base_modulate

func _t006_get_enemy_role_id() -> String:
	var chunks: Array[String] = [name.to_lower()]
	var possible_props: Array[String] = ["enemy_id", "enemy_type", "enemy_kind", "archetype", "display_name"]
	for prop_name: String in possible_props:
		if _t006_has_property(prop_name):
			chunks.append(str(get(prop_name)).to_lower())
	return " ".join(chunks)

func _t006_has_property(prop_name: String) -> bool:
	for prop_info: Dictionary in get_property_list():
		if str(prop_info.get("name", "")) == prop_name:
			return true
	return false
'''


def ensure_file(path: Path, label: str) -> None:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing {label}: {path}")


def replace_player_dispatcher() -> None:
    text = PLAYER.read_text()
    pattern = re.compile(r'\nfunc _t004_call_damage_method\([^\n]*\) -> void:\n(?:(?!\nfunc ).*\n)*', re.MULTILINE)
    m = pattern.search(text)
    if not m:
        raise SystemExit("ERROR: Could not find _t004_call_damage_method() in IsoPhysicsTestPlayer.gd")
    text = text[:m.start()] + "\n" + PLAYER_DISPATCHER + text[m.end():]
    PLAYER.write_text(text)
    print("Patched player damage dispatcher for T-006.")


def insert_enemy_members() -> None:
    text = ENEMY.read_text()
    if "var t006_stagger_value" in text:
        return
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
        raise SystemExit("ERROR: Could not find extends/class_name in IsoTestEnemy.gd")
    member_lines = ENEMY_MEMBERS.strip("\n").splitlines()
    lines[insert_at:insert_at] = [""] + member_lines + [""]
    ENEMY.write_text("\n".join(lines) + "\n")
    print("Inserted T-006 enemy member variables.")


def append_enemy_functions() -> None:
    text = ENEMY.read_text()
    if "func receive_player_ability_interaction" in text:
        return
    ENEMY.write_text(text.rstrip() + "\n" + ENEMY_FUNCTIONS + "\n")
    print("Appended T-006 enemy interaction functions.")


def patch_enemy_process_update() -> None:
    text = ENEMY.read_text()
    if "_t006_update_enemy_interaction(" in text and "func _t006_update_enemy_interaction" in text:
        # If call already exists outside the function definition, do not insert again.
        call_count = text.count("_t006_update_enemy_interaction(") - text.count("func _t006_update_enemy_interaction(")
        if call_count > 0:
            return

    # Prefer _physics_process(delta/_delta), then _process(delta/_delta). If neither exists, add _process.
    process_re = re.compile(r'(func\s+_(?:physics_process|process)\s*\(([^)]*)\)\s*->\s*void:\n)', re.MULTILINE)
    m = process_re.search(text)
    if m:
        args = m.group(2).strip()
        delta_name = "delta"
        if args:
            first_arg = args.split(",")[0].strip()
            if first_arg:
                delta_name = first_arg
        insert = m.group(1) + f"\t_t006_update_enemy_interaction({delta_name})\n"
        text = text[:m.start()] + insert + text[m.end():]
    else:
        text = text.rstrip() + "\n\nfunc _process(delta: float) -> void:\n\t_t006_update_enemy_interaction(delta)\n"

    ENEMY.write_text(text)
    print("Patched enemy update loop for T-006 timers.")


def update_tracker() -> None:
    if not TRACKER.exists():
        print("Tracker JSON not found; skipping tracker update.")
        return
    try:
        data = json.loads(TRACKER.read_text())
    except Exception as exc:
        print(f"Could not parse tracker JSON; skipping tracker update: {exc}")
        return

    def update_items(items):
        if isinstance(items, list):
            for item in items:
                if isinstance(item, dict) and item.get("id") == "S-005":
                    item["status"] = "In Progress"
                    item["notes"] = "T-006 adds placeholder stagger, vulnerability, hit reaction, and role-aware player ability interactions."

    if isinstance(data, dict):
        for key in ["systems", "system_tracker", "items"]:
            update_items(data.get(key))
        # Also recurse one level for common section-based trackers.
        for value in data.values():
            if isinstance(value, list):
                update_items(value)
            elif isinstance(value, dict):
                for subvalue in value.values():
                    update_items(subvalue)

    TRACKER.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print("Updated tracker S-005 to In Progress where found.")


def main() -> None:
    ensure_file(PLAYER, "player script")
    ensure_file(ENEMY, "enemy script")
    replace_player_dispatcher()
    insert_enemy_members()
    append_enemy_functions()
    patch_enemy_process_update()
    update_tracker()
    print("T-006 apply complete.")

if __name__ == "__main__":
    main()
