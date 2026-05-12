#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path.cwd()
script = root / "scripts/iso/IsoPhysicsTestPlayer.gd"
if not script.exists():
    print("ERROR: missing scripts/iso/IsoPhysicsTestPlayer.gd")
    sys.exit(1)
text = script.read_text()
required = [
    "light_attack_active_start_frame",
    "heavy_attack_active_start_frame",
    "dash_invulnerable_start_frame",
    "_update_combat_timing",
    "_apply_active_attack_hit",
    "_active_attack_hit_targets",
    "_is_dash_invulnerable",
    "show_debug_combat_hitbox",
]
missing = [item for item in required if item not in text]
if missing:
    print("ERROR: missing V7 combat timing markers:")
    for item in missing:
        print(" -", item)
    sys.exit(1)
for path in [
    root / "art/iso/player/penitent_v1/penitent_light_attack_iso_5x4.png",
    root / "art/iso/player/penitent_v1/penitent_heavy_attack_iso_6x4.png",
    root / "art/iso/player/penitent_v1/penitent_dash_iso_4x4.png",
]:
    if not path.exists():
        print(f"WARNING: missing expected sprite sheet: {path}")
print("OK: Player Combat Timing V1 / V7 script markers are installed.")
print("Test in Godot: light attack should damage only on frames 2-3; heavy on frames 3-4; dash ignores take_damage on frames 0-2.")
