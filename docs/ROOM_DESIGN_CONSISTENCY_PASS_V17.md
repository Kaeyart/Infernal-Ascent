# V17 — Room Design Consistency Pass

## Goal

Make the current Circle 0 room pool feel structurally consistent and readable without adding new game systems.

This pass follows the Demo Production Bible: V17 touches room layouts, boundaries, spawn points, hazard zones, gate zones, prop density, room dressing, and camera-safe spacing. It does not touch boss work, permanent progression, reward expansion, or player art.

## Changed

- Rebuilt `IsoRoomSetDressing.gd` as a consistent runtime-drawn Circle 0 layout language.
- Added subtle readable zones for player spawn, enemy spawn pads, and gate/exits.
- Added the sixth combat room variant: `penitent_crossing`.
- Standardized fallback player spawn placement when authored markers are missing.
- Standardized fallback enemy spawn positions per variant.
- Realigned hazard positions with the room layouts.
- Realigned route gate positions for the route crossing.
- Improved support room dressing for reward, fountain, forge, shop, and route crossing.

## Room Pool

Combat rooms:

```text
Ash Intake Hall
Cinder Drain
Furnace Vestibule
Chain Reservoir
Ember Sorting Floor
Penitent Crossing
```

Support rooms:

```text
Reward Altar
Fountain of Ash
Cold Forge
Ash Merchant
Route Gate Crossing
```

## Definition of Done

```text
Rooms no longer feel like random test boxes.
Rooms are readable.
Player spawn is safe.
Enemy spawns are intentional.
Gates are easy to find.
Hazards are readable.
Circle 0 theme is visible.
```

## Test Checklist

```text
Enter a combat room.
Clear it.
Choose Combat repeatedly until all variants rotate.
Check that the player starts in a safe lower-center zone.
Check that enemies spawn away from the player.
Check that hazards appear in readable lanes/zones.
Check that gates are easy to locate after room clear.
Enter Reward, Fountain, Forge, and Shop rooms when available.
Confirm support-room objects sit in readable positions.
Confirm return loop still works.
```

## Commit

```bash
git add scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd \
    scripts/iso/IsoRoomSetDressing.gd \
    scripts/iso/IsoRoomLocalLoopController.gd \
    tools/validate_room_design_consistency_v17.py \
    docs/ROOM_DESIGN_CONSISTENCY_PASS_V17.md

git commit -m "Standardize Circle 0 room layouts"
```
