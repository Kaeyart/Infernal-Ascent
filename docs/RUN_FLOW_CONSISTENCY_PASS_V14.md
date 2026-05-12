# V14 — Run Flow Consistency Pass

This patch follows the Infernal Ascent Demo Production Bible milestone V14.

## Goal

Make the current run loop reliable, understandable, and controlled by one explicit state machine.

## Touches

- `scripts/iso/IsoRoomLocalLoopController.gd`
- `tools/validate_run_flow_consistency_v14.py`
- `docs/RUN_FLOW_CONSISTENCY_PASS_V14.md`

## Does not touch

- player art
- enemy art
- enemy roster
- combat timing
- new rooms
- new rewards
- boss systems
- sound
- save system

## Main changes

`IsoRoomLocalLoopController.gd` now owns a formal `RunPhase` enum:

```text
HUB
RUN_START
ROOM_INTRO
COMBAT
ROOM_CLEAR
ROUTE_CHOICE
REWARD
FOUNTAIN
SHOP
FORGE
BOSS_LOCKED_PLACEHOLDER
RUN_VICTORY
RUN_DEATH
RETURN_TO_HUB
```

The old loose state checks have been tightened:

- combat clear signals are ignored unless the run is in `COMBAT`,
- route gates are spawned only after `ROOM_CLEAR`,
- stale/deferred route-gate spawns are cancelled with a phase serial token,
- gate choices are ignored unless the run is in `ROUTE_CHOICE`,
- reward/fountain/shop/forge interactables only complete the room in their matching phase,
- run victory and return-to-hub are explicit phases,
- route nodes and interactables are cleared consistently between phases.

## Definition of done

- Hub has no run UI.
- Run starts cleanly from Hell Gate.
- Combat phase starts correctly.
- Room clear becomes route choice.
- Only one set of gates appears.
- Choosing a gate moves to the correct room phase.
- Reward/fountain/shop/forge each have one clear interaction.
- Run can complete or return to hub cleanly.
- No duplicate gates.
- No stuck states.
- No missing objectives.
- No parser errors.

## Test checklist

1. Start in hub.
2. Enter Hell Gate.
3. Confirm combat begins.
4. Clear combat.
5. Confirm one set of three gates appears.
6. Choose Combat.
7. Clear it and confirm another route choice appears.
8. Choose Reward.
9. Claim one reward and confirm route choice appears.
10. Choose Fountain.
11. Use fountain and confirm route choice appears.
12. Choose Forge if available.
13. Use forge marker and confirm route choice appears.
14. Choose Shop if available.
15. Use merchant marker and confirm route choice appears.
16. Complete enough rooms to end the run.
17. Press E to return to hub.
18. Start a second run.

## Rollback risk

Medium. This replaces the local loop controller state logic, but it does not touch combat, art, enemies, rewards, or room content.

## Commit command

```bash
git status
git add scripts/iso/IsoRoomLocalLoopController.gd tools/validate_run_flow_consistency_v14.py docs/RUN_FLOW_CONSISTENCY_PASS_V14.md
git commit -m "Clean up run flow state machine"
```
