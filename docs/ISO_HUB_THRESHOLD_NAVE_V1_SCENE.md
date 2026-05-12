# Iso Hub Threshold Nave V1 Scene Patch

This patch creates the first playable isometric hub scene.

## Requires

Install the hub asset pack first if you have not already:

`infernal_ascent_iso_hub_assets_v1_sliced.zip`

The scene references assets from:

`res://art/iso/hub/threshold_nave_v1/sliced_padded_32/`

## Added files

- `res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`
- `res://scripts/iso/hub/IsoHubRuntimeController.gd`
- `res://docs/ISO_HUB_THRESHOLD_NAVE_V1_SCENE.md`

## Test scene

Open and run with F6:

`res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn`

## What it contains

- isometric floor blockout
- Hell Gate focal point
- weapon altar placeholder
- boon shrine placeholder
- training yard placeholder
- fountain placeholder
- simple collision
- player spawn
- runtime-spawned `IsoPhysicsTestPlayer`
- `Camera2D` attached to the player
- basic station prompts
- Hell Gate interaction that loads:

`res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn`

## Controls

- WASD / arrows = move
- E = interact
- Space / left mouse = attack, inherited from test player

## Acceptance test

1. Run the hub with F6.
2. Player spawns at bottom center.
3. Walk to Hell Gate.
4. Press E.
5. The active Ash Intake Hall room should load.

## Notes

This is not the final hub. It is the first functional isometric hub blockout using the new hub kit.
Collision is intentionally simple and conservative. Tune it manually in Godot after testing.
