# V16 — Combat Readability Consistency Pass

## Goal

Make combat readable and fair without adding new enemies, rooms, rewards, boss systems, player art, or run-flow changes.

This pass standardizes the moment-to-moment danger language:

```text
WARNING
→ ACTIVE
→ COOLDOWN
```

## Files changed

```text
scripts/iso/IsoTestEnemy.gd
scripts/iso/IsoRoomHazard.gd
scripts/iso/AshBoltProjectile.gd
scripts/iso/IsoPhysicsTestPlayer.gd
tools/validate_combat_readability_v16.py
docs/COMBAT_READABILITY_CONSISTENCY_PASS_V16.md
```

## What changed

### Enemy telegraphs

Ash Grunt melee attacks now use a more visible wedge with countdown ticks and a `SWIPE` label.

Cinder Lunger attacks now use a clear lane marker with side rails, endpoint marker, countdown ticks, and a `LUNGE` label.

Ember Spitter attacks now use a visible aim line with side rails, charge ring, and a `SHOT` label.

### Active enemy damage

Active melee/lunge frames now draw sharper danger overlays so the player can distinguish warning time from actual damage time.

### Hazards

Room hazards use stronger ground plates, clearer warning rings, countdown ticks, and explicit active danger states.

Hazard default windup is slightly longer so the player can actually react.

### Projectiles

Ash bolts now have a stronger danger ring, core, and trail, making them easier to read during movement.

### Player hit feedback

The player now has a stronger world-space hit marker and a softer invulnerability ring after damage.

## Scope lock

This pass does not alter:

```text
run state
route choices
room generation
enemy roster
new rewards
boss logic
player sprite slicing
save system
sound
```

## Definition of done

```text
Every enemy attack warns before damage.
Every hazard warns before damage.
Player can tell why they got hit.
Player can intentionally dash through danger.
Enemy hit feedback is visible.
Player hit feedback is visible.
No invisible damage.
```

## Test checklist

```text
Fight Ash Grunt.
Fight Cinder Lunger.
Fight Ember Spitter.
Trigger ash vent.
Trigger ember grate.
Trigger falling cinder.
Dash through danger.
Take damage intentionally.
Kill enemies.
Confirm run flow still works.
```

## Commit command

```bash
git add scripts/iso/IsoTestEnemy.gd \
    scripts/iso/IsoRoomHazard.gd \
    scripts/iso/AshBoltProjectile.gd \
    scripts/iso/IsoPhysicsTestPlayer.gd \
    tools/validate_combat_readability_v16.py \
    docs/COMBAT_READABILITY_CONSISTENCY_PASS_V16.md

git commit -m "Improve combat readability and telegraphs"
```
