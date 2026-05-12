#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
player = root / "scripts/iso/IsoPhysicsTestPlayer.gd"
doc = root / "docs/PLAYER_FEEL_POLISH_V29.md"

errors = []
if not player.exists():
    errors.append(f"Missing {player}")
else:
    text = player.read_text(encoding="utf-8")
    required = [
        "@export_category(\"Feel Polish\")",
        "movement_acceleration",
        "movement_deceleration",
        "attack_movement_multiplier",
        "heavy_attack_movement_multiplier",
        "hit_pause_duration_light",
        "hit_pause_duration_heavy",
        "screen_shake_enabled",
        "_start_screen_shake",
        "_update_screen_shake",
        "_register_successful_attack_hit",
        "_draw_dash_streak",
        "_draw_death_respawn_bursts",
        "velocity.move_toward",
    ]
    for needle in required:
        if needle not in text:
            errors.append(f"IsoPhysicsTestPlayer.gd missing required V29 token: {needle}")

if not doc.exists():
    errors.append(f"Missing {doc}")

if errors:
    print("V29 validation failed:")
    for e in errors:
        print(" -", e)
    raise SystemExit(1)

print("V29 validation passed: Player Feel Polish files are present.")
