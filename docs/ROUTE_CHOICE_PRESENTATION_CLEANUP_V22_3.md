# V22.3 — Boss Gate Parser Hotfix

## Goal

Fix the parser error introduced in V22.2:

```text
Function "_get_boss_gate_position()" not found in base self.
```

## Scope

This is a parser/readability hotfix only. It does not add boss gameplay, new rooms, new enemies, rewards, save logic, or player art changes.

## Changes

- Adds `_get_boss_gate_position()` to `IsoRoomLocalLoopController.gd`.
- Adds `get_boss_gate_position()` to `IsoAuthoredRoomRuntimeAdapter.gd`.
- Clamps reward and boss-gate fallback sockets to safe demo-floor bounds.
- Keeps the sealed Ash Warden gate inside the current boss antechamber presentation instead of using world-origin or out-of-room placement.

## Definition of done

- Project parses.
- Boss antechamber spawns the sealed gate inside the room.
- Route choice presentation remains cleaned up from V22.1/V22.2.
- Return-to-hub still works.
