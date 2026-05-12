# V29 — Player Feel Polish

## Goal

Make the Penitent Knight feel more responsive and satisfying without changing player art, room flow, boss logic, reward structure, save data, enemies, or UI architecture.

This is the first Stage D polish pass from the Demo Production Bible.

## Scope

Touches only:

- `scripts/iso/IsoPhysicsTestPlayer.gd`
- validation/documentation for V29

Does not touch:

- player sprite sheets
- room/run state
- rewards
- enemies
- boss mechanics
- save system
- permanent upgrades
- UI layout

## What changed

### Movement acceleration / deceleration

Movement now accelerates and decelerates instead of snapping instantly between full speed and zero.

New exported values:

```gdscript
movement_acceleration
movement_deceleration
```

### Attack movement commitment

Light and heavy attacks now reduce movement while the attack animation is locked.

New exported values:

```gdscript
attack_movement_multiplier
heavy_attack_movement_multiplier
hit_movement_multiplier
```

### Hit pause

Successful hits briefly pause the player's animation timing for impact readability.

New exported values:

```gdscript
hit_pause_duration_light
hit_pause_duration_heavy
```

### Screen shake hooks

The player script now creates small camera shake on:

- successful light attack hit
- successful heavy attack hit
- dash start
- player damage
- death
- respawn

New exported values:

```gdscript
screen_shake_enabled
attack_hit_shake_strength
heavy_attack_hit_shake_strength
dash_shake_strength
player_damage_shake_strength
death_shake_strength
screen_shake_duration
```

### Dash streak readability

Dash now draws a subtle local streak during the burst.

New exported value:

```gdscript
show_dash_streak
```

### Death / respawn burst readability

Death and respawn now draw simple temporary burst rings.

New exported value:

```gdscript
show_death_respawn_bursts
```

## Definition of done

- Movement feels less robotic.
- Dash has a clearer burst feel.
- Light attack hit has a small impact beat.
- Heavy attack hit has a stronger impact beat.
- Player damage has clearer feedback.
- Death and respawn feel more intentional.
- Existing combat timing still works.
- Existing run / boss / hub loop still works.

## Test checklist

1. Launch into hub.
2. Start a run.
3. Move in all directions and confirm acceleration/deceleration feels okay.
4. Dash repeatedly and confirm it still works and feels readable.
5. Light attack enemies and confirm hit impact is visible.
6. Heavy attack enemies and confirm heavier impact is visible.
7. Take damage and confirm feedback is visible.
8. Die intentionally and confirm death feedback triggers.
9. Return to hub / restart run flow still works.
10. Fight Ash Warden and confirm boss fight still works.

## Commit message

```bash
git commit -m "Polish player combat feel"
```
