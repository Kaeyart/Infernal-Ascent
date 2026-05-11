# Robust Asset Slicing Tool

Use this instead of connected-component slicing.

The old slicing method looked for separated alpha blobs. That is risky for generated pixel art because horns, chains, candles, flames, glow, and detached side decorations may become separate blobs or get cropped too tightly.

This tool slices by authored grid cells first, then optionally trims transparent borders with generous padding.

## Door sheet

Your current `Room_Doors.png` uses:

- 4 rows = hell progression tiers
- 3 columns = north/east/west door orientation

Run:

```bash
cd /home/kaey/Downloads/infernal_ascent_godot_scaffold

python3 tools/smart_sprite_slicer.py \
  --source /home/kaey/Desktop/Assets/Room_Doors.png \
  --out art/props/room_doors_v2 \
  --rows 4 --cols 3 \
  --names north,east,west \
  --prefix circle \
  --kill-green \
  --trim-alpha \
  --pad 28 \
  --save-cells
```

If anything gets cut off, rerun with a bigger pad:

```bash
--pad 48
```

If it still looks wrong, use no-trim mode:

```bash
python3 tools/smart_sprite_slicer.py \
  --source /home/kaey/Desktop/Assets/Room_Doors.png \
  --out art/props/room_doors_v2_cells \
  --rows 4 --cols 3 \
  --names north,east,west \
  --prefix circle \
  --kill-green \
  --no-trim
```

## Special room prop sheet

Expected layout:

- row 1 = forge
- row 2 = fountain
- row 3 = shrine
- row 4 = shop
- row 5 = reward/chest
- 4 columns = animation/variant frames

Run:

```bash
python3 tools/smart_sprite_slicer.py \
  --source /home/kaey/Desktop/Assets/Special_Room_Props.png \
  --out art/props/special_rooms \
  --rows 5 --cols 4 \
  --row-names forge,fountain,shrine,shop,reward \
  --prefix prop \
  --kill-green \
  --trim-alpha \
  --pad 32 \
  --save-cells
```

## Review

Always open:

```text
_contact_sheet.png
```

before wiring assets into Godot.
