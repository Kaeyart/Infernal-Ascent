# Infernal Ascent — Iso V2 Micro-Run Integration V1

This patch adds one contained integration scene.

It does not wire patron choice into the main game yet.

## Open this scene

`res://scenes/iso/tests/iso_v2_micro_run_test.tscn`

Run the current scene with F6.

## Controls

- WASD / Arrow keys: move the visible test avatar
- C: simulate room clear
- E: interact with patron altar or choice gate
- R: reset patron run

## Expected flow

1. Run the scene with F6.
2. Move the test avatar.
3. Press C to simulate clearing the room.
4. A patron altar appears.
5. Walk near it and press E.
6. Three physical gates appear.
7. Choose a patron gate with E.
8. The second patron locks the run.
9. Press C again.
10. Future patron rewards/gates should use only the locked patron pair, plus utility gates.

## Files added

- `scripts/iso/IsoTestPlayer.gd`
- `scripts/iso/IsoV2MicroRunTest.gd`
- `scenes/iso/tests/iso_v2_micro_run_test.tscn`

## What this is

A playable integration wrapper around the validated Patron Choice + Lock system.

## What this is not

- not the final Ash Intake Hall
- not real combat integration
- not hub integration
- not final UI
