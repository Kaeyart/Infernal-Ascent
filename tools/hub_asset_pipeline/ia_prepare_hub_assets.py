#!/usr/bin/env python3
"""
Infernal Ascent hub sheet cleanup + auto-slicing tool.

Usage from project root:
  python3 tools/hub_asset_pipeline/ia_prepare_hub_assets.py \
    --structural art/hub_generated/source/ia_hub_structural_sheet.png \
    --props art/hub_generated/source/ia_hub_props_sheet.png

What it does:
  - cleans almost-transparent background garbage
  - slices separate alpha islands into individual PNGs
  - organizes them into broad category folders
  - writes a JSON/CSV manifest
  - writes contact sheets so you can choose assets by filename

This does not modify scenes. It only creates image files and manifests.
"""
from PIL import Image, ImageDraw, ImageFont
import argparse, os, json, csv, math, shutil

PROJECT_ROOT = os.getcwd()
OUT_ROOT = os.path.join(PROJECT_ROOT, 'art', 'hub_generated')
SRC_DIR = os.path.join(OUT_ROOT, 'source')
SLICE_ROOT = os.path.join(OUT_ROOT, 'sliced')
CONTACT_DIR = os.path.join(OUT_ROOT, 'contact_sheets')
MANIFEST_DIR = os.path.join(OUT_ROOT, 'manifest')


def ensure_dirs():
    for d in [SRC_DIR, SLICE_ROOT, CONTACT_DIR, MANIFEST_DIR]:
        os.makedirs(d, exist_ok=True)


def clean_rgba(in_path, out_path):
    im = Image.open(in_path).convert('RGBA')
    pix = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            # Remove background-removal dust. Keep real semi-transparent pixels.
            if a < 12:
                pix[x, y] = (0, 0, 0, 0)
            else:
                pix[x, y] = (r, g, b, a)
    im.save(out_path)
    return im


def category_for(sheet_kind, x, y, w, h):
    cy = y + h * 0.5
    if sheet_kind == 'structural':
        if cy < 245:
            return 'structural/floors'
        if cy < 365:
            return 'structural/walls_corners_banners'
        if cy < 515:
            return 'structural/doors_arches_pillars'
        if cy < 625:
            return 'structural/trims_stairs_railings'
        if cy < 750:
            return 'structural/carpets_platforms'
        if cy < 880:
            return 'structural/lava_ember_channels'
        return 'structural/lights_small_props'
    else:
        if cy < 165:
            return 'props/archive_bookcases_codex'
        if cy < 295:
            return 'props/forge_smithing'
        if cy < 410:
            return 'props/training_weapons_chests'
        if cy < 520:
            return 'props/storage_furniture'
        if cy < 635:
            return 'props/banners_chains_lights'
        if cy < 760:
            return 'props/ritual_statues_pillars'
        if cy < 890:
            return 'props/doors_wall_modules'
        return 'landmarks/gates_large_doors'


def slug(cat):
    return cat.replace('/', '_')


def components_from_alpha(im, alpha_threshold=18, min_area=40):
    w, h = im.size
    alpha = im.getchannel('A')
    data = bytearray(1 if a >= alpha_threshold else 0 for a in alpha.getdata())
    seen = bytearray(w * h)
    comps = []
    for idx, val in enumerate(data):
        if not val or seen[idx]:
            continue
        q = [idx]
        seen[idx] = 1
        minx = maxx = idx % w
        miny = maxy = idx // w
        area = 0
        while q:
            i = q.pop()
            area += 1
            x = i % w
            y = i // w
            if x < minx: minx = x
            if x > maxx: maxx = x
            if y < miny: miny = y
            if y > maxy: maxy = y
            if x > 0:
                ni = i - 1
                if data[ni] and not seen[ni]:
                    seen[ni] = 1; q.append(ni)
            if x < w - 1:
                ni = i + 1
                if data[ni] and not seen[ni]:
                    seen[ni] = 1; q.append(ni)
            if y > 0:
                ni = i - w
                if data[ni] and not seen[ni]:
                    seen[ni] = 1; q.append(ni)
            if y < h - 1:
                ni = i + w
                if data[ni] and not seen[ni]:
                    seen[ni] = 1; q.append(ni)
        if area >= min_area:
            comps.append((minx, miny, maxx + 1, maxy + 1, area))
    comps.sort(key=lambda b: (b[1], b[0]))
    return comps


def slice_sheet(sheet_path, sheet_kind, source_label):
    clean_path = os.path.join(SRC_DIR, f'{source_label}_clean.png')
    im = clean_rgba(sheet_path, clean_path)
    comps = components_from_alpha(im)
    assets = []
    counters = {}
    W, H = im.size
    for x1, y1, x2, y2, area in comps:
        margin = 3
        cx1 = max(0, x1 - margin)
        cy1 = max(0, y1 - margin)
        cx2 = min(W, x2 + margin)
        cy2 = min(H, y2 + margin)
        bw = cx2 - cx1
        bh = cy2 - cy1
        if bw < 6 or bh < 6:
            continue
        cat = category_for(sheet_kind, cx1, cy1, bw, bh)
        counters[cat] = counters.get(cat, 0) + 1
        name = f'{source_label}_{slug(cat)}_{counters[cat]:03d}.png'
        out_dir = os.path.join(SLICE_ROOT, cat)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, name)
        crop = im.crop((cx1, cy1, cx2, cy2))
        crop.save(out_path)
        assets.append({
            'name': name,
            'source_label': source_label,
            'source_sheet': os.path.basename(sheet_path),
            'category': cat,
            'path': f'art/hub_generated/sliced/{cat}/{name}',
            'bbox': [cx1, cy1, cx2, cy2],
            'width': bw,
            'height': bh,
            'area_pixels': area,
        })
    return assets


def write_manifest(assets):
    with open(os.path.join(MANIFEST_DIR, 'ia_hub_assets_manifest.json'), 'w') as f:
        json.dump({'version': 1, 'assets': assets}, f, indent=2)
    with open(os.path.join(MANIFEST_DIR, 'ia_hub_assets_manifest.csv'), 'w', newline='') as f:
        fields = ['name', 'source_label', 'category', 'path', 'width', 'height', 'bbox', 'area_pixels']
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for a in assets:
            row = {k: a[k] for k in fields}
            row['bbox'] = json.dumps(row['bbox'])
            writer.writerow(row)


def contact_sheet(asset_list, title, out_path, thumb=96):
    if not asset_list:
        return
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 12)
        small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 10)
    except Exception:
        font = small = None
    cols = 5 if len(asset_list) < 40 else 6
    label_h = 34
    pad = 10
    cell_w = thumb + pad * 2
    cell_h = thumb + label_h + pad * 2
    rows = math.ceil(len(asset_list) / cols)
    header = 36
    sheet = Image.new('RGB', (cols * cell_w, header + rows * cell_h), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    d.text((10, 10), title, fill=(240, 240, 240), font=font)
    for i, a in enumerate(asset_list):
        col = i % cols
        row = i // cols
        ox = col * cell_w + pad
        oy = header + row * cell_h + pad
        img = Image.open(os.path.join(PROJECT_ROOT, a['path'])).convert('RGBA')
        d.rectangle((ox, oy, ox + thumb, oy + thumb), fill=(8, 8, 8), outline=(70, 70, 70))
        iw, ih = img.size
        scale = min(thumb / iw, thumb / ih, 1.0)
        rw = max(1, int(iw * scale))
        rh = max(1, int(ih * scale))
        resized = img.resize((rw, rh), Image.Resampling.NEAREST)
        px = ox + (thumb - rw) // 2
        py = oy + (thumb - rh) // 2
        overlay = Image.new('RGBA', sheet.size, (0, 0, 0, 0))
        overlay.alpha_composite(resized, (px, py))
        sheet = Image.alpha_composite(sheet.convert('RGBA'), overlay).convert('RGB')
        d = ImageDraw.Draw(sheet)
        short = a['name'].replace('.png', '')
        if len(short) > 28:
            short = short[:25] + '...'
        d.text((ox, oy + thumb + 4), short, fill=(230, 230, 230), font=small)
        d.text((ox, oy + thumb + 18), f"{a['width']}x{a['height']}", fill=(170, 170, 170), font=small)
    sheet.save(out_path)


def write_contact_sheets(assets):
    bycat = {}
    for a in assets:
        bycat.setdefault(a['category'], []).append(a)
    for cat, lst in bycat.items():
        contact_sheet(lst, cat, os.path.join(CONTACT_DIR, cat.replace('/', '__') + '.png'))
    contact_sheet(assets, 'Infernal Ascent Hub Assets - ALL SLICES', os.path.join(CONTACT_DIR, 'ALL_ASSETS_CONTACT_SHEET.png'), thumb=88)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--structural', required=True, help='Path to the structural tiles sheet PNG')
    parser.add_argument('--props', required=True, help='Path to the props/landmarks sheet PNG')
    args = parser.parse_args()
    ensure_dirs()
    shutil.copy2(args.structural, os.path.join(SRC_DIR, 'ia_hub_structural_sheet.png'))
    shutil.copy2(args.props, os.path.join(SRC_DIR, 'ia_hub_props_sheet.png'))
    assets = []
    assets += slice_sheet(args.structural, 'structural', 'structural')
    assets += slice_sheet(args.props, 'props', 'props')
    write_manifest(assets)
    write_contact_sheets(assets)
    print(f'Done. Sliced {len(assets)} assets.')
    print('Output folder: art/hub_generated/')
    print('Check: art/hub_generated/contact_sheets/ALL_ASSETS_CONTACT_SHEET.png')


if __name__ == '__main__':
    main()
