# Run Results V1

This patch makes the game remember a simple summary when the current test run ends.

## Target flow

Hub:

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

Run Room:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

## Added / changed files

- `scripts/run/RunSessionData.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `docs/RUN_RESULTS_V1.md`

## What it records

When the Ash Intake Hall local run completes, it records:

- status
- rooms cleared
- room cycles
- weapon used
- patron state text
- placeholder reward
- note

Example:

```text
Run Complete
Rooms Cleared: 5
Weapon Used: Penitent Blade
Patron State: LOCKED: Francesca + Ugolino
Reward: Ash Sigils +1 (placeholder reward)
```

## Hub behavior

When you return to the hub, the HUD mentions that Last Run Results are available at the Fountain.

The Fountain now opens a run results panel instead of a generic placeholder.

## What it does not do yet

- no currency saving
- no reward spending
- no real progression
- no persistent save file
- no detailed kill tracking
- no death result

## Test checklist

1. Play Project.
2. Enter Hell Gate.
3. Complete the Ash Intake Hall local run.
4. At run complete, press E to return to hub.
5. Confirm the hub HUD mentions Last Run Results.
6. Walk to Fountain.
7. Press E.
8. Confirm the panel shows run results.
9. Start another run and confirm the result updates.
