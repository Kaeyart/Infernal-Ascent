#!/usr/bin/env python3
"""
Robust grid-based sprite slicer for Infernal Ascent asset sheets.

Why this exists:
- Connected-component slicing can cut off horns, chains, glow, smoke, candles, or disconnected pieces.
- This slicer treats the sheet as an authored grid first.
- It optionally alpha-trims each cell, but with generous padding.
- It writes a contact sheet and manifest so you can inspect before using assets in Godot.

Requires:
    pip install pillow

Examples:

Room doors, 4 rows x 3 columns:
    python3 tools/smart_sprite_slicer.py \
        --source /home/kaey/Desktop/Assets/Room_Doors.png \
        --out art/props/room_doors_v2 \
        --rows 4 --cols 3 \
        --names north,east,west \
        --prefix circle \
        --kill-green \
        --trim-alpha \
        --pad 24

Special room props, 5 rows x 4 columns:
    python3 tools/smart_sprite_slicer.py \
        --source /home/kaey/Desktop/Assets/Special_Room_Props.png \
        --out art/props/special_rooms \
        --rows 5 --cols 4 \
        --row-names forge,fountain,shrine,shop,reward \
        --prefix prop \
        --kill-green \
        --trim-alpha \
        --pad 28

Safer no-trim mode, if trim cuts anything:
    python3 tools/smart_sprite_slicer.py \
        --source /home/kaey/Desktop/Assets/Room_Doors.png \
        --out art/props/room_doors_cells \
        --rows 4 --cols 3 \
        --names north,east,west \
        --prefix circle \
        --kill-green \
        --no-trim
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw


def parse_csv(value: str) -> list[str]:
    if value.strip() == "":
        return []
    return [part.strip() for part in value.split(",") if part.strip()]


def kill_green_pixels(img: Image.Image, green_threshold: int, red_max: int, blue_max: int) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and g >= green_threshold and r <= red_max and b <= blue_max:
                px[x, y] = (r, g, b, 0)

    return img


def alpha_bbox_with_threshold(img: Image.Image, alpha_threshold: int) -> Optional[tuple[int, int, int, int]]:
    alpha = img.getchannel("A")
    # Pillow's getbbox treats any nonzero alpha as occupied. We want a threshold.
    if alpha_threshold <= 0:
        return alpha.getbbox()

    mask = alpha.point(lambda a: 255 if a > alpha_threshold else 0)
    return mask.getbbox()


def trim_with_padding(cell: Image.Image, pad: int, alpha_threshold: int) -> Image.Image:
    bbox = alpha_bbox_with_threshold(cell, alpha_threshold)

    if bbox is None:
        return cell

    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(cell.width, x1 + pad)
    y1 = min(cell.height, y1 + pad)

    return cell.crop((x0, y0, x1, y1))


def make_contact_sheet(exports: list[dict], out_path: Path, cols: int) -> None:
    if not exports:
        return

    thumb_w = 240
    thumb_h = 210
    rows = (len(exports) + cols - 1) // cols

    sheet = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)

    for i, item in enumerate(exports):
        sprite = Image.open(item["path"]).convert("RGBA")
        sprite.thumbnail((thumb_w - 24, thumb_h - 50), Image.Resampling.NEAREST)

        cell_x = (i % cols) * thumb_w
        cell_y = (i // cols) * thumb_h

        px = cell_x + (thumb_w - sprite.width) // 2
        py = cell_y + 34 + (thumb_h - 54 - sprite.height) // 2

        sheet.alpha_composite(sprite, (px, py))
        label = f'{item["file"]} {item["size"][0]}x{item["size"][1]}'
        draw.text((cell_x + 8, cell_y + 8), label, fill=(255, 230, 180, 255))
        draw.rectangle(
            (cell_x + 1, cell_y + 1, cell_x + thumb_w - 2, cell_y + thumb_h - 2),
            outline=(120, 80, 50, 255),
        )

    sheet.save(out_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Robust grid-based sprite slicer.")
    parser.add_argument("--source", required=True, help="Source PNG path.")
    parser.add_argument("--out", required=True, help="Output directory.")
    parser.add_argument("--rows", required=True, type=int, help="Number of grid rows.")
    parser.add_argument("--cols", required=True, type=int, help="Number of grid columns.")
    parser.add_argument("--prefix", default="sprite", help="Filename prefix.")
    parser.add_argument("--names", default="", help="Column names, comma-separated. Example: north,east,west")
    parser.add_argument("--row-names", default="", help="Row names, comma-separated. Example: forge,fountain,shrine")
    parser.add_argument("--kill-green", action="store_true", help="Remove chroma green pixels.")
    parser.add_argument("--green-threshold", type=int, default=150)
    parser.add_argument("--red-max", type=int, default=130)
    parser.add_argument("--blue-max", type=int, default=130)
    parser.add_argument("--trim-alpha", action="store_true", help="Trim transparent borders inside each grid cell.")
    parser.add_argument("--no-trim", action="store_true", help="Disable trimming explicitly.")
    parser.add_argument("--pad", type=int, default=24, help="Padding around alpha bbox when trimming.")
    parser.add_argument("--alpha-threshold", type=int, default=4, help="Alpha threshold for bbox trimming.")
    parser.add_argument("--save-cells", action="store_true", help="Also save raw untrimmed cells for debugging.")

    args = parser.parse_args()

    source = Path(args.source)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    if not source.exists():
        raise SystemExit(f"Missing source: {source}")

    img = Image.open(source).convert("RGBA")

    if args.kill_green:
        img = kill_green_pixels(img, args.green_threshold, args.red_max, args.blue_max)

    w, h = img.size
    cell_w = w / args.cols
    cell_h = h / args.rows

    col_names = parse_csv(args.names)
    row_names = parse_csv(args.row_names)

    exports: list[dict] = []

    raw_dir = out_dir / "_raw_cells"
    if args.save_cells:
        raw_dir.mkdir(parents=True, exist_ok=True)

    for row in range(args.rows):
        for col in range(args.cols):
            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)

            cell = img.crop((left, top, right, bottom))

            if args.save_cells:
                raw_name = f"raw_r{row + 1:02d}_c{col + 1:02d}.png"
                cell.save(raw_dir / raw_name)

            sprite = cell

            if args.trim_alpha and not args.no_trim:
                sprite = trim_with_padding(cell, args.pad, args.alpha_threshold)

            row_label = row_names[row] if row < len(row_names) else f"{row + 1:02d}"
            col_label = col_names[col] if col < len(col_names) else f"{col + 1:02d}"

            # For row-named prop sheets: prop_forge_01.png
            # For tiered door sheets: circle_01_north.png
            if row_names:
                file_name = f"{args.prefix}_{row_label}_{col + 1:02d}.png"
            else:
                file_name = f"{args.prefix}_{row + 1:02d}_{col_label}.png"

            out_path = out_dir / file_name
            sprite.save(out_path)

            exports.append({
                "file": file_name,
                "path": str(out_path),
                "row": row + 1,
                "col": col + 1,
                "row_label": row_label,
                "col_label": col_label,
                "source_cell": [left, top, right, bottom],
                "size": [sprite.width, sprite.height],
            })

    manifest = {
        "source": str(source),
        "output": str(out_dir),
        "rows": args.rows,
        "cols": args.cols,
        "trim_alpha": bool(args.trim_alpha and not args.no_trim),
        "pad": args.pad,
        "exports": exports,
    }

    (out_dir / "_manifest.json").write_text(json.dumps(manifest, indent=2))
    make_contact_sheet(exports, out_dir / "_contact_sheet.png", args.cols)

    print(f"Sliced {len(exports)} sprites into {out_dir}")
    print(f"Manifest: {out_dir / '_manifest.json'}")
    print(f"Contact sheet: {out_dir / '_contact_sheet.png'}")


if __name__ == "__main__":
    main()
