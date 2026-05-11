from pathlib import Path
from PIL import Image, ImageDraw
import shutil
import json

SOURCE = Path("/home/kaey/Desktop/Assets/Room_Doors.png")
OUT_DIR = Path("art/props/room_doors")
OUT_DIR.mkdir(parents=True, exist_ok=True)

if not SOURCE.exists():
    raise SystemExit(f"Missing source file: {SOURCE}")

img = Image.open(SOURCE).convert("RGBA")
w, h = img.size
pixels = img.load()

# Remove leftover chroma green if it exists.
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 0 and g > 150 and r < 130 and b < 130:
            pixels[x, y] = (r, g, b, 0)

rows = 3
cols = 5

orientations = ["north", "east", "west"]

cell_w = w / cols
cell_h = h / rows

exports = []
PAD = 36

def alpha_bbox(image):
    return image.getchannel("A").getbbox()

for row in range(rows):
    orientation = orientations[row]

    for col in range(cols):
        tier = col + 1

        left = round(col * cell_w)
        top = round(row * cell_h)
        right = round((col + 1) * cell_w)
        bottom = round((row + 1) * cell_h)

        cell = img.crop((left, top, right, bottom))

        # Save raw cell too, so we can recover if trim is bad.
        raw_path = OUT_DIR / f"_raw_circle_{tier:02d}_{orientation}.png"
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

        out_path = OUT_DIR / f"circle_{tier:02d}_{orientation}.png"
        sprite.save(out_path)

        exports.append({
            "file": out_path.name,
            "tier": tier,
            "orientation": orientation,
            "source_cell": [left, top, right, bottom],
            "size": [sprite.width, sprite.height]
        })

# South fallback: use north/front-facing door until we generate real south doors.
for tier in range(1, cols + 1):
    north = OUT_DIR / f"circle_{tier:02d}_north.png"
    south = OUT_DIR / f"circle_{tier:02d}_south.png"
    if north.exists():
        shutil.copyfile(north, south)

# Contact sheet.
thumb_w = 260
thumb_h = 220
sheet = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (18, 18, 18, 255))
draw = ImageDraw.Draw(sheet)

for item in exports:
    sprite = Image.open(OUT_DIR / item["file"]).convert("RGBA")
    sprite.thumbnail((thumb_w - 24, thumb_h - 48), Image.Resampling.NEAREST)

    col = item["tier"] - 1
    row = orientations.index(item["orientation"])

    cell_x = col * thumb_w
    cell_y = row * thumb_h

    px = cell_x + (thumb_w - sprite.width) // 2
    py = cell_y + 34 + (thumb_h - 54 - sprite.height) // 2

    sheet.alpha_composite(sprite, (px, py))

    label = f'{item["file"]} {item["size"][0]}x{item["size"][1]}'
    draw.text((cell_x + 8, cell_y + 8), label, fill=(255, 230, 180, 255))
    draw.rectangle(
        (cell_x + 1, cell_y + 1, cell_x + thumb_w - 2, cell_y + thumb_h - 2),
        outline=(120, 80, 50, 255)
    )

sheet.save(OUT_DIR / "_contact_sheet_correct.png")

manifest = {
    "source": str(SOURCE),
    "layout": "3 rows x 5 columns",
    "rows": {
        "1": "north/top-wall/front-facing-down",
        "2": "east/right-wall",
        "3": "west/left-wall"
    },
    "columns": {
        "1": "circle/tier 1",
        "2": "circle/tier 2",
        "3": "circle/tier 3",
        "4": "circle/tier 4",
        "5": "circle/tier 5"
    },
    "exports": exports
}

(OUT_DIR / "_manifest_correct.json").write_text(json.dumps(manifest, indent=2))

print(f"Sliced {len(exports)} room doors into {OUT_DIR}")
print(f"Open this to inspect: {OUT_DIR / '_contact_sheet_correct.png'}")
