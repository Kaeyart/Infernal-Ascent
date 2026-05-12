# V22.1 — Route Choice Presentation Cleanup Hotfix

## Goal

Remove route-choice debug clutter and make the route-choice screen readable before continuing to boss arena work.

This is a blocking readability hotfix. It exists because the route-choice screen was showing authoring markers, enemy/socket labels, helper zones, and legacy Patron Flow debug UI during normal play.

## Touches

- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`
- `scripts/iso/RunChoiceGate.gd`
- `scripts/iso/IsoRoomSetDressing.gd`

## Does not touch

- player art
- enemy roster
- reward logic
- shop/forge/fountain logic
- boss implementation
- save system
- combat balance

## Changes

- Hides live authoring marker overlays such as `PlayerSpawn`, `Enemy`, `RewardSocket`, and `Door` markers.
- Hides the legacy Patron Flow visual/debug panel during route-choice flow.
- Disables route-choice debug labels by default.
- Disables room layout helper zones by default.
- Shrinks route gates and removes large in-world gate cards.
- Keeps the bottom route-choice panel as the primary explanation layer.
- Moves route gate sockets inward to stay inside the readable room floor.
- Adds conservative clamping for route gate positions.

## Expected presentation

Route choice should now read as:

```text
cleared room
→ three clean physical portals
→ bottom route-choice cards explain left / center / right
→ small [E] ENTER prompt only when near a gate
```

No visible spawn markers. No enemy labels. No socket labels. No Patron Flow debug block. No giant in-world route cards.

## Test checklist

```text
Start a run.
Clear the first combat room.
Reach route choice.
Confirm only the physical gates and bottom choice panel are visible.
Confirm there are no PlayerSpawn / Enemy / Door / RewardSocket labels.
Confirm the Patron Flow debug box is gone.
Confirm gates are inside the room and not clipping through walls.
Walk near each gate.
Confirm only a small [E] ENTER prompt appears.
Choose Reward / Combat / Fountain.
Confirm the room transition still works.
Continue through Shop / Forge / Boss Antechamber placeholder.
Confirm return-to-hub still works.
```

## Commit message

```bash
git commit -m "Clean up route choice presentation"
```
