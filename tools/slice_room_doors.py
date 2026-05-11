from pathlib import Path
from PIL import Image
import shutil

SOURCE = Path("/home/kaey/Desktop/Assets/Room_Doors.png")
OUT_DIR = Path("art/props/room_doors")
OUT_DIR.mkdir(parents=True, exist_ok=True)

if not SOURCE.exists():
    raise SystemExit(f"Missing source file: {SOURCE}")

img = Image.open(SOURCE).convert("RGBA")
w, h = img.size
pixels = img.load()

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 0 and g > 150 and r < 130 and b < 130:
            pixels[x, y] = (r, g, b, 0)

cols = 3
rows = 4
orientations = ["north", "east", "west"]
cell_w = w // cols
cell_h = h // rows

def alpha_bbox(image):
    return image.getchannel("A").getbbox()

for row in range(rows):
    tier = row + 1

    for col in range(cols):
        orientation = orientations[col]
        left = col * cell_w
        top = row * cell_h
        right = w if col == cols - 1 else (col + 1) * cell_w
        bottom = h if row == rows - 1 else (row + 1) * cell_h

        crop = img.crop((left, top, right, bottom))
        bbox = alpha_bbox(crop)

        if bbox is None:
            continue

        pad = 8
        x0, y0, x1, y1 = bbox
        x0 = max(0, x0 - pad)
        y0 = max(0, y0 - pad)
        x1 = min(crop.width, x1 + pad)
        y1 = min(crop.height, y1 + pad)

        sprite = crop.crop((x0, y0, x1, y1))
        out = OUT_DIR / f"circle_{tier:02d}_{orientation}.png"
        sprite.save(out)
        print(out)

    north = OUT_DIR / f"circle_{tier:02d}_north.png"
    south = OUT_DIR / f"circle_{tier:02d}_south.png"
    if north.exists():
        shutil.copyfile(north, south)

print("Done slicing room doors.")
