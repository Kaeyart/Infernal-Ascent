from pathlib import Path
from PIL import Image, ImageDraw
import json

PROJECT_ROOT = Path("/home/kaey/Downloads/infernal_ascent_godot_scaffold")
ASSET_DIR = Path("/home/kaey/Desktop/Assets")
OUT_DIR = PROJECT_ROOT / "art" / "actors" / "player" / "penitent"

SOURCE_NAME = "Penitent_Idle"

# Sheet layout:
# row 1 = down/front
# row 2 = left
# row 3 = right
# row 4 = up/back
ROWS = ["down", "left", "right", "up"]

GRID_ROWS = 4
GRID_COLS = 4

GREEN_THRESHOLD = 145
RED_MAX = 145
BLUE_MAX = 145


def find_source() -> Path:
    candidates = [
        ASSET_DIR / f"{SOURCE_NAME}.png",
        ASSET_DIR / f"{SOURCE_NAME}.PNG",
        ASSET_DIR / SOURCE_NAME,
    ]

    for candidate in candidates:
        if candidate.is_file():
            return candidate

        if candidate.is_dir():
            pngs = []
            for p in list(candidate.glob("*.png")) + list(candidate.glob("*.PNG")):
                lower = p.name.lower()
                if "contact" in lower or "raw" in lower or lower.startswith("_"):
                    continue
                pngs.append(p)

            if pngs:
                return max(pngs, key=lambda p: p.stat().st_size)

    raise SystemExit(f"Could not find {SOURCE_NAME} in {ASSET_DIR}")


def remove_green(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]

            if a > 0 and g >= GREEN_THRESHOLD and r <= RED_MAX and b <= BLUE_MAX:
                pixels[x, y] = (r, g, b, 0)

    return img


def make_contact_sheet(exports: list[dict]) -> None:
    thumb_w = 230
    thumb_h = 210
    cols = 4
    rows = 4

    sheet = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)

    for item in exports:
        img = Image.open(OUT_DIR / item["file"]).convert("RGBA")
        img.thumbnail((thumb_w - 20, thumb_h - 44), Image.Resampling.NEAREST)

        col = item["frame"] - 1
        row = ROWS.index(item["direction"])

        x = col * thumb_w
        y = row * thumb_h

        px = x + (thumb_w - img.width) // 2
        py = y + 30 + (thumb_h - 46 - img.height) // 2

        sheet.alpha_composite(img, (px, py))
        draw.rectangle((x + 1, y + 1, x + thumb_w - 2, y + thumb_h - 2), outline=(150, 90, 45, 255), width=1)
        draw.text((x + 6, y + 6), f"idle/{item['direction']}/{item['frame']:02d}", fill=(235, 215, 180, 255))

    out = OUT_DIR / "_contact_sheet_idle_only.png"
    sheet.save(out)
    print(f"Contact sheet saved: {out}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source = find_source()
    print(f"Using source: {source}")

    img = remove_green(Image.open(source).convert("RGBA"))

    w, h = img.size
    cell_w = w / GRID_COLS
    cell_h = h / GRID_ROWS

    # Delete only old idle frames.
    for old in OUT_DIR.glob("idle_*.png"):
        old.unlink()

    exports = []

    for row in range(GRID_ROWS):
        direction = ROWS[row]

        for col in range(GRID_COLS):
            frame = col + 1

            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)

            cell = img.crop((left, top, right, bottom))

            out_name = f"idle_{direction}_{frame:02d}.png"
            out_path = OUT_DIR / out_name
            cell.save(out_path)

            exports.append({
                "direction": direction,
                "frame": frame,
                "file": out_name,
                "source_cell": [left, top, right, bottom],
                "size": [cell.width, cell.height],
            })

            print(f"saved {out_name} {cell.width}x{cell.height}")

    manifest = {
        "source": str(source),
        "layout": "4 rows x 4 columns",
        "rows": ROWS,
        "method": "full-cell idle-only slicing",
        "exports": exports,
    }

    (OUT_DIR / "_manifest_idle_only.json").write_text(json.dumps(manifest, indent=2))
    make_contact_sheet(exports)

    print(f"Done. Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
