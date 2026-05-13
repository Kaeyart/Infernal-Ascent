# T-004 — Q Ability Placeholder

## Goal

Add the first real in-game Q ability so combat stops being left-click-only.

This is a placeholder implementation, not final combat polish.

## Ability

Current placeholder:

```text
Penitent Riposte / Ashen Cleave hybrid placeholder
```

Current behavior:

```text
Press Q.
The player performs a short forward judgment cleave in the current facing direction.
Enemies in range and in front of the player take damage.
Successful hits grant Judgment.
Q goes on cooldown.
A simple debug VFX arc appears.
```

This gives us a gameplay-visible ability immediately while leaving room to convert it into the full timed riposte later.

## Controls

```text
Q = use Q ability
```

The script also supports an InputMap action named:

```text
player_q
```

If that action is not present, the raw Q key fallback still works.

## Current Values

```text
Cooldown: 4.25s
Damage: 2
Radius: 82 px
Judgment gain: 12 per enemy hit
Recovery: 0.34s
```

## What This Touches

```text
scripts/iso/IsoPhysicsTestPlayer.gd
data/production/demo_asset_tracker.json
```

## What This Does Not Touch

```text
final Q animation
final Q VFX
ultimate
patron system
forge system
weapon ascension
enemy art
boss art
room flow
save system
```

## Test Checklist

```text
Start a run.
Face an enemy.
Press Q.
Confirm the player emits a visible gold/ash arc.
Confirm enemy takes damage.
Confirm Judgment increases on hit.
Confirm Q cannot be spammed during cooldown.
Confirm normal light/heavy attacks still work.
Confirm dash still works.
Confirm death/return flow is not broken.
```

## Acceptance

Accepted if:

```text
Q exists in-game.
Q damages enemies.
Q has a cooldown.
Q grants Judgment on hit.
Q uses the current facing direction.
The game still runs without parser errors.
```

## Known Limitations

```text
The full timed riposte is not implemented yet.
The VFX is debug draw, not final art.
The HUD cooldown indicator is currently player-local debug art, not final UI.
```

## Next Ticket

```text
T-005 — Implement Ultimate Placeholder
```
