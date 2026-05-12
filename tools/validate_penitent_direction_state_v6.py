#!/usr/bin/env python3
from pathlib import Path
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
    "V6 uses deterministic screen-input facing",
    "right -> ne, left -> sw, up -> nw, down -> se",
    "if previous_dir_name != _facing_dir_name:",
    "_apply_sprite_frame()",
    "return \"ne\" if direction.x >= 0.0 else \"sw\"",
    "return \"se\" if direction.y >= 0.0 else \"nw\"",
    "func _lock_animation",
    "func _can_start_action",
]

def main() -> int:
    ok = True
    if not SCRIPT.exists():
        print(f"ERROR: missing {SCRIPT}")
        return 1
    text = SCRIPT.read_text(encoding="utf-8")
    for snippet in REQUIRED_SNIPPETS:
        if snippet not in text:
            print(f"ERROR: script missing V6 direction snippet: {snippet}")
            ok = False
    for asset in REQUIRED_ASSETS:
        if not (ROOT / asset).exists():
            print(f"ERROR: missing sprite asset from V4 patch: {asset}")
            ok = False
    if ok:
        print("OK: V6 direction-state script is installed and V4 sprite assets are present.")
        print("Expected deterministic input rows:")
        print("  D / Right -> northeast row")
        print("  A / Left  -> southwest row")
        print("  W / Up    -> northwest row")
        print("  S / Down  -> southeast row")
        print("Idle must hold the last selected direction after movement stops.")
        return 0
    print("Validation failed. Apply V4 sprites first, then V6 direction patch.")
    return 1

if __name__ == "__main__":
    raise SystemExit(main())
