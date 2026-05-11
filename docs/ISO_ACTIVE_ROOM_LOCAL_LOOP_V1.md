# Iso Active Room Local Loop V1

This stops using the wrapper scene.

The active test target is now directly:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

## Install

```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2 || exit 1
unzip -o /home/kaey/Downloads/infernal_ascent_iso_active_room_local_loop_v1_patch.zip
python3 tools/apply_iso_active_room_local_loop_v1.py
```

## Test

Open and run with F6:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

Do not use:

`res://scenes/iso/tests/iso_v2_room_loop_test.tscn`

## Flow

1. Kill enemies.
2. Patron altar appears.
3. Claim boon.
4. Gates appear.
5. Choose gate.
6. Same active room resets in place.
7. Enemies respawn.
8. Patron state persists.
9. After second patron, run locks to the two patrons.

## Controls

- WASD / arrows = move
- Space / left mouse = attack
- E = interact
- C = debug clear fallback
- R = reset patron manager from current flow
- T = restart local loop
