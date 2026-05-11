#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
from collections import deque
import json
import math

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

# Chroma key tolerance.
GREEN_THRESHOLD = 135
RED_MAX = 170
BLUE_MAX = 170

# Alpha/component cleanup.
ALPHA_THRESHOLD = 8
MIN_COMPONENT_AREA = 80
KEEP_NEAR_MAIN_DISTANCE = 38

# Output frame canvas.
PADDING_X = 26
PADDING_TOP = 22
FOOT_PADDING = 18


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

    raise SystemExit(f"Could not find {SOURCE_NAME}. Expected {ASSET_DIR / (SOURCE_NAME + '.png')} or folder {ASSET_DIR / SOURCE_NAME}")


def remove_green(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]

            # Kills bright green background and green halo leftovers.
            if a > 0 and g >= GREEN_THRESHOLD and r <= RED_MAX and b <= BLUE_MAX:
                pixels[x, y] = (r, g, b, 0)

    return img


def build_alpha_mask(img: Image.Image):
    alpha = img.getchannel("A")
    w, h = img.size
    pix = alpha.load()
    return [[pix[x, y] > ALPHA_THRESHOLD for x in range(w)] for y in range(h)]


def bbox_distance(a, b) -> float:
    # Distance between two rectangles. 0 when touching/overlapping.
    ax0, ay0, ax1, ay1 = a
    bx0, by0, bx1, by1 = b

    dx = max(bx0 - ax1, ax0 - bx1, 0)
    dy = max(by0 - ay1, ay0 - by1, 0)

    return math.sqrt(dx * dx + dy * dy)


def component_filter(cell: Image.Image) -> Image.Image:
    # Removes isolated fragments from neighboring cells while keeping the main sprite.
    cell = cell.convert("RGBA")
    w, h = cell.size
    mask = build_alpha_mask(cell)
    visited = [[False for _ in range(w)] for _ in range(h)]

    components = []
    dirs = [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]

    for y in range(h):
        for x in range(w):
            if visited[y][x] or not mask[y][x]:
                continue

            q = deque([(x, y)])
            visited[y][x] = True
            pixels = []
            min_x = max_x = x
            min_y = max_y = y

            while q:
                cx, cy = q.popleft()
                pixels.append((cx, cy))

                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)

                for dx, dy in dirs:
                    nx = cx + dx
                    ny = cy + dy

                    if nx < 0 or nx >= w or ny < 0 or ny >= h:
                        continue

                    if visited[ny][nx] or not mask[ny][nx]:
                        continue

                    visited[ny][nx] = True
                    q.append((nx, ny))

            components.append({
                "pixels": pixels,
                "area": len(pixels),
                "bbox": (min_x, min_y, max_x + 1, max_y + 1),
            })

    if not components:
        return cell

    components.sort(key=lambda c: c["area"], reverse=True)
    main = components[0]
    main_bbox = main["bbox"]
    main_area = main["area"]

    keep_pixels = set(main["pixels"])

    for comp in components[1:]:
        area = comp["area"]

        if area < MIN_COMPONENT_AREA:
            continue

        dist = bbox_distance(main_bbox, comp["bbox"])

        # Keep legit nearby detached bits such as sword glints, cape holes, or halo tips.
        # Remove far edge garbage from neighboring cells.
        if dist <= KEEP_NEAR_MAIN_DISTANCE and area >= main_area * 0.015:
            keep_pixels.update(comp["pixels"])

    cleaned = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = cell.load()
    dst = cleaned.load()

    for x, y in keep_pixels:
        dst[x, y] = src[x, y]

    return cleaned


def alpha_bbox(img: Image.Image):
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
    return mask.getbbox()


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

    out = OUT_DIR / "_contact_sheet_idle_clean.png"
    sheet.save(out)
    print(f"Contact sheet saved: {out}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source = find_source()
    print(f"Using source: {source}")

    sheet = remove_green(Image.open(source).convert("RGBA"))
    w, h = sheet.size

    cell_w = w / GRID_COLS
    cell_h = h / GRID_ROWS

    entries = []

    debug_raw = OUT_DIR / "_debug_raw_idle_cells"
    debug_raw.mkdir(parents=True, exist_ok=True)

    for row in range(GRID_ROWS):
        direction = ROWS[row]

        for col in range(GRID_COLS):
            frame = col + 1

            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)

            cell = sheet.crop((left, top, right, bottom))
            cell.save(debug_raw / f"raw_{direction}_{frame:02d}.png")

            cleaned = component_filter(cell)
            bbox = alpha_bbox(cleaned)

            if bbox is None:
                continue

            cropped = cleaned.crop(bbox)

            entries.append({
                "direction": direction,
                "frame": frame,
                "cropped": cropped,
                "source_cell": [left, top, right, bottom],
                "bbox": bbox,
            })

    if not entries:
        raise SystemExit("No visible sprite pixels found after slicing.")

    max_w = max(e["cropped"].width for e in entries)
    max_h = max(e["cropped"].height for e in entries)

    canvas_w = max_w + PADDING_X * 2
    canvas_h = max_h + PADDING_TOP + FOOT_PADDING

    for old in OUT_DIR.glob("idle_*.png"):
        old.unlink()

    exports = []

    for entry in entries:
        cropped = entry["cropped"]
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

        # Bottom-center anchor: feet stay in place, no idle sliding.
        paste_x = (canvas_w - cropped.width) // 2
        paste_y = canvas_h - cropped.height - FOOT_PADDING

        canvas.alpha_composite(cropped, (paste_x, paste_y))

        out_name = f"idle_{entry['direction']}_{entry['frame']:02d}.png"
        out_path = OUT_DIR / out_name
        canvas.save(out_path)

        exports.append({
            "direction": entry["direction"],
            "frame": entry["frame"],
            "file": out_name,
            "source_cell": entry["source_cell"],
            "bbox": list(entry["bbox"]),
            "cropped_size": [cropped.width, cropped.height],
            "canvas_size": [canvas_w, canvas_h],
            "paste": [paste_x, paste_y],
        })

        print(f"saved {out_name} canvas={canvas_w}x{canvas_h} crop={cropped.width}x{cropped.height}")

    manifest = {
        "source": str(source),
        "layout": "4 rows x 4 columns",
        "rows": ROWS,
        "method": "grid slice, green removal, component cleanup, bottom-center anchor",
        "exports": exports,
    }

    (OUT_DIR / "_manifest_idle_clean.json").write_text(json.dumps(manifest, indent=2))
    make_contact_sheet(exports)

    print(f"Done. Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
