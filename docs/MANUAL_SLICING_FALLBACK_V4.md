# Manual Slicing Fallback — Penitent Knight

If any animation still feels wrong, do not redraw the art. Fix the anchor.

Use Aseprite or LibreSprite:
1. Open the original Photoroom PNG.
2. Create a 320x320 grid document for the target animation.
3. For each frame, select the visible knight/effect pixels and paste into the 320x320 cell.
4. Put the standing foot/contact point on the same baseline in every frame.
5. Keep the body center near x=160.
6. For slash/dash effects, do not center the whole effect. Center the knight body, then let the effect extend around him.
7. Export the full sheet with the row order: southeast, southwest, northwest, northeast.

Use these final sheet sizes:
- idle: 1280x1280
- walk: 1920x1280
- dash: 1280x1280
- hit: 960x1280
- death: 1920x1280
- respawn: 1920x1280
- light_attack: 1600x1280
- heavy_attack: 1920x1280
