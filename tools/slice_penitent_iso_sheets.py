#!/usr/bin/env python3
"""Re-slice the Penitent Knight source sheets into Godot-ready 128x128 animation sheets.
Run from the Godot project root after replacing files in art_source/penitent_knight_v2.
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image

FRAME_W = 128
FRAME_H = 128
ALPHA_CUTOFF = 10
DIRECTIONS = ["se", "sw", "nw", "ne"]
ROOT = Path("art_source/penitent_knight_v2")
OUT = Path("art/iso/player/penitent_v1")
SOURCES = {
    "idle": (ROOT / "idle_source_photoroom.png", 4, 4, OUT / "penitent_idle_4x1.png", OUT / "penitent_idle_iso_4x4.png"),
    "run": (ROOT / "run_source_photoroom.png", 6, 4, OUT / "penitent_walk_4x1.png", OUT / "penitent_run_iso_6x4.png"),
    "dash": (ROOT / "dash_source_photoroom.png", 4, 4, OUT / "penitent_dash_iso_4x4.png", OUT / "penitent_dash_4x4.png"),
    "hit": (ROOT / "hit_source_photoroom.png", 3, 4, OUT / "penitent_hit_iso_3x4.png", OUT / "penitent_hit_3x4.png"),
    "death": (ROOT / "death_source_photoroom.png", 6, 4, OUT / "penitent_death_iso_6x4.png", OUT / "penitent_death_6x4.png"),
    "respawn": (ROOT / "respawn_source_photoroom.png", 6, 4, OUT / "penitent_respawn_iso_6x4.png", OUT / "penitent_respawn_6x4.png"),
    "light_attack": (ROOT / "light_attack_source_photoroom.png", 5, 4, OUT / "penitent_attack_4x1.png", OUT / "penitent_light_attack_iso_5x4.png"),
    "heavy_attack": (ROOT / "heavy_attack_source_photoroom.png", 6, 4, OUT / "penitent_heavy_attack_iso_6x4.png", OUT / "penitent_heavy_attack_6x4.png"),
}

def clean_alpha(cell: Image.Image) -> Image.Image:
    cell = cell.convert("RGBA")
    pix = cell.load()
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = pix[x, y]
            if a <= ALPHA_CUTOFF:
                pix[x, y] = (0, 0, 0, 0)
    return cell

def process(name: str, src: Path, cols: int, rows: int, dst: Path, alias: Path) -> None:
    if not src.exists():
        print(f"SKIP {name}: missing {src}")
        return
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    sheet = Image.new("RGBA", (cols * FRAME_W, rows * FRAME_H), (0, 0, 0, 0))
    for r in range(rows):
        y0 = round(r * h / rows); y1 = round((r + 1) * h / rows)
        dname = DIRECTIONS[r] if r < len(DIRECTIONS) else f"row_{r}"
        frame_dir = OUT / "frames" / name / dname
        frame_dir.mkdir(parents=True, exist_ok=True)
        for c in range(cols):
            x0 = round(c * w / cols); x1 = round((c + 1) * w / cols)
            cell = clean_alpha(im.crop((x0, y0, x1, y1))).resize((FRAME_W, FRAME_H), Image.Resampling.LANCZOS)
            cell = clean_alpha(cell)
            sheet.alpha_composite(cell, (c * FRAME_W, r * FRAME_H))
            cell.save(frame_dir / f"{name}_{dname}_{c:02d}.png")
    dst.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dst)
    if alias != dst:
        alias.write_bytes(dst.read_bytes())
    print(f"OK {name}: {dst}")

def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, args in SOURCES.items():
        process(name, *args)
    # legacy compatibility strips
    dash = Image.open(OUT / "penitent_dash_iso_4x4.png").convert("RGBA")
    dash.crop((0, 0, 2 * FRAME_W, FRAME_H)).save(OUT / "penitent_dash_2x1.png")
    hit = Image.open(OUT / "penitent_hit_iso_3x4.png").convert("RGBA")
    hit.crop((0, 0, 2 * FRAME_W, FRAME_H)).save(OUT / "penitent_hit_2x1.png")

if __name__ == "__main__":
    main()
