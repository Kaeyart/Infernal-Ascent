# Patron Choice + Lock V1

This patch adds the first version of the run identity system:

```text
clear room
→ patron appears
→ claim boon
→ physical exit choices appear
→ choosing a second patron locks the run
→ future patron rewards come from those two patrons
```

## Files added

```text
scripts/patrons/PatronRegistry.gd
scripts/patrons/PatronRunManager.gd
scripts/patrons/PatronBoonAltar.gd
scripts/patrons/PatronChoiceGate.gd
scripts/iso/IsoPatronFlowController.gd
scenes/iso/rooms/circle0/patron_flow_test_room_iso.tscn
docs/PATRON_CHOICE_LOCK_V1.md
```

## First test scene

Open:

```text
res://scenes/iso/rooms/circle0/patron_flow_test_room_iso.tscn
```

Run it.

Controls:

```text
C = simulate room clear
E = interact / claim / choose gate
R = reset patron run
```

The scene is intentionally simple. It proves the logic before we wire it into every room.

## Current patrons

V1 includes 3 patrons:

```text
Francesca — Wind / Longing / Motion
Ugolino — Hunger / Devour / Survival
Minos — Judgment / Mark / Execution
```

## How the lock works

1. First room clear calls a random patron.
2. Claiming that boon adds the first patron to the run.
3. Exit gates appear.
4. If you choose a new patron gate, that patron becomes the second patron.
5. Once two patrons are selected, the run locks.
6. Future patron gates come only from those two patrons, plus occasional utility choices such as forge, fountain, or shop.

## How to hook into a real combat room later

Add an `IsoPatronFlowController` node to the room scene, then call:

```gdscript
$IsoPatronFlowController.report_room_cleared()
```

from the room-clear logic after enemies are dead.

For now, the test scene uses `C` to simulate clear because the isometric combat room is still being rebuilt.

## What this does not do yet

This patch does not yet:

```text
- replace the full old reward system
- load the actual next room from the selected gate
- create final patron art
- create final boon UI art
- save relationship XP permanently
- integrate the hub
```

It is the spine of the new run identity system.
