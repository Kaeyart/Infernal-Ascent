#!/usr/bin/env python3
"""Slice Infernal Ascent Circle 0 enemy sheets into Godot-ready PNG frames.

Expected source images, relative to art/actors/enemies/circle0/source/:
- ash_wretch_source_sheet.png
- gate_warden_source_sheet.png
- cinder_scribe_source_sheet.png
- bell_hound_source_sheet.png
- vestibule_bailiff_source_sheet.png

Each sheet is expected to be a 4x4 grid:
row 1 = down, row 2 = left, row 3 = right, row 4 = up
columns = frames 01..04
"""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path
from typing import Dict, List

from PIL import Image, ImageDraw, ImageFont

ENEMIES: Dict[str, str] = {
    "ash_wretch": "ash_wretch_source_sheet.png",
    "gate_warden": "gate_warden_source_sheet.png",
    "cinder_scribe": "cinder_scribe_source_sheet.png",
    "bell_hound": "bell_hound_source_sheet.png",
    "vestibule_bailiff": "vestibule_bailiff_source_sheet.png",
}

DIRECTIONS: List[str] = ["down", "left", "right", "up"]
CANVAS_SIZE = 320
ALPHA_THRESHOLD = 12


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha <= ALPHA_THRESHOLD:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (red, green, blue, alpha)

    return image


def slice_sheet(project_root: Path) -> None:
    root = project_root / "art" / "actors" / "enemies" / "circle0"
    source_root = root / "source"
    manifest_root = root / "manifest"
    contact_root = root / "contact_sheets"

    manifest_root.mkdir(parents=True, exist_ok=True)
    contact_root.mkdir(parents=True, exist_ok=True)

    manifest = []

    for enemy_key, source_name in ENEMIES.items():
        source_path = source_root / source_name
        if not source_path.exists():
            raise FileNotFoundError(f"Missing source sheet: {source_path}")

        image = clean_alpha(Image.open(source_path))
        width, height = image.size
        xs = [round(i * width / 4) for i in range(5)]
        ys = [round(i * height / 4) for i in range(5)]

        enemy_root = root / enemy_key
        enemy_root.mkdir(parents=True, exist_ok=True)

        for row, direction in enumerate(DIRECTIONS):
            for column in range(4):
                cell = image.crop((xs[column], ys[row], xs[column + 1], ys[row + 1]))
                canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
                paste_x = (CANVAS_SIZE - cell.size[0]) // 2
                paste_y = (CANVAS_SIZE - cell.size[1]) // 2
                canvas.alpha_composite(cell, (paste_x, paste_y))

                filename = f"{enemy_key}_{direction}_{column + 1:02d}.png"
                output_path = enemy_root / filename
                canvas.save(output_path)

                manifest.append(
                    {
                        "enemy_key": enemy_key,
                        "direction": direction,
                        "frame": column + 1,
                        "file": str(Path("art/actors/enemies/circle0") / enemy_key / filename),
                        "source": source_name,
                        "cell": [xs[column], ys[row], xs[column + 1] - xs[column], ys[row + 1] - ys[row]],
                    }
                )

    write_manifest(manifest_root, manifest)
    write_contact_sheet(root, contact_root, manifest)


def write_manifest(manifest_root: Path, manifest: list[dict]) -> None:
    with open(manifest_root / "circle0_enemy_sprites_manifest.csv", "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["enemy_key", "direction", "frame", "file", "source", "cell"])
        writer.writeheader()
        writer.writerows(manifest)

    with open(manifest_root / "circle0_enemy_sprites_manifest.json", "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)


def write_contact_sheet(root: Path, contact_root: Path, manifest: list[dict]) -> None:
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
        label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    except Exception:
        title_font = None
        label_font = None

    thumb_width = 130
    thumb_height = 130
    title_height = 28
    columns = 8
    rows = math.ceil(len(manifest) / columns)

    sheet = Image.new("RGBA", (columns * thumb_width, title_height + rows * thumb_height), (13, 11, 11, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((12, 6), "Circle 0 Enemy Sprites V1 - sliced frames", fill=(240, 220, 180, 255), font=title_font)

    for index, item in enumerate(manifest):
        row = index // columns
        column = index % columns
        image = Image.open(root.parent.parent.parent.parent / item["file"]).convert("RGBA")
        image.thumbnail((104, 104), Image.Resampling.LANCZOS)

        x = column * thumb_width + (thumb_width - image.size[0]) // 2
        y = title_height + row * thumb_height + 20 + (104 - image.size[1]) // 2
        sheet.alpha_composite(image, (x, y))

        draw.rectangle(
            (column * thumb_width, title_height + row * thumb_height, column * thumb_width + thumb_width - 1, title_height + (row + 1) * thumb_height - 1),
            outline=(60, 48, 42, 255),
        )
        draw.text(
            (column * thumb_width + 4, title_height + row * thumb_height + 4),
            f"{item['enemy_key']}\n{item['direction']}_{int(item['frame']):02d}",
            fill=(190, 170, 140, 255),
            font=label_font,
        )

    sheet.save(contact_root / "ALL_CIRCLE0_ENEMY_FRAMES_CONTACT_SHEET.png")


if __name__ == "__main__":
    slice_sheet(Path.cwd())
