#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
import json

ASSET_ROOT = Path("/home/kaey/Desktop/Assets")
OUT_DIR = Path("art/actors/player/penitent")
OUT_DIR.mkdir(parents=True, exist_ok=True)

ROW_NAMES = ["down", "left", "right", "up"]

SHEETS = {
    "idle": "Penitent_Idle",
    "run": "Penitent_Run",
    "dash": "Penitent_Dash",
}

ROWS = 4
COLS = 4
PAD = 34

GREEN_THRESHOLD = 145
RED_MAX = 145
BLUE_MAX = 145


def find_source(name: str) -> Path:
    candidates = [
        ASSET_ROOT / f"{name}.png",
        ASSET_ROOT / f"{name}.PNG",
        ASSET_ROOT / name,
    ]

    for candidate in candidates:
        if candidate.is_file():
            return candidate

        if candidate.is_dir():
            pngs = sorted(candidate.glob("*.png")) + sorted(candidate.glob("*.PNG"))

            if pngs:
                return max(pngs, key=lambda p: p.stat().st_size)

    raise SystemExit(
        f"Missing {name}. Expected either {ASSET_ROOT / (name + '.png')} "
        f"or a folder containing a PNG at {ASSET_ROOT / name}"
    )


def kill_green(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and g >= GREEN_THRESHOLD and r <= RED_MAX and b <= BLUE_MAX:
                px[x, y] = (r, g, b, 0)

    return img


def alpha_bbox(img: Image.Image):
    return img.getchannel("A").getbbox()


def slice_sheet(state: str, source: Path) -> list[dict]:
    state_dir = OUT_DIR / state
    raw_dir = OUT_DIR / "_raw_cells" / state
    state_dir.mkdir(parents=True, exist_ok=True)
    raw_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(source).convert("RGBA")
    img = kill_green(img)

    w, h = img.size
    cell_w = w / COLS
    cell_h = h / ROWS

    exports = []

    for row in range(ROWS):
        direction = ROW_NAMES[row]

        for col in range(COLS):
            frame = col + 1

            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)

            cell = img.crop((left, top, right, bottom))
            raw_path = raw_dir / f"raw_{state}_{direction}_{frame:02d}.png"
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

            out_path = state_dir / f"{state}_{direction}_{frame:02d}.png"
            sprite.save(out_path)

            flat_path = OUT_DIR / f"{state}_{direction}_{frame:02d}.png"
            sprite.save(flat_path)

            exports.append({
                "state": state,
                "direction": direction,
                "frame": frame,
                "file": str(out_path),
                "flat_file": str(flat_path),
                "source_cell": [left, top, right, bottom],
                "size": [sprite.width, sprite.height],
            })

    return exports


def make_contact_sheet(exports: list[dict], out_path: Path) -> None:
    if not exports:
        return

    states = ["idle", "run", "dash"]
    directions = ROW_NAMES
    thumb_w = 210
    thumb_h = 190

    sheet_w = COLS * thumb_w
    sheet_h = len(states) * len(directions) * thumb_h

    sheet = Image.new("RGBA", (sheet_w, sheet_h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)

    lookup = {}
    for item in exports:
        lookup[(item["state"], item["direction"], item["frame"])] = item

    y_row = 0

    for state in states:
        for direction in directions:
            for frame in range(1, COLS + 1):
                item = lookup.get((state, direction, frame))
                cell_x = (frame - 1) * thumb_w
                cell_y = y_row * thumb_h

                draw.rectangle(
                    (cell_x + 1, cell_y + 1, cell_x + thumb_w - 2, cell_y + thumb_h - 2),
                    outline=(120, 80, 50, 255),
                )

                label = f"{state}/{direction}/{frame:02d}"

                if item is None:
                    draw.text((cell_x + 8, cell_y + 8), label + " MISSING", fill=(255, 80, 80, 255))
                    continue

                sprite = Image.open(item["file"]).convert("RGBA")
                sprite.thumbnail((thumb_w - 24, thumb_h - 46), Image.Resampling.NEAREST)

                px = cell_x + (thumb_w - sprite.width) // 2
                py = cell_y + 32 + (thumb_h - 50 - sprite.height) // 2

                sheet.alpha_composite(sprite, (px, py))
                draw.text((cell_x + 8, cell_y + 8), f"{label} {item['size'][0]}x{item['size'][1]}", fill=(255, 230, 180, 255))

            y_row += 1

    sheet.save(out_path)


def main() -> None:
    all_exports = []
    manifest = {
        "source_root": str(ASSET_ROOT),
        "output": str(OUT_DIR),
        "layout": "4 rows x 4 columns",
        "row_order": ROW_NAMES,
        "columns": "animation frames 1-4",
        "sheets": {},
        "exports": [],
    }

    for state, source_name in SHEETS.items():
        source = find_source(source_name)
        print(f"Slicing {state}: {source}")

        exports = slice_sheet(state, source)
        all_exports.extend(exports)

        manifest["sheets"][state] = str(source)
        manifest["exports"].extend(exports)

    (OUT_DIR / "_manifest.json").write_text(json.dumps(manifest, indent=2))
    make_contact_sheet(all_exports, OUT_DIR / "_contact_sheet.png")

    print(f"\nSliced {len(all_exports)} player sprites into {OUT_DIR}")
    print(f"Open contact sheet: {OUT_DIR / '_contact_sheet.png'}")
    print("If left/right face the wrong way, edit ROW_NAMES in this script and rerun.")


if __name__ == "__main__":
    main()
