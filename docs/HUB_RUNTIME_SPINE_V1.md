# Hub Runtime Spine V1

This patch connects the current hub and the current active run room into a complete temporary spine.

## Target scenes

Main hub:

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

Active run room:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

## Behavior

Hub:
1. Player starts in the hub.
2. Walk to Hell Gate.
3. Press E.
4. Load Ash Intake Hall.

Run room:
1. Clear enemies.
2. Claim boon.
3. Choose gate.
4. Repeat local room cycles.
5. When the test run is complete, HUD says:
   `Run complete. Press E to return to Hub.`
6. Press E to load the hub again.

## Controls

Hub:
- WASD / arrows = move
- E = interact

Run room:
- WASD / arrows = move
- Space / left mouse = attack
- E = interact / claim / choose gate / return to hub after completion
- T = restart local test run

## Files changed

- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`

## Acceptance test

1. Play Project.
2. Confirm hub opens.
3. Walk to Hell Gate.
4. Press E.
5. Confirm Ash Intake Hall opens.
6. Complete the room-loop test.
7. At run completion, press E.
8. Confirm hub opens again.
