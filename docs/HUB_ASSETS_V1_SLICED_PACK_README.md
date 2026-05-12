# Infernal Ascent Iso Hub Assets V1 — Sliced Pack

Target scene to build next:

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

Active run-room reference:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

## Contents

This pack contains 106 auto-sliced transparent PNG assets for the first isometric hub pass.

Folders:

```text
art/iso/hub/threshold_nave_v1/source_sheets/
art/iso/hub/threshold_nave_v1/sliced_trimmed/
art/iso/hub/threshold_nave_v1/sliced_padded_32/
art/iso/hub/threshold_nave_v1/contact_sheets/
art/iso/hub/threshold_nave_v1/hub_asset_manifest.csv
art/iso/hub/threshold_nave_v1/hub_asset_manifest.json
```

Use the `sliced_padded_32` folder in Godot first. The transparent padding reduces edge clipping and makes selection easier.

## Installation

From the Godot project root:

```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2 || exit 1
unzip -o /home/kaey/Downloads/infernal_ascent_iso_hub_assets_v1_sliced.zip
```

Then let Godot import the PNGs.

## Important Notes

These are generated game-production assets, not final polished handmade tiles. Some slices may need manual cleanup, but they are usable enough for the first hub blockout/build pass.

The next build target should be:

```text
res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn
```

Recommended initial scene structure:

```text
IsoHubThresholdNaveV1
  L0_Background
  L1_IsoFloor
  L2_StructuralWalls
  L3_YSorted
  L4_Foreground
  Collision
  Markers
    PlayerSpawn
    HellGateStart
    WeaponAltarMarker
    BoonShrineMarker
    TrainingDummyMarker
    FountainMarker
  HubRuntime
```

## Suggested Build Order

1. Build floor footprint.
2. Place central seal.
3. Place Hell Gate at the back/top.
4. Place Weapon Altar left.
5. Place Boon Shrine right.
6. Place Training Dummy lower-left.
7. Place Fountain lower-right or lower-center.
8. Place PlayerSpawn.
9. Add simple `StaticBody2D + CollisionShape2D` blockers.
10. Add hub runtime interactions later.

## Asset Count by Category

- floor_structural: 17
- fx: 25
- hell_gate: 5
- misc: 3
- shared_prop: 16
- station_archive_merchant: 5
- station_boon_fountain_statue: 6
- station_fountain: 2
- station_weapon_training: 4
- wall_support: 23

Total assets: 106
