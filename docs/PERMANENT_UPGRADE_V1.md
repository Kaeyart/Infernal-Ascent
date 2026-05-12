# V27 — Permanent Upgrade V1

## Goal

Make the Reliquary Altar functional. The player can spend Ash Sigils on session-persistent upgrades that affect future runs. Disk persistence is intentionally reserved for V28.

## Touches

- `scripts/run/PermanentUpgradeData.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `scripts/iso/IsoPhysicsTestPlayer.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`

## Does not touch

- save system
- new rooms
- new enemies
- boss mechanics
- player art
- combat timing
- room layouts
- reward pool expansion

## Permanent upgrades

1. **Iron Vow** — +1 max HP per level.
2. **Executioner's Edge** — +1 light/heavy starting damage per level.
3. **Ashen Footwork** — dash cooldown reduced by 0.04s per level.
4. **Pilgrim's Tithe** — +1 outcome Ash Sigil and +1 starting Run Ash per level.
5. **Relic Sense** — reward rooms offer a fourth pedestal.

## Definition of done

- Player earns Ash Sigils.
- Player sees Ash Sigils in the hub.
- Player opens the Reliquary Altar.
- Player buys upgrades with keys 1–5.
- Purchased upgrades affect future runs.
- Upgrade state remains while the game session is running.
- New run starts with upgrade effects.

## Test checklist

1. Complete a run or use existing Ash Sigils.
2. Return to hub.
3. Walk to Reliquary Altar.
4. Press E.
5. Press 1–5 to buy an upgrade.
6. Confirm Ash Sigils decrease.
7. Start a new run.
8. Confirm the purchased effect applies.
9. Return to hub and confirm upgrade level remains.

## Commit

```bash
git commit -m "Add permanent upgrade altar"
```
