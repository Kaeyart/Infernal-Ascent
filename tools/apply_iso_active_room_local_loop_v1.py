#!/usr/bin/env python3
from pathlib import Path
import re
import shutil

SCENE = Path("scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn")
SCRIPT_PATH = "res://scripts/iso/IsoRoomLocalLoopController.gd"
RESOURCE_ID = "iso_room_local_loop_v1"

def main() -> int:
    if not SCENE.exists():
        print(f"[apply_iso_active_room_local_loop_v1] Missing scene: {SCENE}")
        return 1

    text = SCENE.read_text(encoding="utf-8")
    backup = SCENE.with_suffix(SCENE.suffix + ".bak_before_local_loop_v1")
    if not backup.exists():
        shutil.copy2(SCENE, backup)
        print(f"[apply_iso_active_room_local_loop_v1] Backup written: {backup}")

    changed = False

    if SCRIPT_PATH not in text:
        ext_line = f'[ext_resource type="Script" path="{SCRIPT_PATH}" id="{RESOURCE_ID}"]\n'
        ext_matches = list(re.finditer(r'^\[ext_resource[^\n]*\]\n?', text, flags=re.MULTILINE))
        if ext_matches:
            insert_at = ext_matches[-1].end()
            text = text[:insert_at] + ext_line + text[insert_at:]
        else:
            gd_match = re.search(r'^\[gd_scene[^\n]*\]\n?', text, flags=re.MULTILINE)
            if gd_match:
                insert_at = gd_match.end()
                text = text[:insert_at] + "\n" + ext_line + text[insert_at:]
            else:
                print("[apply_iso_active_room_local_loop_v1] Could not find gd_scene header.")
                return 1
        changed = True

        def bump_load_steps(match: re.Match) -> str:
            value = int(match.group(1))
            return match.group(0).replace(f"load_steps={value}", f"load_steps={value + 1}")

        text = re.sub(r'load_steps=(\d+)', bump_load_steps, text, count=1)

    if 'name="RoomLoopController"' not in text:
        node = f'''\n[node name="RoomLoopController" type="Node2D" parent="."]\nscript = ExtResource("{RESOURCE_ID}")\nrooms_until_run_end = 5\nrestart_key_enabled = true\nprint_debug = true\n'''
        text = text.rstrip() + "\n" + node + "\n"
        changed = True

    if changed:
        SCENE.write_text(text, encoding="utf-8")
        print("[apply_iso_active_room_local_loop_v1] Patched active room scene.")
    else:
        print("[apply_iso_active_room_local_loop_v1] Active room scene already patched.")

    print(f"[apply_iso_active_room_local_loop_v1] Target: res://{SCENE}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
