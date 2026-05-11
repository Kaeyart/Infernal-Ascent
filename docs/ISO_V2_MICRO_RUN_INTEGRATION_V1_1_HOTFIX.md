# Iso V2 Micro-Run Integration V1.1 Hotfix

Fixes parser errors caused by defining a helper named `draw_ellipse()`, which conflicts with Godot's native `CanvasItem.draw_ellipse()` method.

Changed only:

- `scripts/iso/IsoTestPlayer.gd`
- `scripts/iso/IsoV2MicroRunTest.gd`

The helper is now named `_draw_filled_ellipse()`.
