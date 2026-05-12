#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
from PIL import Image
import sys

ROOT = Path("art/iso/player/penitent_v1")
FILES = [
    ("idle", "penitent_idle_4x1.png", 4, 4),
    ("run", "penitent_walk_4x1.png", 6, 4),
    ("light_attack", "penitent_attack_4x1.png", 5, 4),
    ("heavy_attack", "penitent_heavy_attack_iso_6x4.png", 6, 4),
    ("dash", "penitent_dash_iso_4x4.png", 4, 4),
    ("hit", "penitent_hit_iso_3x4.png", 3, 4),
    ("death", "penitent_death_iso_6x4.png", 6, 4),
    ("respawn", "penitent_respawn_iso_6x4.png", 6, 4),
]

def main() -> None:
    ok = True
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    base = root / ROOT
    for name, file_name, cols, rows in FILES:
        path = base / file_name
        if not path.exists():
            print(f"FAIL {name}: missing {path}")
            ok = False
            continue
        img = Image.open(path).convert("RGBA")
        w, h = img.size
        if w % cols != 0 or h % rows != 0:
            print(f"FAIL {name}: {w}x{h} not divisible by {cols}x{rows}")
            ok = False
            continue
        frame = (w // cols, h // rows)
        if frame != (128, 128):
            print(f"WARN {name}: frame is {frame[0]}x{frame[1]}, expected 128x128")
        alpha = img.getchannel("A")
        if alpha.getextrema()[0] >= 255:
            print(f"WARN {name}: no transparency detected")
        print(f"OK   {name:12s}: {w}x{h}, grid {cols}x{rows}, frame {frame[0]}x{frame[1]}")
    if not ok:
        raise SystemExit(1)
    print("Validation passed.")

if __name__ == "__main__":
    main()
