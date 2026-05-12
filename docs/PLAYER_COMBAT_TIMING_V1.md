# Player Combat Timing V1 / V7

This patch moves player damage from button-press timing to animation-frame timing.

## Timing Rules

Light attack:

- animation: `attack`
- sheet: `penitent_light_attack_iso_5x4.png`
- default active frames: `2..3`
- default damage: `attack_damage`

Heavy attack:

- animation: `heavy_attack`
- sheet: `penitent_heavy_attack_iso_6x4.png`
- default active frames: `3..4`
- default damage: `heavy_attack_damage`

Dash:

- animation: `dash`
- default invulnerable frames: `0..2`
- player `take_damage()` returns immediately during those frames.

## Hit Repeat Guard

The player now tracks hit targets per swing with `_active_attack_hit_targets`, keyed by instance id. A dummy or enemy can only take damage once during a single light/heavy attack animation.

## Debugging

Enable these exported properties on `IsoPhysicsTestPlayer`:

- `show_debug_combat_hitbox`
- `show_debug_dash_invulnerability`

The combat debug circle is gray during wind-up/recovery and gold during active frames.

## Important

This patch does not change slicing, row mapping, or animation art. If the wrong direction appears, keep using the V6 direction row exports. If timing feels wrong, tune only the active frame exports first.
