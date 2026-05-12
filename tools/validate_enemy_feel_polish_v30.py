#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
files = {
    "enemy": root / "scripts/iso/IsoTestEnemy.gd",
    "projectile": root / "scripts/iso/AshBoltProjectile.gd",
    "boss": root / "scripts/iso/AshWardenBoss.gd",
    "doc": root / "docs/ENEMY_FEEL_POLISH_V30.md",
}
errors = []
for label, path in files.items():
    if not path.exists():
        errors.append(f"Missing {path}")

checks = {
    "enemy": [
        "@export_category(\"Feel Polish\")",
        "spawn_intro_duration",
        "hit_burst_duration",
        "death_burst_duration",
        "attack_commit_flash_duration",
        "telegraph_pulse_speed",
        "signal feel_event",
        "_draw_spawn_intro",
        "_draw_feel_bursts",
        "_emit_feel_event",
    ],
    "projectile": [
        "signal feel_event",
        "trail_sample_interval",
        "max_trail_points",
        "_trail_points",
        "_update_trail",
        "projectile_hit",
    ],
    "boss": [
        "@export_category(\"Feel Polish\")",
        "boss_hit_burst_duration",
        "phase_transition_burst_duration",
        "boss_death_burst_duration",
        "_draw_boss_feel_rings",
        "boss_phase_changed",
        "boss_death",
    ],
}

for label, needles in checks.items():
    path = files[label]
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            errors.append(f"{path} missing required V30 token: {needle}")

if errors:
    print("V30 validation failed:")
    for e in errors:
        print(" -", e)
    raise SystemExit(1)

print("V30 validation passed: Enemy Feel Polish files are present.")
