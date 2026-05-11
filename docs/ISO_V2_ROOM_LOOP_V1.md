# Iso V2 Room Loop V1

This patch turns the working authored-room combat/patron test into a repeatable micro-run loop.

## Added / changed

- `scripts/iso/IsoRunLoopController.gd`
- `scripts/iso/IsoPatronFlowController.gd`
- `scenes/iso/tests/iso_v2_room_loop_test.tscn`

## Open this test scene

`res://scenes/iso/tests/iso_v2_room_loop_test.tscn`

Run current scene with F6.

## What it does

The loop reuses the current active authored room:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

Flow:

1. Loads Ash Intake Hall 01.
2. RuntimeAdapter spawns player/enemies from the room markers.
3. Kill enemies.
4. Patron altar appears automatically.
5. Claim boon.
6. Physical gates appear.
7. Choose a gate.
8. The next room loads.
9. Patron state persists across rooms.
10. After the second patron is chosen, the run locks to that pair.
11. The loop repeats for 5 completed rooms.
12. Press `T` to restart the test loop.

## Controls

- WASD / arrows = move
- Space / left mouse = attack
- E = interact / claim boon / choose gate
- C = debug clear fallback
- R = reset patron manager from current room flow
- T = restart the whole room loop

## Important

This is still a test loop. It reuses the same room repeatedly so we can prove the roguelite spine before adding more rooms.

Once this works, add more room scene paths to `room_scene_paths`.
