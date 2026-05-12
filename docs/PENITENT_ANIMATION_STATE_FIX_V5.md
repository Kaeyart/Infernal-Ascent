Infernal Ascent V2 - Penitent Knight Animation State Fix V5

This patch assumes the V4 sliced Penitent Knight sprite assets are already installed.
It does not re-slice the art. It fixes when each animation is selected and how directional rows are chosen.

Main fixes:
- idle and walk are now locomotion states only, not competing with one-shot actions
- dash, hit, light attack, heavy attack, death, and respawn now play as one-shot animations
- one-shot animation lock durations are calculated from frame count / FPS instead of arbitrary short timers
- dash, light attack, and heavy attack no longer get cut off after only the first frames
- mouse attacks face the mouse before selecting the attack row
- keyboard attacks can face the nearest enemy/dummy before selecting the attack row
- direction row selection is stored as se/sw/nw/ne instead of recalculating directly from raw vector every frame
- row mapping is exported, so wrong-facing rows can be remapped in the Inspector without re-slicing

Install:
  cd /home/kaey/Downloads/infernal_ascent_iso_v2
  unzip -o /home/kaey/Downloads/infernal_ascent_penitent_knight_anim_state_patch_v5.zip
  python3 tools/validate_penitent_anim_state_v5.py

Important exported row mapping defaults:
  row_for_southeast = 0
  row_for_southwest = 1
  row_for_northwest = 2
  row_for_northeast = 3

If the animation type is right but the facing is wrong, do not touch the art.
Change only those four exported row values on IsoPhysicsTestPlayer.

Test order:
  1. Stand still: idle loops only.
  2. Move: walk loops only.
  3. Release movement: returns to idle.
  4. Shift: dash one-shot plays across the full dash sheet.
  5. Left mouse or Space: light attack one-shot plays all frames.
  6. Right mouse or F: heavy attack one-shot plays all frames.
  7. Attack with mouse in each quadrant around the player: row changes toward the mouse.
  8. Hit/damage event: hit reaction one-shot plays.
  9. Death event if called: death plays and holds the final collapsed frame.
  10. Respawn event if called: respawn plays, then returns to idle/walk.
