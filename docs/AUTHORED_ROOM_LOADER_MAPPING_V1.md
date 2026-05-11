# Authored Room Loader Mapping V1

This patch makes the authored-room loader less strict.

## Combat rooms
The combat loader now tries:
1. the exact generated layout name, such as `combat_gate_ledger_01.tscn`
2. fallback: `combat_ash_intake_hall_01.tscn`

So your `combat_ash_intake_hall_01.tscn` can be used as a test combat room even when the run randomly picks another combat layout.

## Reward rooms
The reward loader now tries the exact room type first:
- `reward_upgrade_01.tscn`
- `reward_shop_01.tscn`
- `reward_forge_01.tscn`
- `reward_shrine_01.tscn`
- `reward_fountain_01.tscn`

If the exact scene does not exist, it falls back to `reward_upgrade_01.tscn`.

## Debug print
When an authored scene loads, the Output panel prints:

`[AuthoredRoom] Combat loaded: ...`

or

`[AuthoredRoom] Reward loaded: ...`

If you do not see that line, Godot is not finding the scene at the expected path.
