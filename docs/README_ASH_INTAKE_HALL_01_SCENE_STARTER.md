# Ash Intake Hall 01 — Authored Scene Starter V1

This patch adds a prebuilt authored-room scene:

```text
scenes/rooms/circle0/combat_ash_intake_hall_01.tscn
```

It assumes the Ash Intake Hall sliced art kit is already installed at:

```text
art/rooms/circle0/ash_intake_hall_01/sliced_padded_32/
```

## What is already set up

The scene already contains this layer stack:

```text
Art
  L0_Background
  L1_Floor
  L2_Structure
  L3_Props
  L4_Foreground
Collision
Markers
  PlayerSpawn
  RewardSocket
  UpgradeSockets
  EnemySpawns
  DoorSockets
```

## What I placed for you

- dark outside-room backdrop
- background shadow strips
- starter floor block
- central intake seal
- intake grates
- north wall / main intake gate
- side boundary pieces
- bottom/front parapet pieces
- a small number of props
- foreground chains / ash particles
- basic collision rectangles
- player / enemy / door markers

## What you should edit first

Open this scene in Godot:

```text
res://scenes/rooms/circle0/combat_ash_intake_hall_01.tscn
```

Start by editing these layers:

```text
Art/L1_Floor
Art/L2_Structure
Art/L3_Props
```

Do not start by touching the collision unless the player gets stuck.

## Important rule

Keep the middle of the room open. Use props mostly on the sides/back.

This scene is a starter layout, not a final art pass. It is meant to give you the correct room structure so you are not building from an empty scene.

## Install

From your project folder:

```bash
cd /home/kaey/Downloads/infernal_ascent_godot_scaffold || exit 1
cp scenes/rooms/circle0/combat_ash_intake_hall_01.tscn scenes/rooms/circle0/combat_ash_intake_hall_01.tscn.bak_before_scene_starter_v1 2>/dev/null || true
unzip -o /home/kaey/Downloads/ash_intake_hall_01_scene_starter_v1_patch.zip
```

If the scene does not show assets, first install the sliced art kit zip again.
