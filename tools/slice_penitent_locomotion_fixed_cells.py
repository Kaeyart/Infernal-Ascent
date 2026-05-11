from pathlib import Path
from PIL import Image, ImageDraw
import json

PROJECT_ROOT = Path("/home/kaey/Downloads/infernal_ascent_godot_scaffold")
ASSET_DIR = Path("/home/kaey/Desktop/Assets")
OUTPUT_DIR = PROJECT_ROOT / "art" / "actors" / "player" / "penitent"

SHEETS = {
    "idle": "Penitent_Idle",
    "run": "Penitent_Run",
    "dash": "Penitent_Dash",
}

# Your corrected row order.
# Change to ["down", "right", "left", "up"] only if left/right are wrong.
ROW_NAMES = ["down", "left", "right", "up"]

GRID_ROWS = 4
GRID_COLS = 4

GREEN_THRESHOLD = 145
RED_MAX = 145
BLUE_MAX = 145


def find_source(name: str) -> Path:
    candidates = [
        ASSET_DIR / f"{name}.png",
        ASSET_DIR / f"{name}.PNG",
        ASSET_DIR / name,
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

    raise SystemExit(
        f"Missing source for {name}. Expected {ASSET_DIR / (name + '.png')} "
        f"or folder {ASSET_DIR / name}"
    )


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


def slice_full_cells(state: str, source_path: Path) -> list[dict]:
    img = remove_green(Image.open(source_path).convert("RGBA"))

    w, h = img.size
    cell_w = w / GRID_COLS
    cell_h = h / GRID_ROWS

    exports = []

    for row in range(GRID_ROWS):
        direction = ROW_NAMES[row]

        for col in range(GRID_COLS):
            frame = col + 1

            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)

            cell = img.crop((left, top, right, bottom))

            out_name = f"{state}_{direction}_{frame:02d}.png"
            out_path = OUTPUT_DIR / out_name
            cell.save(out_path)

            exports.append({
                "state": state,
                "direction": direction,
                "frame": frame,
                "file": out_name,
                "source": str(source_path),
                "source_cell": [left, top, right, bottom],
                "size": [cell.width, cell.height],
            })

            print(f"saved {out_name} {cell.width}x{cell.height}")

    return exports


def make_contact_sheet(exports: list[dict]) -> None:
    states = ["idle", "run", "dash"]
    directions = ROW_NAMES
    frames = [1, 2, 3, 4]

    thumb_w = 210
    thumb_h = 190

    rows = len(states) * len(directions)
    cols = len(frames)

    sheet = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)

    export_map = {
        (e["state"], e["direction"], e["frame"]): e
        for e in exports
    }

    y_row = 0

    for state in states:
        for direction in directions:
            for frame in frames:
                x = (frame - 1) * thumb_w
                y = y_row * thumb_h

                draw.rectangle(
                    (x + 1, y + 1, x + thumb_w - 2, y + thumb_h - 2),
                    outline=(150, 90, 45, 255),
                    width=1
                )

                item = export_map.get((state, direction, frame))
                label = f"{state}/{direction}/{frame:02d}"

                if item is None:
                    draw.text((x + 6, y + 6), label + " MISSING", fill=(255, 80, 80, 255))
                    continue

                img = Image.open(OUTPUT_DIR / item["file"]).convert("RGBA")
                img.thumbnail((thumb_w - 20, thumb_h - 42), Image.Resampling.NEAREST)

                px = x + (thumb_w - img.width) // 2
                py = y + 28 + (thumb_h - 44 - img.height) // 2

                sheet.alpha_composite(img, (px, py))
                draw.text((x + 6, y + 6), f"{label} {item['size'][0]}x{item['size'][1]}", fill=(235, 215, 180, 255))

            y_row += 1

    out = OUTPUT_DIR / "_contact_sheet_fixed_cells.png"
    sheet.save(out)
    print(f"\nContact sheet saved: {out}")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    all_exports = []

    for state, sheet_name in SHEETS.items():
        source = find_source(sheet_name)
        print(f"\nProcessing {state}: {source}")
        all_exports.extend(slice_full_cells(state, source))

    manifest = {
        "layout": "4 rows x 4 columns",
        "row_order": ROW_NAMES,
        "method": "fixed full-cell slicing, no alpha trimming",
        "exports": all_exports,
    }

    (OUTPUT_DIR / "_manifest_fixed_cells.json").write_text(json.dumps(manifest, indent=2))
    make_contact_sheet(all_exports)

    print(f"\nDone. Output folder: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
