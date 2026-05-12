# Patron Shrine V1

This patch turns the Boon Shrine / Patron Shrine into a real patron information station.

## Target scene

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

## Added / changed files

- `scripts/patrons/PatronShrineData.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `docs/PATRON_SHRINE_V1.md`

## What it does

The Patron Shrine now opens a real overview panel for:

- Francesca
- Ugolino
- Minos

The panel explains:

- what patrons are
- current run patron-lock rule
- each patron's gameplay identity
- each patron's build direction
- placeholder relationship rank
- future starting-patron unlocks

## NPC update

The Veiled Attendant now uses the same patron shrine data instead of generic placeholder text.

## What it does not do yet

- no relationship progression yet
- no starting-patron selection yet
- no patron upgrades purchased from the hub yet
- no new patrons
- no boon mechanics changes

## Test checklist

1. Run the hub.
2. Walk to the Patron Shrine / Boon Shrine.
3. Press E.
4. Confirm the panel lists Francesca, Ugolino, and Minos.
5. Confirm each patron has clear gameplay text.
6. Talk to The Veiled Attendant.
7. Confirm she also explains patron functions.
8. Confirm Weapon Altar, NPCs, Fountain, Training Dummy, and Hell Gate still work.
