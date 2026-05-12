Infernal Ascent V2 - Penitent Knight Direction State Fix V6

This patch assumes the V4 sliced sprite assets are already installed. It does not re-slice or replace the art. It fixes the direction-selection logic in `scripts/iso/IsoPhysicsTestPlayer.gd`.

Problem fixed:
- V5 chose pure left/right/up/down rows partly from the previous facing direction.
- That meant pressing D/Right could sometimes use the southeast row and sometimes the northeast row depending on what direction the player was facing a moment before.
- The animation row did not always refresh immediately when changing direction inside the same animation state.

V6 behavior:
- D / Right always selects the northeast row by default.
- A / Left always selects the southwest row by default.
- W / Up always selects the northwest row by default.
- S / Down always selects the southeast row by default.
- Diagonal input maps to the matching isometric quadrant.
- When movement stops, the player keeps the last selected facing row for idle.
- If the player is walking and changes from A to D, the sprite row refreshes immediately instead of waiting for the next frame tick.

Important row mapping defaults:
- row_for_southeast = 0
- row_for_southwest = 1
- row_for_northwest = 2
- row_for_northeast = 3

If the animation type is correct but a row faces the wrong way, change only those row exports in the Inspector. Do not re-slice.

Art audit note:
The current generated art is usable, but it is not a perfect four-direction turnaround. The northwest/back-facing row is the cleanest rear row. The northeast row reads more like a front/right three-quarter variant than a true rear/right variant. Use this patch first. If up-right still looks wrong after this, the next correct production step is to regenerate only the missing northeast/back-right directional row, not to redo all slicing.

Install:

```bash
cd /home/kaey/Downloads/infernal_ascent_iso_v2
unzip -o /home/kaey/Downloads/infernal_ascent_penitent_knight_direction_patch_v6.zip
python3 tools/validate_penitent_direction_state_v6.py
```

Test:
1. Press D, release. Idle must face the same right-ish row.
2. Press A, release. Idle must face the same left-ish row.
3. Press W, release. Idle must face the same back/up row.
4. Press S, release. Idle must face the same down/front row.
5. Change direction while already walking. The row must change immediately.
6. Dash should use the same direction as current input, or last facing direction if no input is held.
7. Light/heavy attacks should still play as one-shots.
