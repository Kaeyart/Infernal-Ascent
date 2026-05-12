# Player Sprite Sheet Integration V3

This patch integrates the current Penitent Knight art pass into Infernal Ascent V2.

## Scope

Only player visuals and `IsoPhysicsTestPlayer.gd` are touched. The hub, room loop, patron flow, training dummy, and run economy scripts are not changed.

## Runtime behavior

`IsoPhysicsTestPlayer.gd` now uses a `Sprite2D` with region rectangles. Each animation sheet is a horizontal frame strip repeated across 4 isometric direction rows.

Direction row mapping:

```text
0 southeast
1 southwest
2 northwest
3 northeast
```

Animation mapping:

```text
idle          -> penitent_idle_4x1.png              4x4
walk/run      -> penitent_walk_4x1.png              6x4
light attack  -> penitent_attack_4x1.png            5x4
heavy attack  -> penitent_heavy_attack_iso_6x4.png  6x4
dash          -> penitent_dash_iso_4x4.png          4x4
hit           -> penitent_hit_iso_3x4.png           3x4
death         -> penitent_death_iso_6x4.png         6x4
respawn       -> penitent_respawn_iso_6x4.png       6x4
```

## Controls preserved

```text
WASD / arrows = movement
Shift = dash
Space / left mouse = light attack
F / right mouse = heavy attack
```

## Important tuning values

The image cells are 128x128 for clean slicing, but the displayed sprite is scaled down:

```gdscript
visual_scale = Vector2(0.55, 0.55)
visual_offset = Vector2(0.0, -30.0)
```

This gives the game the 32-64 px body read without destroying source detail.
