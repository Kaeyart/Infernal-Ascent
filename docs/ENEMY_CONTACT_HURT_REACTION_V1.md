# Enemy Contact / Hurt Reaction V1 / V8

This patch makes enemy and dummy feedback match the player combat timing introduced in V7.

## Player

`IsoPhysicsTestPlayer.gd` now has:

- `max_health`
- `current_health`
- contact damage i-frames
- hit flash ring
- optional health bar
- death animation when HP reaches 0
- `take_damage(amount) -> bool`

Dash invulnerability still wins. If an enemy touches the player during dash invulnerable frames, player damage is rejected.

## Player Attack Delivery

The player attack code now prefers:

```gdscript
receive_player_hit(amount, source_global_position, hit_direction, attack_anim)
```

If a target does not implement that method, it falls back to:

```gdscript
take_damage(amount)
```

This keeps older targets compatible.

## Enemy

`IsoTestEnemy.gd` now has:

- contact damage radius
- contact damage cooldown
- hit flash
- damage numbers
- light/heavy knockback
- delayed queue-free after death so the hit response can be seen briefly

## Training Dummy

`IsoHubTrainingDummy.gd` now has:

- `receive_player_hit(...)`
- visual recoil
- stronger recoil for heavy attacks
- existing HP and damage number behavior preserved

## Test Target

This is still not a full enemy AI attack system. It is only contact/hurt reaction foundation. The next milestone should be enemy telegraphs.
