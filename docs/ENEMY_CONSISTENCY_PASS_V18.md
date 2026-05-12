# V18 — Enemy Consistency Pass

## Goal

Make the current Circle 0 enemy roster distinct, readable, and consistent without adding boss logic, reward systems, hub progression, or save logic.

## Scope

Touches:

- Enemy roles
- Enemy stats
- Enemy telegraphs
- Enemy placeholder silhouettes
- Enemy hit/death feedback
- Encounter profile composition

Does not touch:

- Boss systems
- Reward system
- Hub progression
- Save system
- Player art
- Room flow

## Enemy roster

### Ash Grunt

Basic melee pressure. Walks toward the player and uses a short readable swipe.

### Cinder Lunger

Dodge-check enemy. Stops, telegraphs a lane, then lunges.

### Ember Spitter

Ranged pressure enemy. Keeps distance, telegraphs a shot, then fires a slow ash projectile.

### Chainbound Penitent

Slow armored threat. High HP, slow movement, long wind-up, heavy swing, reduced knockback.

### Furnace Imp

Fast nuisance. Low HP, fast movement, short attack, high knockback when hit.

### Bell Wretch

Support/disruption enemy. Keeps distance, telegraphs a bell pulse, then rouses nearby enemies by reducing their attack cooldown and forcing idle enemies into chase.

## Encounter rule

Enemy mixes now use the full roster by room variant and encounter cycle instead of repeatedly spawning only the original three test enemies.

## Definition of done

- Each enemy has one clear role.
- Each enemy has readable attack timing.
- Each enemy has visible hit feedback.
- Each enemy has visible death feedback.
- Enemies do not all feel identical.
- Mixed groups create different pressure without dogpiling the player.
