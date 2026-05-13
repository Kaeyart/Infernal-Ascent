#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path.cwd()
checks = [
    (ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd", [
        "var t010_mammon_boons",
        "func _t010_record_mammon_boon",
        "func _t010_apply_mammon_hit_effects",
        "func _t010_update_mammon_player_effects",
    ]),
    (ROOT / "scripts/iso/IsoTestEnemy.gd", [
        "var t010_burn_timer",
        "func t010_apply_burn",
        "func t010_is_burning",
        "func _t010_update_mammon_enemy_effects",
    ]),
    (ROOT / "scripts/iso/IsoRoomLocalLoopController.gd", [
        "func _t010_grant_boon_to_player",
        "_t010_grant_boon_to_player(payload)",
    ]),
    (ROOT / "docs/MAMMON_BOON_MECHANICS_T010.md", [
        "T-010",
        "Mammon",
    ]),
]

ok = True
for path, needles in checks:
    if not path.exists():
        print(f"FAIL missing: {path}")
        ok = False
        continue
    text = path.read_text()
    for needle in needles:
        if needle not in text:
            print(f"FAIL {path}: missing {needle!r}")
            ok = False
        else:
            print(f"OK {path}: {needle}")

if not ok:
    sys.exit(1)

print("T-010 Mammon boon mechanics validation passed.")
