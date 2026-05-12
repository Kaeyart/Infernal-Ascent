# R0.5E — TileMap Room Runtime Integration Test

This pass makes the generated isometric rooms playable in a contained Godot test scene.

It does not replace the main run loop yet. It loads generated room runtime JSON, draws the TileMapLayer room, then spawns the current player, enemies, hazards, and route gates into that room.

## Scene

```text
res://scenes/iso/rooms/circle0/generated_iso_room_playable_test.tscn
```

Use **Play Scene**, not Play Project.

## Controls

```text
1–6 = switch generated rooms
R = reload current room
K = kill enemies for route-gate test
G = force route gates
M = toggle socket markers
```

## What this proves

- The room builder output can be used by Godot runtime code.
- Player spawn comes from room JSON.
- Enemy spawns come from room JSON.
- Hazard sockets come from room JSON.
- Route gate sockets come from room JSON.
- Room clear can open gates.
- Gates can load another generated room.

## What this does not do yet

- It does not replace the active Ash Intake run room.
- It does not use final art assets.
- It does not create final collision/navigation.
- It does not modify the main demo run state machine.

## Acceptance

Accept this pass only if the generated rooms are playable enough to test combat spacing and route sockets.
