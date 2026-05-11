# Iso Real Combat Integration V1

This patch adds temporary real room-clear combat to authored isometric rooms.

It is still test combat, not final enemy AI.

## Added / changed files

- `scripts/iso/IsoTestEnemy.gd`
- `scripts/iso/IsoTestPlayer.gd`
- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`

## What it does

If your authored room has the `RuntimeAdapter` node with:

`res://scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`

then on F6 it now:

1. Finds enemy markers under `Markers`.
2. Spawns simple test enemies at those markers.
3. Lets `IsoTestPlayer` attack with Space or left mouse.
4. Kills enemies after enough hits.
5. Calls `PatronFlow.report_room_cleared()` when all test enemies die.
6. Patron altar appears automatically.
7. Debug `C` clear still works as fallback.

## Controls

- WASD / arrows = move
- Space / left mouse = attack nearby enemies
- E = interact with altar/gate
- C = debug clear room
- R = reset patron run

## What counts as an enemy marker

Any Node2D marker under `Markers` whose name contains `enemy`.

Examples:

- `Enemy01`
- `Enemy_01`
- `EnemySpawn01`
- `EnemySpawn_01`

## Inspector options on RuntimeAdapter

- `auto_spawn_test_enemies`
- `test_enemy_health`
- `test_enemy_movement_enabled`
- `clear_room_when_test_enemies_dead`

Keep movement disabled at first.
