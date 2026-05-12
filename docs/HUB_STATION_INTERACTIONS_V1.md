# Hub Station Interactions V1

This patch makes the current isometric hub stations respond like real game objects.

## Target scene

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

## Changed / added files

- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `scripts/iso/hub/IsoHubInteractionPanel.gd`
- `docs/HUB_STATION_INTERACTIONS_V1.md`

## Station behavior

Hell Gate:
- Press E to start the current run room.

Weapon Altar:
- Opens placeholder weapon/loadout panel.

Boon Shrine:
- Opens placeholder patron relationship panel.

Fountain:
- Opens placeholder recovery/results panel.

Training Yard:
- Spawns or resets a hub training dummy.
- The dummy uses the current test enemy class, so Space / left mouse can damage it.

## Controls

- WASD / arrows = move
- E = interact / close panel
- Esc = close panel
- Space / left mouse = attack dummy

## Test checklist

1. Run the hub.
2. Walk to Weapon Altar, press E, read panel, close it.
3. Walk to Boon Shrine, press E, read panel, close it.
4. Walk to Fountain, press E, read panel, close it.
5. Walk to Training Yard, press E.
6. Confirm a dummy spawns/resets.
7. Hit the dummy with Space / left mouse.
8. Walk to Hell Gate and press E.
9. Confirm Ash Intake Hall loads.
