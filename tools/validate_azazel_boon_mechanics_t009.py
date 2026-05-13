#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
checks = [
    (ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd", ["func apply_run_boon", "_t009_pre_damage_azazel_effects", "_t009_update_bound_step_dash_slow"]),
    (ROOT / "scripts/iso/IsoTestEnemy.gd", ["func apply_azazel_mark", "func apply_azazel_slow", "func apply_azazel_root", "_t009_update_azazel_enemy_effects"]),
    (ROOT / "scripts/iso/IsoRoomLocalLoopController.gd", ["_t009_notify_players_of_boon"]),
    (ROOT / "docs/AZAZEL_BOON_MECHANICS_T009.md", ["T-009"]),
]
failed = False
for path, needles in checks:
    if not path.exists():
        print(f"MISSING: {path}")
        failed = True
        continue
    text = path.read_text()
    for needle in needles:
        if needle not in text:
            print(f"MISSING in {path}: {needle}")
            failed = True
if failed:
    sys.exit(1)
print("T-009 Azazel boon mechanics validation passed.")
