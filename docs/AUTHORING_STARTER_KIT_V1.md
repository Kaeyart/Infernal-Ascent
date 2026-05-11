# Authoring Starter Kit V1

This patch gives you visible starter scenes so you are not staring at only markers.

## Added scenes

```text
scenes/rooms/circle0/reward_fountain_01.tscn
scenes/rooms/circle0/combat_ash_intake_hall_01.tscn
scenes/rooms/circle0/Circle0_ArtPalette.tscn
```

## What to open first

Open:

```text
scenes/rooms/circle0/reward_fountain_01.tscn
```

You should now see:

```text
floor
walls
fountain
props
collision bodies
markers
```

## How to edit the room

Move visual objects under:

```text
Art/Floor
Art/Walls
Art/Props
```

Move gameplay markers under:

```text
Markers
```

Move / resize collision under:

```text
Collision
```

## What you can safely move

Safe to move:

```text
Sprite2D art pieces
PlayerSpawn
RewardSocket
DoorSockets
EnemySpawns
Collision StaticBody2D nodes
```

Be careful moving:

```text
FountainBlocker_EDIT_IF_YOU_MOVE_FOUNTAIN
```

If you move the main fountain sprite, move this collision node with it.

## Art palette workflow

Open:

```text
scenes/rooms/circle0/Circle0_ArtPalette.tscn
```

Copy useful sprites, then paste them into your room under:

```text
Art/Props
```

This is faster than digging through the FileSystem every time.

## Collision rule

Only collision big things:

```text
walls
big fountain base
large pillars
gates
large slabs
```

Do not collision:

```text
small candles
banners
floor symbols
small rubble
trim
```

## Why there is no TileMap yet

This is a beginner-safe authored-room workflow. It uses Sprite2D pieces and simple collision rectangles. A proper TileMap system can come later when the room pipeline is stable.
