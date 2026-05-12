#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path.cwd()
SCRIPT = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
REQUIRED_ASSETS = [
    "art/iso/player/penitent_v1/penitent_idle_iso_4x4.png",
    "art/iso/player/penitent_v1/penitent_walk_iso_6x4.png",
    "art/iso/player/penitent_v1/penitent_dash_iso_4x4.png",
    "art/iso/player/penitent_v1/penitent_hit_iso_3x4.png",
    "art/iso/player/penitent_v1/penitent_death_iso_6x4.png",
    "art/iso/player/penitent_v1/penitent_respawn_iso_6x4.png",
    "art/iso/player/penitent_v1/penitent_light_attack_iso_5x4.png",
    "art/iso/player/penitent_v1/penitent_heavy_attack_iso_6x4.png",
]
REQUIRED_SNIPPETS = [
    "func _lock_animation",
    "func _can_start_action",
    "func _face_for_attack",
    "func _direction_name_from_vector",
    "row_for_southeast",
    "row_for_southwest",
    "row_for_northwest",
    "row_for_northeast",
    "_get_animation_duration(\"attack\")",
    "_get_animation_duration(\"heavy_attack\")",
    "_get_animation_duration(\"dash\")",
]

def main() -> int:
    ok = True
    if not SCRIPT.exists():
        print(f"ERROR: missing {SCRIPT}")
        return 1
    text = SCRIPT.read_text(encoding="utf-8")
    for snippet in REQUIRED_SNIPPETS:
        if snippet not in text:
            print(f"ERROR: script missing expected animation-state snippet: {snippet}")
            ok = False
    for asset in REQUIRED_ASSETS:
        path = ROOT / asset
        if not path.exists():
            print(f"ERROR: missing V4 sprite asset: {asset}")
            ok = False
    if ok:
        print("OK: V5 animation state script is installed and V4 sprite assets are present.")
        print("Next: test idle, walk, dash, light attack, heavy attack, hit, death, respawn in Godot.")
        return 0
    print("Validation failed. Apply the V4 sprite patch first, then apply this V5 state patch.")
    return 1

if __name__ == "__main__":
    raise SystemExit(main())
