# Iso Enemy Marker Filter V1

Fixes test enemies spawning on the enemy container Node2D itself.

## Problem

The runtime adapter was scanning every Node2D under `Markers` whose name contained `enemy`.

That meant a container like:

```text
Markers
  EnemySpawns
    Enemy01
    Enemy02
```

could be treated as a spawn socket too.

## Fix

The adapter now:

- prefers an enemy marker container such as `EnemySpawns`
- spawns only from the direct children of that container
- ignores container nodes such as `EnemySpawns`, `Enemies`, `EnemyMarkers`
- ignores any enemy-named node that has children
- uses only leaf Node2D marker sockets

## Expected scene structure

```text
Markers
  PlayerSpawn
  RewardSocket
  DoorSocket_Left
  DoorSocket_Center
  DoorSocket_Right
  EnemySpawns
    Enemy01
    Enemy02
    Enemy03
```

## File changed

- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`
