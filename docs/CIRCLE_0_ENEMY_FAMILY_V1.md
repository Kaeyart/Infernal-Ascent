# Circle 0 Enemy Family V1

Theme: Circle 0 · The Cinder Vestibule

Design premise:
Hell is not treated as a random evil monster pit. Circle 0 is the intake chamber of damnation. Its enemies are wardens, functionaries, processed dead, and enforcement mechanisms trying to stop the Penitent Knight from trespassing deeper into the cosmic system.

Enemy roles added:

- Ash Wretch: weak processed soul residue; fragile pressure enemy.
- Gate Warden: slow institutional guard with a heavier cone attack.
- Cinder Scribe: floor-marking punishment bureaucrat; creates delayed judgment circles under/near the player.
- Bell Hound: fast pursuer/pounce enemy that punishes retreat.
- Vestibule Bailiff: elite judgment officer with rotating attack patterns.

Implementation notes:

- No new enemy sprite sheet yet.
- Existing enemy art is reused and recolored/tinted by role.
- CombatRoom now assigns Circle 0 roles based on the current room layout.
- Enemy.gd now supports a sixth optional setup parameter: enemy role.
- Cinder Scribe adds a new attack style: scribe_mark.

Files touched:

- scripts/combat/Enemy.gd
- scripts/rooms/CombatRoom.gd
