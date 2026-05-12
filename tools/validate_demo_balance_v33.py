#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path.cwd()

CHECKS = [
    ("scripts/iso/IsoPhysicsTestPlayer.gd", r"@export var max_health: int = 7", "player max health tuned"),
    ("scripts/iso/IsoPhysicsTestPlayer.gd", r"@export var contact_damage_iframe_duration: float = 0\.68", "player i-frame duration tuned"),
    ("scripts/iso/IsoPhysicsTestPlayer.gd", r"@export var light_attack_arc_degrees: float = 122\.0", "light attack arc tuned"),
    ("scripts/iso/IsoTestEnemy.gd", r"if wave_index >= 4:", "enemy scaling delayed"),
    ("scripts/iso/IsoTestEnemy.gd", r"attack_windup_duration = 0\.64", "cinder lunger windup tuned"),
    ("scripts/iso/IsoTestEnemy.gd", r"projectile_speed = 165\.0", "ember projectile speed tuned"),
    ("scripts/iso/IsoTestEnemy.gd", r"support_pulse_strength = 0\.32", "bell wretch support tuned"),
    ("scripts/iso/AshWardenBoss.gd", r"@export var max_health: int = 90", "boss default health tuned"),
    ("scripts/iso/AshWardenBoss.gd", r"@export var seal_stagger_damage: int = 10", "boss seal reward tuned"),
    ("scripts/iso/IsoRoomHazard.gd", r"@export var windup_duration: float = 1\.55", "hazard warning duration tuned"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"@export var ash_warden_max_health_v24: int = 90", "boss run health tuned"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"@export var demo_death_base_ash_sigils: int = 1", "death progress tuned"),
]

errors: list[str] = []
for rel, pattern, description in CHECKS:
    path = ROOT / rel
    if not path.exists():
        errors.append(f"Missing {rel} ({description})")
        continue
    text = path.read_text(encoding="utf-8")
    if re.search(pattern, text) is None:
        errors.append(f"Failed check: {description} in {rel}")

if errors:
    print("V33 validation failed:")
    for error in errors:
        print(" - " + error)
    raise SystemExit(1)

print("V33 validation passed: demo balance values are installed.")
