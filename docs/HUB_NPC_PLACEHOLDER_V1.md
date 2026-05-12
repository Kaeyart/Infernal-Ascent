# Hub NPC Placeholder V1

Adds four placeholder NPCs to the isometric hub.

## Target scene

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

## Added / changed files

- `scripts/iso/hub/IsoHubNPC.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `docs/HUB_NPC_PLACEHOLDER_V1.md`

## NPCs

### Varric, Weapon Keeper
Near the Weapon Altar.

Purpose:
- future weapon selection
- weapon upgrades
- weapon aspects

### The Veiled Attendant
Near the Boon Shrine.

Purpose:
- patron relationships
- discovered boons
- starting patron unlocks

### Erem, Ash Archivist
Near the archive/codex side of the hub.

Purpose:
- enemy records
- patron records
- run history
- lore

### Marta, Toll Clerk
Near the merchant/toll side of the hub.

Purpose:
- future shop/economy
- starting supplies
- resource exchange
- run modifier rewards

## Behavior

The NPCs are runtime-spawned near existing hub markers. No manual scene editing required.

Walk near an NPC and press E to open the hub interaction panel.

## Controls

- WASD / arrows = move
- E = interact / close panel
- Esc = close panel

## Test checklist

1. Run the hub.
2. Confirm four NPC silhouettes appear.
3. Walk near each NPC.
4. Confirm prompt changes to the NPC name.
5. Press E.
6. Confirm the NPC panel opens.
7. Close with E or Esc.
8. Confirm Hell Gate and station interactions still work.
