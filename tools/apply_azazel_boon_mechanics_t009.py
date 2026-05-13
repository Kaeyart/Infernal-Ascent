#!/usr/bin/env python3
from pathlib import Path
import re, json

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
ENEMY = ROOT / "scripts/iso/IsoTestEnemy.gd"
CONTROLLER = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"

def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing {path}")
    return path.read_text()

def write(path: Path, text: str) -> None:
    path.write_text(text)

def append_once(text: str, block: str) -> str:
    if block.strip() in text:
        return text
    return text.rstrip() + "\n\n" + block.strip() + "\n"

def patch_player() -> None:
    text = read(PLAYER)

    if "var t009_owned_boons: Dictionary = {}" not in text:
        m = re.search(r'(^class_name IsoPhysicsTestPlayer\s*\n)', text, re.MULTILINE)
        if not m:
            raise SystemExit("ERROR: class_name IsoPhysicsTestPlayer not found")
        state = '''
# T-009 Azazel boon mechanics. Placeholder mechanics until final boon UI/VFX exists.
var t009_owned_boons: Dictionary = {}
var t009_light_hit_count: int = 0
var t009_bound_step_cooldown: float = 0.0
'''
        text = text[:m.end()] + state + text[m.end():]

    if "_t009_update_azazel_dash_effects(delta)" not in text:
        text = re.sub(
            r'(func _physics_process\(delta: float\) -> void:\n)',
            r'\1\t_t009_update_azazel_dash_effects(delta)\n',
            text,
            count=1
        )

    # Light/heavy direct calls.
    text = text.replace('enemy_node.call("take_damage", attack_damage)', '_t009_apply_light_attack_damage(enemy_node, attack_damage)')
    text = text.replace('enemy.take_damage(attack_damage)', '_t009_apply_light_attack_damage(enemy, attack_damage)')
    text = text.replace('enemy_node.call("take_damage", heavy_attack_damage)', '_t009_apply_heavy_attack_damage(enemy_node, heavy_attack_damage)')
    text = text.replace('enemy.call("take_damage", heavy_attack_damage)', '_t009_apply_heavy_attack_damage(enemy, heavy_attack_damage)')
    text = text.replace('enemy.take_damage(heavy_attack_damage)', '_t009_apply_heavy_attack_damage(enemy, heavy_attack_damage)')

    dispatcher_hook = '''	if _t009_is_q_attack_kind(attack_kind):
		_t009_on_q_hit(target)
	if _t009_is_heavy_attack_kind(attack_kind):
		damage_amount = _t009_apply_heavy_modifiers_to_damage(target, damage_amount)
	if _t009_is_ultimate_attack_kind(attack_kind):
		_t009_on_ultimate_hit(target)

'''
    if dispatcher_hook.strip() not in text and "func _t004_call_damage_method(" in text:
        marker = '\tvar method_args: Array = []\n'
        if marker in text:
            text = text.replace(marker, dispatcher_hook + marker, 1)
        else:
            print("WARNING: T004 damage dispatcher marker not found; Q/ultimate hooks may be partial.")

    methods = '''
func receive_run_boon(payload: Dictionary) -> void:
	var patron_id: String = str(payload.get("patron_id", ""))
	var boon_id: String = str(payload.get("boon_id", payload.get("id", "")))
	if patron_id != "patron_azazel_chains":
		return
	if boon_id == "":
		return
	t009_owned_boons[boon_id] = payload.duplicate(true)
	print("[T009] Azazel boon received: %s" % boon_id)

func _t009_has_boon_token(token: String) -> bool:
	for raw_key: Variant in t009_owned_boons.keys():
		var boon_id: String = str(raw_key)
		if boon_id.find(token) >= 0:
			return true
	return false

func _t009_is_q_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("q") >= 0 or kind.find("riposte") >= 0 or kind.find("cleave") >= 0

func _t009_is_heavy_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("heavy") >= 0 or kind.find("grave") >= 0

func _t009_is_ultimate_attack_kind(attack_kind: String) -> bool:
	var kind: String = attack_kind.to_lower()
	return kind.find("ultimate") >= 0 or kind.find("judgment") >= 0 or kind.find("break") >= 0

func _t009_apply_light_attack_damage(target: Node, base_damage: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	target.call("take_damage", base_damage)
	_t009_on_light_hit(target)

func _t009_apply_heavy_attack_damage(target: Node, base_damage: int) -> void:
	var final_damage: int = _t009_apply_heavy_modifiers_to_damage(target, base_damage)
	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		target.call("take_damage", final_damage)

func _t009_apply_heavy_modifiers_to_damage(target: Node, base_damage: int) -> int:
	var final_damage: int = base_damage
	var consumed_mark: bool = false
	if target != null and is_instance_valid(target) and target.has_method("t009_consume_azazel_mark"):
		consumed_mark = bool(target.call("t009_consume_azazel_mark"))
	elif target != null and is_instance_valid(target) and bool(target.get_meta("t009_azazel_marked", false)):
		target.set_meta("t009_azazel_marked", false)
		consumed_mark = true
	if consumed_mark and _t009_has_boon_token("riposte_mark"):
		final_damage += 2
	if _t009_has_boon_token("heavy_bonus") or _t009_has_boon_token("chain_stagger"):
		if target != null and is_instance_valid(target) and target.has_method("t009_add_stagger_pressure"):
			target.call("t009_add_stagger_pressure", 35.0)
	if _t009_has_boon_token("chain_stagger"):
		final_damage += 1
	if _t009_has_boon_token("dash_bind") or _t009_has_boon_token("root"):
		if target != null and is_instance_valid(target) and target.has_method("t009_pull_toward"):
			target.call("t009_pull_toward", global_position, 145.0)
	return final_damage

func _t009_on_light_hit(target: Node) -> void:
	if not _t009_has_boon_token("echo_lash"):
		return
	t009_light_hit_count += 1
	if t009_light_hit_count % 3 != 0:
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	var best_target: Node = null
	var best_distance: float = INF
	for enemy_node: Node in enemies:
		if enemy_node == target:
			continue
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		if not enemy_node.has_method("take_damage"):
			continue
		var distance: float = global_position.distance_to((enemy_node as Node2D).global_position)
		if distance < 190.0 and distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	if best_target != null:
		best_target.call("take_damage", 1)
		if best_target.has_method("t009_apply_slow"):
			best_target.call("t009_apply_slow", 0.70, 0.8)

func _t009_on_q_hit(target: Node) -> void:
	if not _t009_has_boon_token("riposte_mark"):
		return
	if target == null or not is_instance_valid(target):
		return
	target.set_meta("t009_azazel_marked", true)
	if target.has_method("t009_apply_azazel_mark"):
		target.call("t009_apply_azazel_mark", 5.0)

func _t009_on_ultimate_hit(target: Node) -> void:
	if not _t009_has_boon_token("ultimate_shackle"):
		return
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("t009_apply_root"):
		target.call("t009_apply_root", 2.0)
	else:
		target.set_meta("t009_azazel_rooted", true)

func _t009_update_azazel_dash_effects(delta: float) -> void:
	if t009_bound_step_cooldown > 0.0:
		t009_bound_step_cooldown = maxf(0.0, t009_bound_step_cooldown - delta)
	if not _t009_has_boon_token("dash_bind"):
		return
	if t009_bound_step_cooldown > 0.0:
		return
	if not has_method("_is_dash_invulnerable"):
		return
	if not _is_dash_invulnerable():
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
	for enemy_node: Node in enemies:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not enemy_node is Node2D:
			continue
		if global_position.distance_to((enemy_node as Node2D).global_position) <= 56.0:
			if enemy_node.has_method("t009_apply_slow"):
				enemy_node.call("t009_apply_slow", 0.45, 1.25)
			t009_bound_step_cooldown = 0.18
'''
    text = append_once(text, methods)
    write(PLAYER, text)

def patch_enemy() -> None:
    text = read(ENEMY)
    if "var t009_azazel_mark_timer: float = 0.0" not in text:
        marker = 'var t006_base_modulate_captured: bool = false\n'
        insert = '''
# T-009 Azazel status hooks.
var t009_azazel_mark_timer: float = 0.0
var t009_azazel_root_timer: float = 0.0
var t009_azazel_slow_timer: float = 0.0
var t009_azazel_slow_multiplier: float = 1.0
var t009_azazel_base_move_speed: float = -1.0
'''
        if marker not in text:
            raise SystemExit("ERROR: T006 state marker not found in IsoTestEnemy.gd")
        text = text.replace(marker, marker + insert, 1)
    if "_t009_update_azazel_status(delta)" not in text:
        text = text.replace("_t006_update_enemy_interaction(delta)", "_t006_update_enemy_interaction(delta)\n\t_t009_update_azazel_status(delta)", 1)

    methods = '''
func t009_apply_azazel_mark(duration: float = 5.0) -> void:
	t009_azazel_mark_timer = maxf(t009_azazel_mark_timer, duration)
	set_meta("t009_azazel_marked", true)
	queue_redraw()

func t009_consume_azazel_mark() -> bool:
	if t009_azazel_mark_timer <= 0.0 and not bool(get_meta("t009_azazel_marked", false)):
		return false
	t009_azazel_mark_timer = 0.0
	set_meta("t009_azazel_marked", false)
	queue_redraw()
	return true

func t009_add_stagger_pressure(amount: float) -> void:
	t006_stagger_value += amount
	if t006_stagger_value >= t006_stagger_threshold:
		t006_stagger_timer = maxf(t006_stagger_timer, 0.8)

func t009_apply_root(duration: float = 1.5) -> void:
	t009_azazel_root_timer = maxf(t009_azazel_root_timer, duration)
	queue_redraw()

func t009_apply_slow(multiplier: float = 0.55, duration: float = 1.2) -> void:
	if t009_azazel_base_move_speed < 0.0:
		t009_azazel_base_move_speed = move_speed
	t009_azazel_slow_multiplier = clampf(multiplier, 0.15, 1.0)
	t009_azazel_slow_timer = maxf(t009_azazel_slow_timer, duration)
	move_speed = t009_azazel_base_move_speed * t009_azazel_slow_multiplier
	queue_redraw()

func t009_pull_toward(point: Vector2, force: float = 130.0) -> void:
	var direction: Vector2 = (point - global_position).normalized()
	if direction.length_squared() <= 0.001:
		return
	_knockback_velocity = direction * force
	_knockback_remaining = maxf(_knockback_remaining, 0.10)
	queue_redraw()

func _t009_update_azazel_status(delta: float) -> void:
	if t009_azazel_mark_timer > 0.0:
		t009_azazel_mark_timer = maxf(0.0, t009_azazel_mark_timer - delta)
		if t009_azazel_mark_timer <= 0.0:
			set_meta("t009_azazel_marked", false)
	if t009_azazel_root_timer > 0.0:
		t009_azazel_root_timer = maxf(0.0, t009_azazel_root_timer - delta)
		_state = EnemyState.RECOVERY
		_knockback_velocity = Vector2.ZERO
		_knockback_remaining = 0.0
	if t009_azazel_slow_timer > 0.0:
		t009_azazel_slow_timer = maxf(0.0, t009_azazel_slow_timer - delta)
		if t009_azazel_slow_timer <= 0.0 and t009_azazel_base_move_speed >= 0.0:
			move_speed = t009_azazel_base_move_speed
			t009_azazel_slow_multiplier = 1.0
	if t009_azazel_mark_timer > 0.0:
		modulate = Color(1.0, 0.82, 0.38, 1.0)
	elif t009_azazel_root_timer > 0.0:
		modulate = Color(0.70, 0.85, 1.0, 1.0)
'''
    text = append_once(text, methods)
    write(ENEMY, text)

def patch_controller() -> None:
    text = read(CONTROLLER)
    if "_grant_boon_payload_to_player(payload)" not in text:
        marker = 'reward_display_history.append("%s: %s" % [patron_name, display_name])\n'
        if marker not in text:
            raise SystemExit("ERROR: _claim_boon_payload marker not found")
        text = text.replace(marker, marker + "\t_grant_boon_payload_to_player(payload)\n", 1)
    methods = '''
func _grant_boon_payload_to_player(payload: Dictionary) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for player_node: Node in players:
		if player_node != null and is_instance_valid(player_node) and player_node.has_method("receive_run_boon"):
			player_node.call("receive_run_boon", payload)
'''
    text = append_once(text, methods)
    write(CONTROLLER, text)

def patch_tracker() -> None:
    if not TRACKER.exists():
        return
    try:
        data = json.loads(TRACKER.read_text())
    except Exception:
        return
    def walk(obj):
        if isinstance(obj, dict):
            if obj.get("id") == "S-008":
                obj["status"] = "Placeholder"
                obj["Status"] = "Placeholder"
                obj["notes"] = "T-009 adds first placeholder Azazel combat mechanics."
            for v in obj.values():
                walk(v)
        elif isinstance(obj, list):
            for v in obj:
                walk(v)
    walk(data)
    TRACKER.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

def main() -> None:
    patch_player()
    patch_enemy()
    patch_controller()
    patch_tracker()
    print("Applied T-009 Azazel boon mechanics placeholder patch.")

if __name__ == "__main__":
    main()
