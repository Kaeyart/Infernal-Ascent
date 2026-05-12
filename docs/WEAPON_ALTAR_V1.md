# Weapon Altar V1

This patch turns the Weapon Altar from a pure placeholder into the first real hub station.

## Target scene

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

## Added / changed files

- `scripts/player/PlayerWeaponData.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `docs/WEAPON_ALTAR_V1.md`

## What it does

The Weapon Altar now opens a real loadout inspection panel.

It shows:

- current weapon
- status
- role
- weapon fantasy
- current stats
- controls
- strengths
- missing features
- future Weapon Altar functions

## Current weapon

`Penitent Blade`

Current displayed stats:

- Damage: 1
- Attack Range: 82
- Attack Cooldown: 0.28s
- Move Speed: 260

## What it does not do yet

No combat values are changed.

No weapon swapping yet.

No aspects yet.

No upgrade purchasing yet.

## Test checklist

1. Run the hub.
2. Walk to the Weapon Altar.
3. Press E.
4. Confirm the panel says `PENITENT BLADE`.
5. Confirm it lists stats and future functions.
6. Close with E or Esc.
7. Confirm other hub station interactions still work.
8. Confirm Hell Gate still starts the run.
