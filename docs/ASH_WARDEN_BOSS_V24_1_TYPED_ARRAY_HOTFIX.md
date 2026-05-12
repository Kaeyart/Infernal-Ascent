# V24.1 — Ash Warden Typed Array Hotfix

## Goal

Fix a Godot parser/type compatibility issue caused by assigning `get_tree().get_nodes_in_group("player")` directly into `Array[Node]`.

## Fix

Changed player group lookups from:

```gdscript
var players: Array[Node] = get_tree().get_nodes_in_group("player")
```

to:

```gdscript
var players: Array = get_tree().get_nodes_in_group("player")
```

in:

```text
scripts/iso/AshWardenBoss.gd
scripts/iso/IsoRoomLocalLoopController.gd
```

## Scope

This hotfix does not change boss design, arena flow, combat behavior, rewards, save data, art, or run logic. It only removes the fragile typed-array assignment.

## Test

1. Project opens without parser/type errors.
2. Reach The Sentencing Furnace.
3. Ash Warden spawns.
4. Boss can find player and attack.
5. Player can damage boss.
6. Boss death opens victory exit.
