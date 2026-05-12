# Infernal Ascent — Penitent Knight Isometric Sprite Patch V4

This fixes the V3 slicing problem.

V3 used naive equal-cell slicing and 128x128 frames. That made some rows feel like they were sliding or drifting because the generated sheets did not place every sprite perfectly inside identical cells.

V4 changes the pipeline:
- detects real row and column bands from alpha
- crops each frame tightly from real foreground pixels
- ignores slash arcs/cyan dash residue for the body anchor
- places every frame into a 320x320 canvas with a stable baseline/body pivot
- keeps full 4-direction isometric sheets
- adds per-direction strips and preview GIFs for manual inspection

Install:
```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2
unzip -o /home/kaey/Downloads/infernal_ascent_penitent_knight_iso_sprite_patch_v4.zip
python3 -m pip install --user pillow
python3 tools/validate_penitent_iso_assets_v4.py
```

Test:
```text
Play Project
→ hub opens
→ player appears as Penitent Knight
→ idle does not slide
→ WASD movement changes direction and run cycle does not drift badly
→ Shift dash plays dash sheet
→ Space / left mouse light attack plays light attack
→ F / right mouse heavy attack plays heavy attack
→ Training Yard dummy can be hit
→ Hell Gate loads Ash Intake Hall
→ run room still works
→ return loop still works
```

If size is off, tune only these exported values on IsoPhysicsTestPlayer:
```gdscript
visual_scale = Vector2(0.22, 0.22)
visual_offset = Vector2(0.0, -30.0)
```

If direction rows feel swapped, do not reslice. Change only `_get_direction_row()` in `IsoPhysicsTestPlayer.gd`. The sheets are row-ordered:
0=southeast, 1=southwest, 2=northwest, 3=northeast.
