# Infernal Ascent — Combat Visuals V2 Enemy Feedback

This patch is intentionally code-driven. It does not add image assets and does not modify the player scene or Penitent idle sprites.

Changed files:

- `scripts/combat/Enemy.gd`
- `scripts/combat/DamageNumber.gd`
- `scripts/rooms/CombatRoom.gd`

What it adds:

- stronger enemy hit flash
- visual knockback/squash reaction on hit
- weapon-colored impact rings on enemies
- longer-lived, more visible hit sparks/particles
- improved floating damage numbers
- special big-hit treatment for heavy, Q, ultimate, and execute damage
- room-clear pulse when the last enemy dies

Manual validation checklist:

1. Start a combat room.
2. Hit a normal enemy with light attacks.
3. Check that hit sparks, white flash, damage number, and a small visual recoil appear.
4. Use heavy/Q/ultimate if available and check that impact is larger than light hits.
5. Kill the last enemy and check that the room-clear pulse appears.
6. Confirm the Penitent sprite still looks correct and there is no double body.
