#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
import json

SOURCE_CANDIDATES = [
    Path("/home/kaey/Desktop/Assets/Special_Room_Props.png"),
    Path("/mnt/data/Special_Room_Props.png"),
]
OUT_DIR = Path("art/props/special_rooms")
OUT_DIR.mkdir(parents=True, exist_ok=True)

source = None
for candidate in SOURCE_CANDIDATES:
    if candidate.exists():
        source = candidate
        break

if source is None:
    raise SystemExit("Missing Special_Room_Props.png. Expected /home/kaey/Desktop/Assets/Special_Room_Props.png")

img = Image.open(source).convert("RGBA")
w, h = img.size
pixels = img.load()

# Kill remaining chroma green, but preserve actual object pixels.
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 0 and g > 145 and r < 140 and b < 140:
            pixels[x, y] = (r, g, b, 0)

rows = 5
cols = 4

# Row interpretation from the generated sheet:
# 1 forge/anvil, 2 fountain/blood statue, 3 shrine/altar, 4 shop/stall, 5 reward chest.
row_names = ["forge", "fountain", "shrine", "shop", "reward"]

cell_w = w / cols
cell_h = h / rows
PAD = 40

exports = []

def alpha_bbox(image):
    return image.getchannel("A").getbbox()

raw_dir = OUT_DIR / "_raw_cells"
raw_dir.mkdir(parents=True, exist_ok=True)

for row in range(rows):
    prop_id = row_names[row]

    for col in range(cols):
        variant = col + 1

        left = round(col * cell_w)
        top = round(row * cell_h)
        right = round((col + 1) * cell_w)
        bottom = round((row + 1) * cell_h)

        cell = img.crop((left, top, right, bottom))
        raw_path = raw_dir / f"raw_{prop_id}_{variant:02d}.png"
        cell.save(raw_path)

        bbox = alpha_bbox(cell)
        if bbox is None:
            continue

        x0, y0, x1, y1 = bbox
        x0 = max(0, x0 - PAD)
        y0 = max(0, y0 - PAD)
        x1 = min(cell.width, x1 + PAD)
        y1 = min(cell.height, y1 + PAD)

        sprite = cell.crop((x0, y0, x1, y1))
        out_path = OUT_DIR / f"{prop_id}_{variant:02d}.png"
        sprite.save(out_path)

        # Default alias: first frame is the stable/base asset.
        if variant == 1:
            alias_path = OUT_DIR / f"{prop_id}.png"
            sprite.save(alias_path)

        exports.append({
            "file": out_path.name,
            "alias": f"{prop_id}.png" if variant == 1 else "",
            "prop_id": prop_id,
            "variant": variant,
            "source_cell": [left, top, right, bottom],
            "size": [sprite.width, sprite.height],
        })

# Contact sheet.
thumb_w = 250
thumb_h = 210
sheet = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (18, 18, 18, 255))
draw = ImageDraw.Draw(sheet)

for item in exports:
    sprite = Image.open(OUT_DIR / item["file"]).convert("RGBA")
    sprite.thumbnail((thumb_w - 24, thumb_h - 52), Image.Resampling.NEAREST)

    col = item["variant"] - 1
    row = row_names.index(item["prop_id"])

    cell_x = col * thumb_w
    cell_y = row * thumb_h

    px = cell_x + (thumb_w - sprite.width) // 2
    py = cell_y + 36 + (thumb_h - 58 - sprite.height) // 2

    sheet.alpha_composite(sprite, (px, py))

    label = f'{item["prop_id"]}_{item["variant"]:02d} {item["size"][0]}x{item["size"][1]}'
    draw.text((cell_x + 8, cell_y + 8), label, fill=(255, 230, 180, 255))
    draw.rectangle(
        (cell_x + 1, cell_y + 1, cell_x + thumb_w - 2, cell_y + thumb_h - 2),
        outline=(120, 80, 50, 255)
    )

sheet.save(OUT_DIR / "_special_rooms_contact_sheet.png")

manifest = {
    "source": str(source),
    "layout": "5 rows x 4 columns",
    "rows": {
        "1": "forge",
        "2": "fountain",
        "3": "shrine",
        "4": "shop",
        "5": "reward/chest",
    },
    "columns": {
        "1": "base/default",
        "2": "variant/frame 2",
        "3": "variant/frame 3",
        "4": "variant/frame 4",
    },
    "exports": exports,
}

(OUT_DIR / "_manifest.json").write_text(json.dumps(manifest, indent=2))

print(f"Sliced {len(exports)} prop sprites into {OUT_DIR}")
print(f"Open contact sheet: {OUT_DIR / '_special_rooms_contact_sheet.png'}")
