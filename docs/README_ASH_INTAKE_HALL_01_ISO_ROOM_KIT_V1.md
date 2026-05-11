# Ash Intake Hall 01 — Isometric Room Kit V1

This package contains the cleaned isometric asset sheet sliced into individual PNG assets for Infernal Ascent V2.

## Install
Extract this zip at the root of your Godot project:

```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2 || exit 1
unzip -o /home/kaey/Downloads/ash_intake_hall_01_iso_room_kit_v1_project_dropin.zip
```

## Main folders

- `art/iso/circle0/ash_intake_hall_01/source/` — original cleaned source sheet.
- `art/iso/circle0/ash_intake_hall_01/sliced_trimmed/` — tight trimmed PNGs for manual placement.
- `art/iso/circle0/ash_intake_hall_01/sliced_padded_32/` — transparent padded PNGs with dimensions rounded to 32px multiples. These are easier to align and use with Y-sorting.
- `art/iso/circle0/ash_intake_hall_01/tiles_scaled_64x32_preview/` — optional resized floor tile previews. These are technical experiments only; inspect before using as final TileSet tiles.
- `art/iso/circle0/ash_intake_hall_01/contact_sheets/` — visual previews of all slices.

## Recommended usage

Use `sliced_padded_32/` for Godot placement first. It keeps the asset canvases more predictable.

Use `sliced_trimmed/` when you want tighter manual placement.

For floors, start with the 5 floor tile assets:

- `tile_floor_plain_01`
- `tile_floor_cracked_01`
- `tile_floor_sigil_judgment_01`
- `tile_floor_grate_ash_vent_01`
- `tile_floor_border_lane_01`

For props/walls, use Sprite2D scenes first instead of forcing everything into a TileSet.

Suggested scene structure:

```text
IsoRoomRoot
  L0_Background
  L1_IsoFloor
  L2_IsoWalls
  L3_YSorted
  L4_Foreground
  Collision
  Markers
```

Place walk-around props such as the lectern, brazier, statue, urns, and chain barrier in `L3_YSorted`.

## Notes

The generated sheet is clean and usable, but it is not a mathematically perfect 64x32 tile atlas. Treat the floor tiles as source sprites first. If you want a strict TileSet later, rebuild a clean 64x32 tile sheet from the approved floor pieces.
