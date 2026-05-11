# Penitent Animation Art Pass V1

This patch gives the Penitent a real animation set while keeping the current weapon architecture intact.

Included animation families:
- idle: 4 directions, 4 frames
- walk: 4 directions, 4 frames
- dash: 4 directions, 4 frames
- hurt: 4 directions, 4 frames
- attack: 4 directions, 4 frames

Notes:
- Walk is conservative and stable. It is based on the current Penitent identity with small motion/bob so it does not introduce broken AI-frame wobble.
- Dash is stronger and more aggressive.
- Attack frames are a temporary V1 animation layer with slash overlays. They are not final weapon-specific animations.
- Hurt frames are red/stagger feedback frames.

Files:
- art/actors/player/penitent/*.png
- art/actors/player/penitent/<family>/*.png
- art/actors/player/penitent/contact_sheets/PENITENT_ANIMATION_V1_CONTACT_SHEET.png
- scripts/player/PlayerSpriteAnimator.gd

What changed in PlayerSpriteAnimator:
- Resets animation frame when state family changes.
- Updates texture immediately when direction changes.
- Loads both flat sprite files and organized folder sprite files.
- Keeps fallback to idle if a future animation family is missing.

This patch does not add new weapons and does not touch room systems.
