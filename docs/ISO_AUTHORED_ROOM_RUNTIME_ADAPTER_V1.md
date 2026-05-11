# Iso Authored Room Runtime Adapter V1

This patch adds a reusable adapter for hand-authored isometric rooms.

It does not modify your existing scenes automatically. Add it to a room scene as a child node.

## Added file

`res://scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`

## How to use it

Open your authored isometric room scene.

Add a child node to the room root:

```text
RuntimeAdapter
```

Attach:

```text
res://scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd
```

Run the scene with F6.

The adapter will:

- find `PlayerSpawn`
- create/move `IsoTestPlayer`
- create a `Camera2D` under the test player
- find `RewardSocket`
- find `Door L`, `Door C`, `Door R`
- create/configure `PatronFlow`
- use your authored room markers for altar/gate positions

## Supported marker names

The adapter supports common variants:

- `PlayerSpawn`, `Player Spawn`, `player_spawn`
- `RewardSocket`, `Reward Socket`, `BoonSocket`, `AltarSocket`
- `Door L`, `DoorL`, `Door_Left`, `LeftDoor`
- `Door C`, `DoorC`, `Door_C`, `CenterDoor`
- `Door R`, `DoorR`, `Door_Right`, `RightDoor`

## Controls

Still uses the current test controls:

- WASD / arrows = move test avatar
- C = simulate room clear
- E = interact / claim boon / choose gate
- R = reset patron run

## Why this exists

Before this adapter, every authored room had to manually place:

- IsoTestPlayer
- Camera2D
- PatronFlow
- altar position
- gate positions

Now the authored room markers drive the runtime setup.

## Next step after this works

Real Combat Integration V1:

- spawn actual enemies at Enemy markers
- detect real room clear
- call `PatronFlow.report_room_cleared()` automatically
- remove the debug `C` clear behavior
