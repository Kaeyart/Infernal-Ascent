#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path.cwd()
checks = {
    "scripts/iso/IsoPhysicsTestPlayer.gd": [
        "current_health",
        "contact_damage_iframe_duration",
        "func take_damage(amount: int = 1) -> bool",
        "play_death_animation",
        "_deliver_attack_damage_to_target",
        "receive_player_hit",
    ],
    "scripts/iso/IsoTestEnemy.gd": [
        "contact_damage_enabled",
        "contact_damage_cooldown",
        "func receive_player_hit",
        "_update_contact_damage",
        "_apply_knockback",
        "_damage_numbers",
    ],
    "scripts/iso/hub/IsoHubTrainingDummy.gd": [
        "func receive_player_hit",
        "_visual_recoil_offset",
        "recoil_distance_heavy",
        "hit_flash_duration",
    ],
}
failed = False
for rel_path, markers in checks.items():
    path = root / rel_path
    if not path.exists():
        print(f"ERROR: missing {rel_path}")
        failed = True
        continue
    text = path.read_text()
    missing = [marker for marker in markers if marker not in text]
    if missing:
        print(f"ERROR: {rel_path} missing markers:")
        for marker in missing:
            print(" -", marker)
        failed = True
if failed:
    sys.exit(1)
print("OK: Enemy Contact / Hurt Reaction V1 / V8 markers are installed.")
print("Test: dummy recoils on hit; enemies flash/knock back; enemy contact damages player with cooldown; dash avoids contact damage.")
