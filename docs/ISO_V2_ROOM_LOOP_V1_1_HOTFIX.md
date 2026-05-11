# Iso V2 Room Loop V1.1 Hotfix

Fixes room-loop advancement after choosing a gate.

## Problem

In some authored-room setups, the gate choice was committed through the shared patron manager, but the loop controller did not reliably receive the room-local `PatronFlow.next_room_choice_selected` signal.

That meant:
- room cleared
- boon claimed
- gate chosen
- patron state updated
- but the next room did not load

## Fix

`IsoRunLoopController.gd` now also listens to:

`PatronRunManager.gate_choice_committed`

This is the reliable fallback because every gate choice passes through the shared manager.

The controller also has an `_advance_in_progress` guard so it cannot double-advance if both signals arrive.

## File changed

- `scripts/iso/IsoRunLoopController.gd`

## Test

Open:

`res://scenes/iso/tests/iso_v2_room_loop_test.tscn`

Run with F6.

Flow:
1. Kill enemies.
2. Claim boon.
3. Choose gate.
4. HUD should say loading next room.
5. Same room may reload for V1, but Room number should increment and enemies should respawn.
