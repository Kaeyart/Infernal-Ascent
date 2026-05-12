# V30 — Enemy Feel Polish

## Goal

Make enemies more satisfying and fair without changing the demo's structure. This is the Stage D enemy-feel pass from the Demo Production Bible.

## Scope

Touches:

- `scripts/iso/IsoTestEnemy.gd`
- `scripts/iso/AshBoltProjectile.gd`
- `scripts/iso/AshWardenBoss.gd`

Does not touch:

- run flow
- room layouts
- reward logic
- save logic
- permanent upgrades
- player art
- new enemy types
- new boss mechanics
- UI layout

## What changed

### Enemy spawn readability

Enemies now have a short spawn intro ring so new enemies read as entering the encounter instead of popping in silently.

New exported values:

```gdscript
spawn_intro_enabled
spawn_intro_duration
```

### Enemy hit and death feel

Enemies now show clearer local hit bursts and death bursts. This supports the existing hit flash, knockback, damage numbers, and death delay.

New exported values:

```gdscript
hit_burst_duration
death_burst_duration
```

### Enemy attack commitment feedback

Enemy active attack windows now get a small visual flash so attack commitment is easier to read.

New exported value:

```gdscript
attack_commit_flash_duration
```

### Telegraph pulse polish

Enemy windup telegraphs now pulse subtly instead of looking like flat debug shapes.

New exported value:

```gdscript
telegraph_pulse_speed
```

### SFX / feel hooks

Enemies, projectiles, and the boss now emit `feel_event` signals. These are hooks for the later audio pass. V30 does not add actual audio.

Example events:

```text
enemy_spawn
enemy_hit
enemy_death
enemy_attack_active
projectile_hit
boss_hit
boss_phase_changed
boss_death
```

### Projectile readability

Ash bolt projectiles now keep a short sampled trail, making their path easier to read while moving.

New exported values:

```gdscript
trail_sample_interval
max_trail_points
```

### Boss feel polish

The Ash Warden now has hit rings, phase transition rings, and death burst rings. These are visual only and do not change boss mechanics.

New exported values:

```gdscript
boss_hit_burst_duration
phase_transition_burst_duration
boss_death_burst_duration
show_boss_feel_rings
```

## Definition of done

- Enemy attacks remain fair and readable.
- Killing enemies feels more satisfying.
- Enemy type remains quickly identifiable.
- Projectiles are easier to track.
- Boss phase changes are easier to see.
- Boss death has stronger feedback.
- Existing run, boss, save, hub, and return loops still work.

## Test checklist

1. Start a run.
2. Fight Ash Grunt.
3. Fight Cinder Lunger.
4. Fight Ember Spitter.
5. Fight Chainbound Penitent.
6. Fight Furnace Imp.
7. Fight Bell Wretch.
8. Confirm spawn intro is visible but not intrusive.
9. Hit enemies with light and heavy attacks.
10. Confirm hit bursts and death bursts read clearly.
11. Confirm projectiles remain readable in motion.
12. Reach Ash Warden.
13. Damage Ash Warden and confirm boss hit feedback.
14. Push Ash Warden into Phase 2 / Phase 3 and confirm phase feedback.
15. Kill Ash Warden and confirm boss death feedback.
16. Confirm victory / return-to-hub still works.
