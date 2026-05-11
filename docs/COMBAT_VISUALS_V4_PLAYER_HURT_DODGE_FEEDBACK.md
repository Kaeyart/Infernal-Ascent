# Infernal Ascent — Combat Visuals V4: Player Hurt + Dodge Feedback

This is a contained code-driven feedback pass. It does not add generated images, new sprite sheets, or scene rewrites.

## Files touched

- `scripts/player/Player.gd`
- `scripts/player/PlayerSpriteAnimator.gd`

## What changed

- Stronger player hit flash and squash response
- Local impact ring when damage lands
- Small player-side hit particles
- Red screen tint when the player takes real damage
- Subtle low-health pulse below 30% HP
- Dash / invulnerability ring while protected
- Perfect-dodge burst when an attack is avoided inside the dodge window
- Sprite blink/tint during invulnerability and perfect dodge feedback

## What did not change

- No enemy logic changes
- No Penitent idle slicing changes
- No new images
- No run-loop rewrites
- No HUD file edits
- No combat balance edits

## Validation checklist

1. Enter combat.
2. Dash near an enemy attack and check for blue protection feedback.
3. Perfect dodge if possible and check for the blue-white burst.
4. Let yourself get hit once and check for player flash, red screen tint, local ring, and particles.
5. Drop low on health and check for a subtle danger pulse.
6. Confirm the Penitent idle sprite scale and directions are still correct.
