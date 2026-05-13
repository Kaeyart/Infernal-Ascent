#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import json

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
ENEMY = ROOT / "scripts/iso/IsoTestEnemy.gd"
CONTROLLER = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"
DOC = ROOT / "docs/MAMMON_BOON_MECHANICS_T010.md"


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing required file: {path}")
    return path.read_text()


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def insert_before(text: str, marker: str, block: str) -> str:
    if block.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"ERROR: Could not find insertion marker: {marker[:80]!r}")
    return text.replace(marker, block + marker, 1)


def insert_after(text: str, marker: str, block: str) -> str:
    if block.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"ERROR: Could not find insertion marker: {marker[:80]!r}")
    return text.replace(marker, marker + block, 1)


def patch_controller() -> None:
    text = read(CONTROLLER)

    # Ensure claimed boon payloads are forwarded to the player. T-009 may already have a helper;
    # this version is deliberately generic and idempotent.
    helper = r'''
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
'''
    if "func _t010_grant_boon_to_player" not in text:
        text = insert_before(text, "\nfunc _build_gate_choices() -> Array[Dictionary]:", "\n" + helper + "\n")

    # Add call inside _claim_boon_payload. Use multiple likely anchors.
    if "_t010_grant_boon_to_player(payload)" not in text:
        anchors = [
            'reward_display_history.append("%s: %s" % [patron_name, display_name])\n',
            'reward_display_history.append("%s: %s" % [patron_name, display_name])\r\n',
        ]
        patched = False
        for anchor in anchors:
            if anchor in text:
                text = text.replace(anchor, anchor + "\t_t010_grant_boon_to_player(payload)\n", 1)
                patched = True
                break
        if not patched:
            # Fallback: locate function and insert after var display_name line.
            m = re.search(r"func _claim_boon_payload\(payload: Dictionary\) -> void:\n(?:(?!\nfunc ).*\n)*", text)
            if not m:
                raise SystemExit("ERROR: Could not find _claim_boon_payload() to wire Mammon boon ownership.")
            body = m.group(0)
            lines = body.splitlines()
            for i, line in enumerate(lines):
                if "display_name" in line and "payload.get" in line:
                    lines.insert(i + 1, "\t_t010_grant_boon_to_player(payload)")
                    break
            else:
                lines.insert(1, "\t_t010_grant_boon_to_player(payload)")
            text = text[:m.start()] + "\n".join(lines) + "\n" + text[m.end():]

    write(CONTROLLER, text)


def patch_enemy() -> None:
    text = read(ENEMY)

    var_block = r'''
# T-010 Mammon / burn interaction state. Placeholder fire logic until final VFX/art exists.
var t010_burn_timer: float = 0.0
var t010_burn_tick_timer: float = 0.0
var t010_burn_tick_interval: float = 0.75
var t010_burn_damage: int = 1
var t010_slow_timer: float = 0.0
var t010_slow_factor: float = 1.0
var t010_root_timer: float = 0.0
var t010_enemy_base_modulate: Color = Color.WHITE
var t010_enemy_base_modulate_captured: bool = false
'''
    if "var t010_burn_timer" not in text:
        # Place after T-006 state if present, otherwise after class_name.
        if "var t006_base_modulate_captured" in text:
            text = re.sub(r"(var t006_base_modulate_captured: bool = false\n)", r"\1" + var_block, text, count=1)
        else:
            text = insert_after(text, "class_name IsoTestEnemy\n", "\n" + var_block)

    # Hook update into _process.
    if "_t010_update_mammon_enemy_effects(delta)" not in text:
        if "_t006_update_enemy_interaction(delta)" in text:
            text = text.replace("_t006_update_enemy_interaction(delta)\n", "_t006_update_enemy_interaction(delta)\n\t_t010_update_mammon_enemy_effects(delta)\n", 1)
        elif "func _process(delta: float) -> void:\n" in text:
            text = text.replace("func _process(delta: float) -> void:\n", "func _process(delta: float) -> void:\n\t_t010_update_mammon_enemy_effects(delta)\n", 1)
        else:
            raise SystemExit("ERROR: Could not hook enemy _process() for Mammon burn state.")

    methods = r'''
func t010_apply_burn(duration: float = 2.5, damage_per_tick: int = 1, _source: Node = null) -> void:
	if is_dead:
		return
	t010_burn_timer = maxf(t010_burn_timer, duration)
	t010_burn_tick_timer = minf(t010_burn_tick_timer, 0.12)
	t010_burn_damage = maxi(1, damage_per_tick)
	queue_redraw()

func t010_is_burning() -> bool:
	return t010_burn_timer > 0.0

func t010_apply_slow(duration: float = 1.25, factor: float = 0.55) -> void:
	if is_dead:
		return
	t010_slow_timer = maxf(t010_slow_timer, duration)
	t010_slow_factor = clampf(factor, 0.15, 1.0)
	queue_redraw()

func t010_apply_root(duration: float = 1.0) -> void:
	if is_dead:
		return
	t010_root_timer = maxf(t010_root_timer, duration)
	queue_redraw()

func t010_apply_pull(source_position: Vector2, strength: float = 34.0) -> void:
	if is_dead:
		return
	var dir: Vector2 = (source_position - global_position).normalized()
	if dir.length_squared() > 0.001:
		global_position += dir * strength
		queue_redraw()

func _t010_update_mammon_enemy_effects(delta: float) -> void:
	if not t010_enemy_base_modulate_captured:
		t010_enemy_base_modulate = modulate
		t010_enemy_base_modulate_captured = true

	if t010_burn_timer > 0.0:
		t010_burn_timer = maxf(0.0, t010_burn_timer - delta)
		t010_burn_tick_timer -= delta
		if t010_burn_tick_timer <= 0.0 and not is_dead:
			t010_burn_tick_timer = t010_burn_tick_interval
			if has_method("take_damage"):
				call("take_damage", t010_burn_damage)
		modulate = Color(1.0, 0.55, 0.25, 1.0)
	elif t010_root_timer > 0.0:
		t010_root_timer = maxf(0.0, t010_root_timer - delta)
		modulate = Color(0.75, 0.55, 0.32, 1.0)
	elif t010_slow_timer > 0.0:
		t010_slow_timer = maxf(0.0, t010_slow_timer - delta)
		modulate = Color(0.92, 0.72, 0.42, 1.0)
	else:
		modulate = t010_enemy_base_modulate
'''
    if "func t010_apply_burn" not in text:
        text = text.rstrip() + "\n\n" + methods + "\n"

    # Patch movement speed with slow/root factor in a conservative way.
    # We don't know the exact movement code, so patch common occurrences.
    if "# T-010 movement modifier" not in text:
        text = text.replace(
            "move_speed * delta",
            "(0.0 if t010_root_timer > 0.0 else move_speed * (t010_slow_factor if t010_slow_timer > 0.0 else 1.0)) * delta # T-010 movement modifier"
        )

    write(ENEMY, text)


def patch_player() -> None:
    text = read(PLAYER)

    var_block = r'''
# T-010 Mammon boon runtime state. First-pass fire/greed mechanics.
var t010_mammon_boons: Dictionary = {}
var t010_dash_fire_timer: float = 0.0
var t010_dash_fire_tick: float = 0.0
var t010_first_attack_after_dash_empowered: bool = false
var t010_light_hit_count: int = 0
var t010_furnace_bloom_cooldown: float = 0.0
'''
    if "var t010_mammon_boons" not in text:
        # Put after class_name or after T009 vars if present.
        if "var t009_azazel_boons" in text:
            m = re.search(r"var t009_azazel_boons.*\n", text)
            if m:
                text = text[:m.end()] + var_block + text[m.end():]
            else:
                text = insert_after(text, "class_name IsoPhysicsTestPlayer\n", "\n" + var_block)
        else:
            text = insert_after(text, "class_name IsoPhysicsTestPlayer\n", "\n" + var_block)

    # Hook passive update into _physics_process. Support both delta and _delta naming.
    if "_t010_update_mammon_player_effects(" not in text:
        if "func _physics_process(delta: float) -> void:\n" in text:
            text = text.replace("func _physics_process(delta: float) -> void:\n", "func _physics_process(delta: float) -> void:\n\t_t010_update_mammon_player_effects(delta)\n", 1)
        elif "func _physics_process(_delta: float) -> void:\n" in text:
            text = text.replace("func _physics_process(_delta: float) -> void:\n", "func _physics_process(_delta: float) -> void:\n\t_t010_update_mammon_player_effects(_delta)\n", 1)
        else:
            raise SystemExit("ERROR: Could not find _physics_process() in player for Mammon update hook.")

    # Ensure receive_boon_payload exists or patch existing one.
    if "func receive_boon_payload(payload: Dictionary)" in text:
        if "_t010_record_mammon_boon(payload)" not in text:
            text = re.sub(
                r"(func receive_boon_payload\(payload: Dictionary\) -> void:\n)",
                r"\1\t_t010_record_mammon_boon(payload)\n",
                text,
                count=1,
            )
    else:
        receive_method = r'''
func receive_boon_payload(payload: Dictionary) -> void:
	_t010_record_mammon_boon(payload)
	if has_method("t009_record_azazel_boon"):
		call("t009_record_azazel_boon", payload)
'''
        text = text.rstrip() + "\n\n" + receive_method + "\n"

    methods = r'''
func _t010_record_mammon_boon(payload: Dictionary) -> void:
	var patron_id: String = str(payload.get("patron_id", ""))
	var boon_id: String = str(payload.get("boon_id", payload.get("id", ""))).to_lower()
	if patron_id != "patron_mammon_furnace" and boon_id.find("mammon") < 0 and boon_id.find("furnace") < 0 and boon_id.find("cinder") < 0:
		return

	t010_mammon_boons[boon_id] = true
	print("[T010] Mammon boon received: %s" % boon_id)

func _t010_has_mammon_boon(fragment: String) -> bool:
	var needle: String = fragment.to_lower()
	for key: Variant in t010_mammon_boons.keys():
		var id: String = str(key).to_lower()
		if id.find(needle) >= 0:
			return true
	return false

func _t010_has_any_mammon_boon() -> bool:
	return not t010_mammon_boons.is_empty()

func _t010_update_mammon_player_effects(delta: float) -> void:
	if t010_furnace_bloom_cooldown > 0.0:
		t010_furnace_bloom_cooldown = maxf(0.0, t010_furnace_bloom_cooldown - delta)

	if not _t010_has_any_mammon_boon():
		return

	if t010_dash_fire_timer > 0.0:
		t010_dash_fire_timer = maxf(0.0, t010_dash_fire_timer - delta)
		t010_dash_fire_tick -= delta
		if t010_dash_fire_tick <= 0.0:
			t010_dash_fire_tick = 0.18
			_t010_apply_burn_to_nearby_enemies(global_position, 52.0, 1.7, 1)

	var dash_pressed: bool = false
	if InputMap.has_action("dash") and Input.is_action_just_pressed("dash"):
		dash_pressed = true
	if Input.is_physical_key_pressed(KEY_SHIFT):
		dash_pressed = true

	if dash_pressed and (_t010_has_mammon_boon("ash") or _t010_has_mammon_boon("dash") or _t010_has_mammon_boon("step")):
		t010_dash_fire_timer = 0.42
		t010_dash_fire_tick = 0.01
		t010_first_attack_after_dash_empowered = true

func _t010_apply_mammon_hit_effects(target: Node, attack_kind: String = "attack", damage_amount: int = 1, hit_position: Vector2 = Vector2.ZERO) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not _t010_has_any_mammon_boon():
		return

	var kind: String = attack_kind.to_lower()
	var is_light: bool = kind.find("light") >= 0 or kind == "attack" or kind == "player_ability"
	var is_heavy: bool = kind.find("heavy") >= 0
	var is_q: bool = kind.find("q") >= 0 or kind.find("cleave") >= 0 or kind.find("riposte") >= 0
	var is_ultimate: bool = kind.find("ultimate") >= 0 or kind.find("judgment") >= 0

	# Cinder Edge / generic burn lane: light-style hits ignite enemies.
	if is_light and (_t010_has_mammon_boon("cinder") or _t010_has_mammon_boon("burn")):
		_t010_apply_burn_to_target(target, 2.4, 1)

	# Kindled Wounds: Q against burning enemies deals bonus damage.
	if is_q and (_t010_has_mammon_boon("kindled") or _t010_has_mammon_boon("wound")):
		if target.has_method("t010_is_burning") and bool(target.call("t010_is_burning")):
			_t010_direct_extra_damage(target, 1, "mammon_kindled")

	# Scorched Heavy: heavy attacks emit a small ember burst.
	if is_heavy and (_t010_has_mammon_boon("heavy") or _t010_has_mammon_boon("ember") or _t010_has_mammon_boon("scorch")):
		var origin: Vector2 = hit_position
		if origin == Vector2.ZERO and target is Node2D:
			origin = (target as Node2D).global_position
		_t010_apply_burn_to_nearby_enemies(origin, 86.0, 2.0, 1)

	# Ash Step / Dash Ignite: first hit after dash gets a small fire bonus.
	if t010_first_attack_after_dash_empowered and (_t010_has_mammon_boon("ash") or _t010_has_mammon_boon("dash") or _t010_has_mammon_boon("step")):
		t010_first_attack_after_dash_empowered = false
		_t010_direct_extra_damage(target, 1, "mammon_ash_step")
		_t010_apply_burn_to_target(target, 1.6, 1)

	# Coal Heart / low HP fire: simple low-health damage bonus.
	if (_t010_has_mammon_boon("low") or _t010_has_mammon_boon("coal") or _t010_has_mammon_boon("heart")) and _t010_is_player_low_health():
		_t010_direct_extra_damage(target, 1, "mammon_coal_heart")

	# Furnace Bloom: burning enemy death creates a small burst.
	if (_t010_has_mammon_boon("explosion") or _t010_has_mammon_boon("bloom")) and t010_furnace_bloom_cooldown <= 0.0:
		var dead_now: bool = false
		if "is_dead" in target:
			dead_now = bool(target.get("is_dead"))
		if dead_now and target is Node2D:
			t010_furnace_bloom_cooldown = 0.35
			_t010_apply_burn_to_nearby_enemies((target as Node2D).global_position, 104.0, 2.2, 1)

	# Ultimate fire fantasy: if the player has any final flame style boon, ultimate burns survivors.
	if is_ultimate and (_t010_has_mammon_boon("final") or _t010_has_mammon_boon("flame")):
		_t010_apply_burn_to_target(target, 3.0, 1)

func _t010_apply_burn_to_target(target: Node, duration: float, damage_per_tick: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("t010_apply_burn"):
		target.call("t010_apply_burn", duration, damage_per_tick, self)

func _t010_apply_burn_to_nearby_enemies(origin: Vector2, radius: float, duration: float, damage_per_tick: int) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for enemy_node: Node in enemies:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		var enemy_pos: Vector2 = (enemy_node as Node2D).global_position
		if enemy_pos.distance_to(origin) <= radius:
			_t010_apply_burn_to_target(enemy_node, duration, damage_per_tick)

func _t010_direct_extra_damage(target: Node, amount: int, attack_kind: String) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		# Use the existing safe dispatcher if present.
		if has_method("_t004_call_damage_method"):
			call("_t004_call_damage_method", target, amount, global_position, 0.0, attack_kind)
		else:
			target.call("take_damage", amount)

func _t010_is_player_low_health() -> bool:
	var current_hp: float = 9999.0
	var max_hp_value: float = 9999.0

	if "health" in self:
		current_hp = float(get("health"))
	elif "current_health" in self:
		current_hp = float(get("current_health"))
	elif "hp" in self:
		current_hp = float(get("hp"))

	if "max_health" in self:
		max_hp_value = float(get("max_health"))
	elif "maximum_health" in self:
		max_hp_value = float(get("maximum_health"))
	elif "max_hp" in self:
		max_hp_value = float(get("max_hp"))

	if max_hp_value <= 0.0 or max_hp_value >= 9999.0:
		return false
	return current_hp / max_hp_value <= 0.40
'''
    if "func _t010_record_mammon_boon" not in text:
        text = text.rstrip() + "\n\n" + methods + "\n"

    # Hook regular light _perform_attack direct damage if present.
    if "_t010_apply_mammon_hit_effects(enemy_node, \"light\"" not in text:
        text = text.replace(
            "enemy_node.call(\"take_damage\", attack_damage)\n",
            "enemy_node.call(\"take_damage\", attack_damage)\n\t\t\t_t010_apply_mammon_hit_effects(enemy_node, \"light\", attack_damage, enemy_position)\n",
            1,
        )

    # Hook safe damage dispatcher branches if present.
    if "mammon_dispatch_hook" not in text:
        text = text.replace(
            'target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\treturn',
            'target.call("take_damage", damage_amount, hit_position, hit_direction, attack_kind)\n\t\t_t010_apply_mammon_hit_effects(target, attack_kind, damage_amount, hit_position) # mammon_dispatch_hook\n\t\treturn'
        )
        text = text.replace(
            'target.call("take_damage", damage_amount)\n\t\treturn',
            'target.call("take_damage", damage_amount)\n\t\t_t010_apply_mammon_hit_effects(target, attack_kind, damage_amount, hit_position) # mammon_dispatch_hook\n\t\treturn'
        )
        text = text.replace(
            'Callable(target, "take_damage").callv(call_args)\n',
            'Callable(target, "take_damage").callv(call_args)\n\t_t010_apply_mammon_hit_effects(target, attack_kind, damage_amount, hit_position) # mammon_dispatch_hook\n'
        )

    write(PLAYER, text)


def update_tracker() -> None:
    if not TRACKER.exists():
        return
    try:
        data = json.loads(TRACKER.read_text())
    except Exception:
        return

    # Mark Mammon system item if present; otherwise append a simple item.
    updated = False
    for section_key in ("systems", "system_tracker", "items"):
        section = data.get(section_key)
        if isinstance(section, list):
            for item in section:
                if not isinstance(item, dict):
                    continue
                name = str(item.get("System", item.get("system", item.get("name", "")))).lower()
                sid = str(item.get("ID", item.get("id", ""))).lower()
                if "mammon" in name or "furnace mother" in name or sid == "s-009":
                    item["Status"] = item.get("Status", "In Progress") if "Status" in item else "In Progress"
                    item["status"] = "In Progress"
                    updated = True
    if not updated:
        data.setdefault("t010_notes", {})["mammon_boon_mechanics"] = "In Progress"
    TRACKER.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def write_doc() -> None:
    DOC.parent.mkdir(parents=True, exist_ok=True)
    DOC.write_text("""# T-010 — Mammon Boon Mechanics V1\n\nGoal: make Mammon, the Gilded Furnace, affect combat in-game instead of existing only as boon data.\n\nThis is a placeholder mechanics pass. Final fire art, icons, SFX, UI frames, and balance are deferred.\n\n## Implemented mechanics\n\n- Mammon boon ownership is recorded on the player when a Mammon boon is claimed.\n- Cinder/burn-style boons ignite enemies on light-style hits.\n- Ash Step / dash-style boons create a brief burning dash trail and empower the first attack after dash.\n- Scorched Heavy / ember-style boons create a small burn burst around heavy-style hits.\n- Kindled Wounds deals bonus damage when Q hits a burning enemy.\n- Coal Heart / low-HP fire gives a small damage bonus when the player is under 40% HP.\n- Furnace Bloom / explosion boons create a small burn burst when a burning enemy dies.\n- Final Flame-style boons make ultimate hits burn survivors.\n\n## Deferred\n\n- Real flame VFX.\n- Real boon icons.\n- Proper UI explanation beyond the current quick boon description.\n- Final audio.\n- Balance.\n- Shop/gold-specific Mammon economy effects.\n\n## Test checklist\n\n1. Start a run.\n2. Claim a Mammon boon.\n3. Confirm console prints `[T010] Mammon boon received`.\n4. Use light attacks on enemies. If the boon is burn/cinder related, enemies should take burn ticks.\n5. If the boon is Ash Step/dash related, dash through/near enemies and attack after dash.\n6. If the boon is heavy/ember related, use heavy-style attacks and confirm nearby enemies burn.\n7. If the boon is Kindled Wounds, use Q on burning enemies and confirm bonus damage.\n8. Confirm Azazel/Mammon/Minos route reward flow still works.\n9. Confirm no parser/runtime errors.\n\n## Commit\n\n```bash\ngit add scripts/iso/IsoPhysicsTestPlayer.gd \\\n scripts/iso/IsoTestEnemy.gd \\\n scripts/iso/IsoRoomLocalLoopController.gd \\\n data/production/demo_asset_tracker.json \\\n docs/MAMMON_BOON_MECHANICS_T010.md \\\n tools/apply_mammon_boon_mechanics_t010.py \\\n tools/validate_mammon_boon_mechanics_t010.py\n\ngit commit -m \"Add Mammon boon mechanics\"\n```\n""")


def main() -> None:
    patch_controller()
    patch_enemy()
    patch_player()
    update_tracker()
    write_doc()
    print("Applied T-010 Mammon Boon Mechanics V1.")


if __name__ == "__main__":
    main()
