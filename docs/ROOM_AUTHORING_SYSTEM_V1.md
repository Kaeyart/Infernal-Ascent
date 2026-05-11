# Room Authoring System V1

This patch adds a marker-based authored-room workflow.

The old generated rooms still work as fallback. Nothing changes visually until you create an authored scene with one of the expected filenames.

## Why this exists

The generated draw-code approach is bad for final art direction. Authored scenes let you place art, walls, collision, doors, rewards, and spawn markers visually in the Godot editor.

## New files

```text
scripts/rooms/AuthoredRoomTemplate.gd
scenes/rooms/authored/AuthoredRoomTemplate.tscn
scenes/rooms/circle0/_copy_this_template_for_new_rooms.tscn
```

## Folder convention

Put authored room scenes here:

```text
scenes/rooms/circle0/
```

## Scene structure

Every authored room scene should have this structure:

```text
RoomRoot
  Art
    your sprites / tiles / props
  Collision
    StaticBody2D nodes with CollisionShape2D children
  Markers
    PlayerSpawn
    RewardSocket
    UpgradeSockets
      UpgradeSocket_01
      UpgradeSocket_02
      UpgradeSocket_03
    EnemySpawns
      EnemySpawn_01
      EnemySpawn_02
      EnemySpawn_03
    DoorSockets
      DoorSocket_Left
      DoorSocket_Center
      DoorSocket_Right
```

The room root should have this script:

```text
res://scripts/rooms/AuthoredRoomTemplate.gd
```

## Combat room filenames

CombatRoom.gd auto-checks these paths:

```text
scenes/rooms/circle0/combat_ash_intake_hall_01.tscn
scenes/rooms/circle0/combat_gate_ledger_01.tscn
scenes/rooms/circle0/combat_cinder_procession_01.tscn
scenes/rooms/circle0/combat_sorting_slab_01.tscn
scenes/rooms/circle0/combat_hall_of_unclaimed_names_01.tscn
scenes/rooms/circle0/combat_records_nave_01.tscn
scenes/rooms/circle0/elite_unchosen_court_01.tscn
scenes/rooms/circle0/miniboss_judgment_antechamber_01.tscn
scenes/rooms/circle0/boss_door_before_judgment_01.tscn
```

If a file exists, the game loads it. If not, the old generated room is used.

## Reward room filenames

RewardRoom.gd auto-checks these paths:

```text
scenes/rooms/circle0/reward_upgrade_01.tscn
scenes/rooms/circle0/reward_shop_01.tscn
scenes/rooms/circle0/reward_forge_01.tscn
scenes/rooms/circle0/reward_shrine_01.tscn
scenes/rooms/circle0/reward_fountain_01.tscn
```

If a file exists, the game loads it. If not, the old generated room is used.

## What the markers do

```text
PlayerSpawn = where the player appears
RewardSocket = where the pickup/fountain/forge/shrine interaction sits
UpgradeSockets = where upgrade cards appear
EnemySpawns = where enemies spawn
DoorSockets = where choice doors appear
```

## Collision rule

Only put collision on actual walls and large blockers.

Good collision targets:

```text
walls
large pillars
large altars
large statues
gates
rail blockers
big fountain body
```

Avoid collision on:

```text
floor art
small candles
banners
small rubble
small urns
sigils
trim
```

## Recommended first test

Do not start with combat.

Start with:

```text
reward_fountain_01.tscn
```

Steps:

1. Duplicate `_copy_this_template_for_new_rooms.tscn`.
2. Rename it to `reward_fountain_01.tscn`.
3. Open it in Godot.
4. Add a few sprites under `Art`.
5. Add wall StaticBody2D nodes under `Collision`.
6. Move `PlayerSpawn` and `RewardSocket` where they make sense.
7. Save.
8. Run the game and enter the fountain room.

If it loads, the system works.
