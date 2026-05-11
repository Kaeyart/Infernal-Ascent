# Infernal Ascent — Isometric V2 Foundation

This patch starts the isometric V2 pivot without deleting the working V1 logic.

It does **not** replace the whole game yet. It creates the clean isometric room-authoring foundation so we can build one proper test room first: **Ash Intake Hall 01**.

## Added folders

```text
scripts/iso/
scenes/iso/rooms/templates/
scenes/iso/rooms/circle0/
art/iso/circle0/ash_intake_hall_01/
docs/
```

## Added scripts

```text
scripts/iso/IsoRoomTemplate.gd
scripts/iso/IsoGridGuide.gd
scripts/iso/IsoMarker.gd
scripts/iso/IsoRoomLoader.gd
scripts/iso/IsoYSortGroup.gd
```

## Added scenes

```text
scenes/iso/rooms/templates/IsoRoomTemplate.tscn
scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn
```

Open this first:

```text
res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn
```

You should see a drawn isometric guide room: diamond floor, rear wall, side returns, front edge, collision nodes, and visible markers.

## Locked V2 art standard

```text
Projection: true 2D isometric
Base floor tile: 64x32 diamond
Wall height: 32px / 64px increments
Room building: authored scenes, not generated draw-code rooms
Gameplay: still Godot 2D
Collision: simple invisible rectangles/polygons
Sorting: Y-sort for player/enemies/walk-around props
```

## Scene layer structure

Every iso room should use:

```text
IsoRoomRoot
  L0_Background
  L1_IsoFloor
  L2_IsoWalls
  L3_YSorted
  L4_Foreground
  Collision
  Markers
    PlayerSpawn
    RewardSocket
    EnemySpawns
    DoorSockets
```

## What goes where

```text
L0_Background
- distant void
- furnace glow
- smoke / ash haze
- background silhouettes

L1_IsoFloor
- 64x32 diamond floor tiles
- floor grates
- floor cracks
- central seals

L2_IsoWalls
- north wall
- east/west walls
- corners
- gates
- stairs / platforms

L3_YSorted
- player
- enemies
- lecterns
- braziers
- statues
- pillars the player can walk around

L4_Foreground
- front parapet
- foreground chains
- near-camera pillars
- smoke overlays
```

## Important

This patch does not yet wire the normal run flow into the iso room. That is intentional.

First, validate that the isometric scene opens, is editable, and feels structurally sane. Once that is confirmed, the next patch wires the run loader to use the iso room for Circle 0 combat.

## Suggested next steps

1. Open `combat_ash_intake_hall_01_iso.tscn`.
2. Confirm the scene opens without corruption.
3. Inspect the layer structure.
4. Place future iso sprites under the correct layer.
5. Keep current V1 project copy untouched as backup.
6. Next patch: generate/import the real 64x32 isometric Ash Intake Hall kit.
