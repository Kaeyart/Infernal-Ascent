# Player Character Visual V1

This patch replaces the debug-looking drawn test body with a sprite-based visual rig while keeping the working physics player.

## Target script

`res://scripts/iso/IsoPhysicsTestPlayer.gd`

## Added art

```text
res://art/iso/player/penitent_v1/penitent_idle_4x1.png
res://art/iso/player/penitent_v1/penitent_walk_4x1.png
res://art/iso/player/penitent_v1/penitent_attack_4x1.png
```

These are temporary pixel sprites. They are not final character art. Their job is to make the player read as the Penitent Knight instead of a debug pawn.

## What changed

`IsoPhysicsTestPlayer` now:

- remains a `CharacterBody2D`
- keeps `move_and_slide()` movement
- keeps attack input
- keeps enemy damage
- creates `VisualRoot`
- creates `VisualRoot/PenitentSprite`
- animates idle / walk / attack sprite sheets
- flips the sprite when moving left/right
- draws only shadow, attack flash, and optional debug footprint
- keeps fallback debug body if the sprite assets are missing

## Export toggles

Useful Inspector exports:

- `use_sprite_visuals`
- `show_debug_footprint`
- `show_fallback_drawn_body`
- `visual_offset`
- `visual_scale`
- `frame_size`
- `idle_sheet_path`
- `walk_sheet_path`
- `attack_sheet_path`

## Test

Test both:

```text
res://scenes/iso/hub/iso_hub_threshold_nave_v1.tscn
res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn
```

Expected:

- player spawns with sprite body
- movement still works
- collision still works
- hub station interactions still work
- attack still damages hub dummy and run enemies
- Hell Gate still loads Ash Intake Hall
- run room still returns to hub
