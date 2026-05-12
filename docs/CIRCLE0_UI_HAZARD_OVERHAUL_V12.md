# V12 — Circle 0 UI + Hazard Readability Overhaul

Corrective patch after V11. V11 added room variants, hazards, and run choices, but the presentation was too loose. V12 focuses on making the loop readable.

## Goals

- Proper run HUD instead of a raw debug label.
- Explicit room phase: Combat, Route Choice, Reward, Recovery, Forge Placeholder, Shop Placeholder, Run Complete.
- HUD cards that match the three physical route gates.
- Clear objective text for each room.
- More visible hazard windups and active zones.
- Interactables and route gates drawn above room dressing.
- Route summary cleaned up so it reads like a run path rather than duplicate debug entries.

## Files

- `scripts/iso/Circle0RunHUD.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`
- `scripts/iso/IsoRoomHazard.gd`
- `scripts/iso/IsoRoomSetDressing.gd`
- `scripts/iso/RunChoiceGate.gd`
- `scripts/iso/RunRoomInteractable.gd`

## Test checklist

1. Enter Hell Gate.
2. Confirm the HUD says Circle 0, room title, phase, objective, and route.
3. In combat, confirm orange hazard rings are visible before damage.
4. Clear combat.
5. Confirm three physical route gates appear and three HUD cards appear.
6. Walk to each gate and confirm the gate label becomes readable.
7. Choose Reward and confirm reward pickups are readable.
8. Choose Fountain / Forge / Shop if they appear and confirm the objective changes.
9. Finish the run and return to the hub.
