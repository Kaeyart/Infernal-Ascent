# Player Animation + Weapon Architecture V1

This patch does **not** add new weapons. It makes the current Penitent Blade run through a more future-proof action system.

## What changed

- `WeaponData.gd` now has action tags for light, heavy, Q, and ultimate.
- `WeaponController.gd` now builds an action payload for each attack.
- `Player.gd` exposes action hooks for future rewards/boons.
- `PlayerSpriteAnimator.gd` now supports future `walk_`, `dash_`, `attack_`, and `hurt_` Penitent sprite frames, while falling back to the current idle frames.
- `CombatActionData.gd` exists as a formal resource shape for future systems.

## Current working weapon

The current weapon is still:

```text
penitent_blade
```

Its attacks still emit the legacy signal:

```gdscript
attack_performed(kind, origin, direction, radius, damage)
```

So current room combat should still work.

## New action hooks

Player now emits:

```gdscript
combat_action_started(action: Dictionary)
combat_action_performed(action: Dictionary)
player_dash_started(action: Dictionary)
player_perfect_dodge(action: Dictionary)
```

These are for future boons/rewards.

## Action tags

Example action tags:

```text
light_1: attack, light, melee, slash, combo, blade
heavy: attack, heavy, melee, cleave, charged, stagger, blade
q: attack, skill, q, movement, dash_slash, melee, judgment, blade
ultimate: attack, ultimate, area, judgment, execute, high_cost, blade
```

Future boons should modify tags/events, not hardcoded weapon names.

## Future sprite naming

The animator now checks these paths first:

```text
res://art/actors/player/penitent/walk_down_01.png
res://art/actors/player/penitent/dash_down_01.png
res://art/actors/player/penitent/attack_down_01.png
res://art/actors/player/penitent/hurt_down_01.png
```

If those do not exist, it falls back to:

```text
idle_down_01.png
```

So no new sprite art is required for this patch.
