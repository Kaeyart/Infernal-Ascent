# V20 — Demo Run Length Lock

## Goal

Define and implement a predictable demo run length.

This follows the Demo Production Bible scope for V20. The demo now has a clear beginning, middle, pre-boss endpoint, and return flow. This patch does not implement the Ash Warden fight; that is reserved for the boss design/arena/boss milestones.

## Route structure

The run now aims for this locked demo structure:

```text
Hub
→ Room 1: Combat
→ Route Choice
→ Room 2: Combat / Reward / Fountain
→ Route Choice
→ Room 3: Combat / Shop / Forge
→ Route Choice
→ Room 4: Elite Combat / Combat
→ Boss Antechamber placeholder
→ Sealed Ash Warden Gate
→ Run Complete
→ Return to Hub
```

## What changed

- `rooms_until_run_end` default is now 4.
- Added V20 exports:
  - `demo_run_length_locked`
  - `demo_rooms_before_boss`
  - `boss_antechamber_variant`
  - `boss_placeholder_completes_run`
  - `force_demo_route_pattern`
- Route choices now follow a predictable demo pattern while the length lock is enabled.
- After the fourth completed room, the run enters a Boss Antechamber placeholder instead of continuing forever.
- The Boss Antechamber contains a sealed Ash Warden gate interactable.
- Interacting with the sealed gate completes the current demo route and returns to the usual run-complete flow.

## Does not touch

- Player art
- Enemy art
- Enemy roster
- Combat timing
- New rewards
- Boss implementation
- Sound
- Save system

## Definition of done

- Run has a clear beginning, middle, and end.
- Player reaches the boss gate after a predictable number of rooms.
- Run does not continue forever.
- Route choices still matter.
- Return-to-hub still works.

## Test checklist

1. Start in hub.
2. Enter Hell Gate.
3. Clear Room 1 combat.
4. Confirm route choices offer Combat / Reward / Fountain.
5. Choose a room and complete it.
6. Confirm next route choices offer Combat / Shop / Forge.
7. Choose a room and complete it.
8. Confirm next route choices offer Elite Combat / Combat / Combat.
9. Complete the fourth room.
10. Confirm Boss Antechamber appears.
11. Interact with the Sealed Ash Warden Gate.
12. Confirm run complete panel appears.
13. Press E to return to hub.

## Commit message

```bash
git commit -m "Lock demo run length"
```
