# Infernal Ascent — Combat Visuals V3: Enemy Telegraphs

This patch is intentionally code-driven. It does not add new art, regenerate sprites, or change the Penitent idle sprite implementation.

## Files touched

- `scripts/combat/Enemy.gd`
- `scripts/player/Player.gd`

## What changed

Enemy attack windups now have stronger readable danger shapes:

- circular area warning for slam/radius enemies
- cone warning for frontal attackers
- line warning for thrust/ranged-line style enemies
- pounce lane and landing warning for fast enemies
- enemy body warning ring during windup
- warning particles at windup start
- release flash when the attack actually fires
- stronger boss/elite/miniboss windup presence

Player hurt feedback now has a short local impact ring when damage gets through armor/HP.

## What did not change

- No generated images
- No sprite slicing
- No run loop edits
- No enemy stat rebalance
- No Player scene restructuring
- No Penitent scale/idle changes

## Validation checklist

1. Enter a combat room.
2. Let enemies approach instead of killing them instantly.
3. Confirm enemies pause before attacks.
4. Confirm danger shapes show before damage lands.
5. Confirm fast enemies show a pounce lane/landing circle.
6. Confirm line/cone enemies are readable.
7. Confirm player hurt has a short impact ring.
8. Confirm no crashes.
