#!/usr/bin/env python3
from pathlib import Path

ROOT = Path.cwd()
checks = [
    ("scripts/iso/IsoPhysicsTestPlayer.gd", [
        "func receive_run_boon(payload: Dictionary) -> void:",
        "func _t009_on_q_hit(target: Node) -> void:",
        "func _t009_on_ultimate_hit(target: Node) -> void:",
        "func _t009_update_azazel_dash_effects(delta: float) -> void:",
        "_t009_apply_light_attack_damage",
    ]),
    ("scripts/iso/IsoTestEnemy.gd", [
        "func t009_apply_azazel_mark",
        "func t009_consume_azazel_mark",
        "func t009_apply_root",
        "func t009_apply_slow",
        "func t009_pull_toward",
        "func _t009_update_azazel_status",
    ]),
    ("scripts/iso/IsoRoomLocalLoopController.gd", [
        "func _grant_boon_payload_to_player(payload: Dictionary) -> void:",
        "_grant_boon_payload_to_player(payload)",
    ]),
]
ok = True
for rel, needles in checks:
    path = ROOT / rel
    if not path.exists():
        print(f"ERROR: Missing {rel}")
        ok = False
        continue
    text = path.read_text()
    for needle in needles:
        if needle not in text:
            print(f"ERROR: {rel} missing: {needle}")
            ok = False
for rel in ["scripts/iso/IsoPhysicsTestPlayer.gd", "scripts/iso/IsoTestEnemy.gd"]:
    path = ROOT / rel
    if path.exists():
        text = path.read_text()
        for bad in ["_t006_update_enemy_interaction(delta: float)", "class_name IsoPhysicsTestPlayer\nclass_name IsoPhysicsTestPlayer", "class_name IsoTestEnemy\nclass_name IsoTestEnemy"]:
            if bad in text:
                print(f"ERROR: {rel} contains parser-risk pattern: {bad}")
                ok = False
if ok:
    print("T-009 validation passed.")
else:
    raise SystemExit(1)
