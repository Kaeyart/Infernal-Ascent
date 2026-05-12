#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path.cwd()
ASSET = ROOT / "art/iso/player/penitent_v1"
EXPECTED = {
    "penitent_idle_iso_4x4.png": (4*320,4*320),
    "penitent_walk_iso_6x4.png": (6*320,4*320),
    "penitent_dash_iso_4x4.png": (4*320,4*320),
    "penitent_hit_iso_3x4.png": (3*320,4*320),
    "penitent_death_iso_6x4.png": (6*320,4*320),
    "penitent_respawn_iso_6x4.png": (6*320,4*320),
    "penitent_light_attack_iso_5x4.png": (5*320,4*320),
    "penitent_heavy_attack_iso_6x4.png": (6*320,4*320),
}

ok = True
for name, size in EXPECTED.items():
    path = ASSET / name
    if not path.exists():
        print(f"MISSING {path}")
        ok = False
        continue
    with Image.open(path) as im:
        if im.size != size:
            print(f"BAD SIZE {name}: {im.size} expected {size}")
            ok = False
        else:
            print(f"OK {name} {im.size}")
if not ok:
    raise SystemExit(1)
print("Penitent V4 sprite assets validated.")
