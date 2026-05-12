# Ash Intake Combat Encounter V1 / V9

This patch turns the Ash Intake Hall from a loose enemy test into a first real combat encounter.

## Files changed

```text
scripts/iso/IsoPhysicsTestPlayer.gd
scripts/iso/IsoTestEnemy.gd
scripts/iso/AshBoltProjectile.gd
scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd
scripts/iso/IsoRoomLocalLoopController.gd
tools/validate_ash_intake_combat_encounter_v9.py
docs/ASH_INTAKE_COMBAT_ENCOUNTER_V1.md
PATCH_README.txt
```

## Gameplay additions

Enemy types:

```text
Ash Grunt      - walks in, telegraphs, then swipes
Cinder Lunger  - pauses, paints a lunge line, then bursts forward
Ember Spitter  - keeps distance, telegraphs, then fires a slow ash bolt
```

Encounter waves:

```text
cycle 1: Ash Grunts
cycle 2: Ash Grunt + Cinder Lunger
cycle 3+: Ash Grunt + Cinder Lunger + Ember Spitter
```

The runtime adapter still uses the authored enemy markers in:

```text
res://scenes/iso/rooms/circle0/combat_ash_intake_hall_01_iso.tscn
```

So the room remains authored; this patch only changes what gets spawned at those sockets.

## Combat behavior

Enemies are no longer just contact hazards by default. Their damage comes from readable attacks:

```text
wind-up telegraph -> active hit window -> recovery
```

The player now supports enemy attack knockback through:

```gdscript
receive_enemy_attack(amount, source_global_position, knockback_direction, knockback_force)
```

Dash invulnerability still works because enemy attacks route through the same player damage gate.

## Debug toggles

On `IsoAuthoredRoomRuntimeAdapter`:

```gdscript
show_enemy_debug_ranges = true
```

On `IsoTestEnemy`:

```gdscript
show_debug_aggro_radius = true
show_debug_attack_range = true
show_debug_active_hitbox = true
```

Use these only while tuning.
