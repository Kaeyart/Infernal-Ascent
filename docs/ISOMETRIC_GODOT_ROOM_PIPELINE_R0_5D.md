# R0.5D — Godot-Native Isometric Room Pipeline

This pass changes the room pipeline direction from custom polygon drawing to a Godot-native isometric room structure.

## Why this exists

The previous R0.5C loader was useful for visualizing room specs, but it still drew most of the room manually. That is not the correct long-term Godot workflow.

The correct production direction is:

```text
TileSet + TileMapLayer for floor/layout/collision/navigation
Node2D y-sort world layer for props/actors/interactables
Room specs exported into tile cells + sockets
Validation before Godot integration
```

Godot 4's TileMapLayer is the current node for 2D tile-based maps. It uses a TileSet, and several TileMapLayer nodes can replace the older multi-layer TileMap workflow. Godot's TileSet supports isometric tile shape and collision/navigation/occlusion layers.

## What this pass adds

```text
scripts/iso/room_pipeline/IsoGodotTileRoomLoader.gd
scenes/iso/rooms/circle0/godot_tilemap_room_loader_test.tscn
tools/room_pipeline/iso_godot_room_tool.py
art/iso/room_kits/circle0/debug_tiles/circle0_iso_debug_tiles.png
data/rooms/circle0/tilemap/*.tilemap.runtime.json
```

## Test scene

Open:

```text
res://scenes/iso/rooms/circle0/godot_tilemap_room_loader_test.tscn
```

Play Scene, not Play Project.

Controls:

```text
1–6 = switch generated rooms
R = reload current room JSON
H = toggle help text
L = toggle labels
M = toggle socket markers
```

## What this proves

This test scene proves that generated room data can be shown through Godot's actual TileMapLayer system, not only through manual draw calls.

It also introduces the correct layer split:

```text
FloorTileMapLayer
HazardTileMapLayer
GateTileMapLayer
YSortedWorldObjects
OptionalDebugLabels
```

## What this still does not do

```text
It does not replace the active run room.
It does not spawn real enemies.
It does not add final tiles/art.
It does not add final collision/navigation yet.
It does not use room art assets beyond debug tiles.
```

## Next step

After this test is accepted:

```text
R0.5E — TileMap Room Runtime Integration
```

That pass should make one generated TileMapLayer room playable with the player, real enemies, hazards, gates, and collision.
