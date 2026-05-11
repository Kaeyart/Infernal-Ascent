# Iso V2 Room Loop V1.2 Hotfix

Fixes the loop not advancing after selecting a patron gate.

## Cause

Your room-local `PatronFlow` could still be using its own local `PatronRunManager`.
The patron choice worked, but the `IsoRunLoopController` did not receive the gate commit, so no next room loaded.

## Fix

This patch makes the room loop more explicit:

- The room scene receives `shared_patron_manager` metadata before it enters the tree.
- `IsoAuthoredRoomRuntimeAdapter` reads that shared manager and assigns it to `PatronFlow`.
- `IsoRunLoopController` links every `PatronFlow` in the loaded room to the shared manager.
- The loop listens to both:
  - `PatronFlow.next_room_choice_selected`
  - `SharedPatronRunManager.gate_choice_committed`
- Double-advance guard prevents skipping rooms.

## Files changed

- `scripts/iso/IsoRunLoopController.gd`
- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`

## Test

Open:

`res://scenes/iso/tests/iso_v2_room_loop_test.tscn`

Run with F6.

Expected after choosing a gate:

- Output should show `[IsoRunLoop] Advance requested...`
- HUD Room number should increase.
- Enemies should respawn.
- Patron lock should persist.
