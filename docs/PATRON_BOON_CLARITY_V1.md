# Patron Boon Clarity V1

This patch improves player-facing boon/patron text.

## Changed files

- `scripts/patrons/PatronRegistry.gd`
- `scripts/patrons/PatronBoonAltar.gd`
- `scripts/patrons/PatronChoiceGate.gd`

## What changed

Patron text now uses gameplay-readable descriptions instead of only abstract tags.

Examples:

- Francesca: `Speed and wind attacks`
- Ugolino: `Survive by hurting enemies`
- Minos: `Mark and execute enemies`

Boon data now includes:

- `summary`
- `trigger_text`
- `effect_text`
- `build_hint`
- `patron_role_text`
- `patron_simple_text`

The boon altar card now shows:

- patron identity
- boon name
- affected slot
- rarity
- what it does
- trigger
- effect
- build hint

The choice gates also show a short helper line for patron/utility choices.

## What did not change

- no new patrons
- no mechanics changes
- no room changes
- no art changes
- no run loop changes

## Test

Run:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

Clear the room, inspect the patron boon altar, claim it, then inspect the gate choices.
