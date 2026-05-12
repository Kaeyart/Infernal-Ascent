#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "scripts/iso/IsoPhysicsTestPlayer.gd",
    "scripts/iso/IsoTestEnemy.gd",
    "scripts/iso/AshBoltProjectile.gd",
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "docs/ASH_INTAKE_COMBAT_ENCOUNTER_V1.md",
]
TOKENS = {
    "scripts/iso/IsoTestEnemy.gd": [
        "ash_grunt", "cinder_lunger", "ember_spitter",
        "EnemyState", "_start_windup", "_start_active", "_fire_projectile",
        "show_debug_active_hitbox",
    ],
    "scripts/iso/AshBoltProjectile.gd": [
        "class_name AshBoltProjectile", "receive_enemy_attack", "queue_free",
    ],
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd": [
        "use_encounter_director", "set_encounter_cycle_index", "_get_encounter_profiles",
        "configure_for_encounter_type",
    ],
    "scripts/iso/IsoRoomLocalLoopController.gd": [
        "set_encounter_cycle_index", "Ash Intake Combat Encounter V1",
    ],
    "scripts/iso/IsoPhysicsTestPlayer.gd": [
        "receive_enemy_attack", "_apply_enemy_hit_knockback", "enemy_hit_knockback_speed",
    ],
}

def fail(msg: str) -> None:
    print("[V9 VALIDATION FAILED]", msg)
    sys.exit(1)

for rel in REQUIRED:
    if not (ROOT / rel).exists():
        fail(f"Missing required file: {rel}")

for rel, tokens in TOKENS.items():
    text = (ROOT / rel).read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"{rel} missing token: {token}")

print("[V9 VALIDATION OK] Ash Intake Combat Encounter V1 files are present.")
print("Next: run Godot and test hub -> Ash Intake Hall -> enemy waves -> patron/gate -> return loop.")
