# V23.1 — Boss Arena Parser Hotfix

Fixes a parser-level issue from V23 where `IsoRoomLocalLoopController.gd` used the custom class type `AshWardenBossPlaceholder` before Godot recognized the class name.

## What changed

- `IsoRoomLocalLoopController.gd` now preloads `res://scripts/iso/AshWardenBossPlaceholder.gd` explicitly.
- Static `AshWardenBossPlaceholder` type annotations in the controller were replaced with `Node2D`.
- Cleanup now finds boss placeholder instances through the `boss_placeholder` group instead of a custom class type check.

## What this does not change

- No boss AI.
- No boss fight implementation.
- No arena design change.
- No player/enemy/reward/run-flow expansion.

## Test

1. Project parses without `Could not find type AshWardenBossPlaceholder`.
2. Reach Boss Antechamber.
3. Interact with Sealed Ash Warden Gate.
4. Enter The Sentencing Furnace.
5. Confirm placeholder appears.
6. Press E near placeholder to break seal.
7. Use exit and return to hub.
