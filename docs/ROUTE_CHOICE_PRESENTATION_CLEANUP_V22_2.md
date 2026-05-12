# V22.2 — Route Choice / Boss Placeholder Presentation Hotfix

This is a blocking readability hotfix after V22.1.

## Goal

Remove the remaining authoring/debug visual remnants, restore small door names above route doors, and keep the sealed Ash Warden placeholder inside the room.

## Touches

- `IsoRoomLocalLoopController.gd`
- `IsoAuthoredRoomRuntimeAdapter.gd`
- `RunChoiceGate.gd`
- `RunRoomInteractable.gd`
- `IsoRoomSetDressing.gd`

## Does not touch

- Boss implementation
- Boss arena implementation
- Enemy roster
- Rewards
- Player art
- Combat timing
- Save system

## Fixes

- Route gates now show compact names above the physical door.
- Bottom route cards remain the primary explanation.
- Gate labels are no longer big floating cards.
- Boss placeholder gate spawns from the room center socket, not raw world origin.
- Boss placeholder uses a physical sealed-door marker.
- Route/boss runtime dressing no longer paints a heavy fake floor over the authored room.
- Authoring marker cleanup is more aggressive for `Enemy`, `Door`, `RewardSocket`, `PlayerSpawn`, `Debug`, and legacy patron-flow visual text.
- Non-combat transitions clear stray enemies/projectiles/hazards more aggressively.

## Definition of done

- No PlayerSpawn / Enemy / Door / RewardSocket debug labels in normal play.
- Physical route gates are inside the room.
- Door names appear above route doors in small labels.
- Bottom cards still match left / center / right.
- Boss antechamber sealed gate is inside the room.
- Boss placeholder does not show a fake giant floor overlay.
- Route choice / reward / fountain / shop / forge / return flow still works.
