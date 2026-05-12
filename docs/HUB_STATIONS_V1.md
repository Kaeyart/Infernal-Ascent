# V26 — Hub Stations V1

## Goal

Make the hub functional and readable after the demo run can already reach victory/death and return.

This patch follows the Production Bible's V26 scope: the hub gets readable stations and prompts, important stations do something, locked stations communicate future purpose, and the run HUD must not appear in the hub.

## Touches

- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `scripts/iso/hub/IsoHubStationMarker.gd`

## Does not touch

- boss fight logic
- run rewards
- enemy AI
- room layouts
- save system
- permanent upgrade purchasing
- player art
- combat timing

## Hub stations added / standardized

### Hell Gate

Starts the current Circle 0 demo descent.

### Training Yard

Spawns or resets the training dummy.

### Memory Pool

Shows the last run result through the existing `RunSessionData` fountain summary.

### Reliquary Altar

Readable permanent-upgrade station placeholder for V27. It displays current currency and explains that purchasing is intentionally locked until V27.

### Hub Forge

Readable forge/weapon station placeholder. It shows the current weapon panel and explains that run-only forge marks already exist inside runs.

### Codex Lectern

Readable codex placeholder for future enemy, boss, hazard, and lore records.

### Sealed Descent Door

Locked future-content marker showing that the route beyond Circle 0 is not part of the demo slice.

## Definition of done

- Hub has readable stations.
- Each station has a prompt.
- Important stations do something.
- Locked stations communicate future purpose.
- Run HUD does not appear in hub.
- Player can start another run cleanly.

## Test checklist

1. Launch into the hub.
2. Confirm the hub HUD says `THRESHOLD NAVE`, not run/combat UI.
3. Walk to Hell Gate and confirm the prompt appears.
4. Press E at Hell Gate and confirm the run starts.
5. Return to hub after a run.
6. Walk to Memory Pool and confirm last run results appear.
7. Walk to Training Yard and confirm the dummy spawns/resets.
8. Walk to Reliquary Altar and confirm permanent upgrades are clearly locked for V27.
9. Walk to Hub Forge and confirm weapon/forge status appears.
10. Walk to Codex Lectern and confirm placeholder records panel appears.
11. Walk to Sealed Descent Door and confirm future content is clearly locked.
12. Confirm no run HUD appears in hub.

## Commit

```bash
git commit -m "Add functional hub stations"
```
