# Ash Intake Hall 01 — Sliced Room Kit V1

This package contains sliced transparent PNG assets from the cleaned source sheets.

## Folders

- `art/rooms/circle0/ash_intake_hall_01/sliced_trimmed/`  
  Tight crops. Best for visual placement when you want minimal empty padding.

- `art/rooms/circle0/ash_intake_hall_01/sliced_padded_32/`  
  Same assets padded to 32-pixel multiples. Best for grid-based placement or Godot snapping.

- `art/rooms/circle0/ash_intake_hall_01/contact_sheets/`  
  Inspection sheets showing all slices with names. These are for you, not for in-game use.

- `art/rooms/circle0/ash_intake_hall_01/source_sheets/`  
  Original cleaned sheets used for slicing.

## Suggested use in Godot

Use `sliced_padded_32` when building with snap/grid. Use `sliced_trimmed` for props that you want to place by eye.

For Ash Intake Hall 01, start with:

1. Floors:
   - `floor_base_dark_stone_A`
   - `floor_base_cracked_worn_B`
   - `floor_accent_judgment_sigil`
   - `floor_border_clean_edge`

2. North/back wall:
   - `front_wall_section_scales`
   - `front_wall_variant_banner_A/B`
   - `main_hell_gate_intake_portal`
   - `gate_frame_arch_empty`
   - `left_corner_wall`
   - `right_corner_wall`

3. Identity props:
   - `ledger_lectern_record_stand`
   - `judgment_clerk_statue`
   - `wall_banner_A_red`
   - `wall_banner_B_black`

4. Gameplay-safe props:
   - `low_brazier_large`
   - `tall_torch_iron_sconce`
   - `short_fence_chain_barrier`
   - `soul_urn_*`
   - `rubble_pile_dark`
   - `floor_grate_tile`

5. Atmosphere:
   - `ember_ash_particle_*`
   - `torch_flame_anim_01..04`
   - `hanging_chain_silhouette_*`
   - generated shadow/vignette overlays

## Notes

- I sliced the cleaned images as provided. Some green/magenta edge residue may remain because the cleaned files still had color-fringing in a few places.
- The marker/collision sheet is in `05_editor_markers`. Treat those as editor/reference helpers, not normal room art.
- The assets are pixel-art styled but not perfectly strict 32x32 tiles. The padded folder makes them easier to snap to a 32px grid.
