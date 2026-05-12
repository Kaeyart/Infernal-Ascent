#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
REQUIRED = {
    "scripts/iso/IsoTestEnemy.gd": [
        "func _draw_melee_warning",
        "func _draw_lunge_warning",
        "func _draw_projectile_warning",
        "SWIPE",
        "LUNGE",
        "SHOT",
        "show_readability_labels",
    ],
    "scripts/iso/IsoRoomHazard.gd": [
        "WARNING",
        "DANGER",
        "func _draw_iso_fill",
        "warning_ring_width",
        "active_ring_width",
    ],
    "scripts/iso/AshBoltProjectile.gd": [
        "draw_readability_trail",
        "danger_ring_alpha",
        "_pulse_time",
    ],
    "scripts/iso/IsoPhysicsTestPlayer.gd": [
        "show_readability_hit_feedback",
        "func _draw_readability_damage_state",
    ],
    "docs/COMBAT_READABILITY_CONSISTENCY_PASS_V16.md": [
        "V16",
        "Combat Readability",
    ],
}

errors = []
for rel, needles in REQUIRED.items():
    path = ROOT / rel
    if not path.exists():
        errors.append(f"missing {rel}")
        continue
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            errors.append(f"{rel}: missing marker {needle!r}")

if errors:
    print("V16 validation failed:")
    for err in errors:
        print(" -", err)
    sys.exit(1)

print("V16 validation passed: combat readability files and markers are present.")
