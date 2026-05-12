#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
checks = []

def require(path: str, needles: list[str]) -> None:
    p = ROOT / path
    if not p.exists():
        print(f"MISSING: {path}")
        sys.exit(1)
    text = p.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            print(f"MISSING in {path}: {needle}")
            sys.exit(1)
        checks.append((path, needle))

require("scripts/iso/IsoTestEnemy.gd", [
    '"ash_grunt"',
    '"cinder_lunger"',
    '"ember_spitter"',
    '"chainbound_penitent"',
    '"furnace_imp"',
    '"bell_wretch"',
    "support_pulse_enabled",
    "receive_support_pulse",
    "_draw_support_warning",
    "_get_role_text",
    "ARMORED",
    "SUPPORT",
])

require("scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd", [
    "max_enemies_cycle_4_plus",
    "_get_v18_variant_profiles",
    '"chainbound_penitent"',
    '"furnace_imp"',
    '"bell_wretch"',
])

require("docs/ENEMY_CONSISTENCY_PASS_V18.md", [
    "V18",
    "Ash Grunt",
    "Cinder Lunger",
    "Ember Spitter",
    "Chainbound Penitent",
    "Furnace Imp",
    "Bell Wretch",
])

print(f"V18 enemy consistency validation passed ({len(checks)} checks).")
