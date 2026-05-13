# T-006 — Enemy Interaction Pass for First Three Enemies

## Goal

Rebuild the first enemy interaction layer around the new player kit: light combo, heavy attack, Q ability, ultimate, and Judgment meter.

This is not enemy final art. This is combat behavior/readability scaffolding.

## Scope

Touches:

- `scripts/iso/IsoPhysicsTestPlayer.gd`
- `scripts/iso/IsoTestEnemy.gd`
- `data/production/demo_asset_tracker.json`

Does not touch:

- enemy art
- boss art
- room art
- patrons
- boons
- forge marks
- weapon ascension
- save structure

## Added behavior

Normal enemies now receive a player-ability interaction payload before damage is applied.

The interaction layer supports:

- light hit reaction
- heavy stagger pressure
- Q ability stagger/control pressure
- ultimate heavy stagger pressure
- small knockback impulse where possible
- temporary stagger/vulnerability state
- role-aware handling for Ash Grunt, Cinder Lunger, and Ember Spitter naming conventions

## Role intent

### Ash Grunt

Basic melee pressure. Teaches normal hit rhythm and stagger basics.

### Cinder Lunger

Dodge-check enemy. Receives stronger stagger/control from Q and ultimate so the player can test counterplay.

### Ember Spitter

Ranged pressure. Receives extra pressure from Q/ultimate so the player can test target-priority tools.

## Acceptance

- Normal enemies can be hit by light/heavy/Q/ultimate without runtime errors.
- Ash Warden still accepts Q/ultimate damage without signature errors.
- First three enemy roles have different interaction responses.
- Stagger state is visible enough through placeholder modulation/response.
- No parser errors.
- No broken run start.

## Test checklist

1. Start a run.
2. Hit Ash Grunt with light/heavy/Q/ultimate.
3. Hit Cinder Lunger with light/heavy/Q/ultimate.
4. Hit Ember Spitter with light/heavy/Q/ultimate.
5. Confirm no damage signature errors.
6. Confirm enemies briefly react/stagger.
7. Reach Ash Warden.
8. Use Q and ultimate on Ash Warden.
9. Confirm boss damage still works.

## Commit

```bash
git add scripts/iso/IsoPhysicsTestPlayer.gd \
        scripts/iso/IsoTestEnemy.gd \
        data/production/demo_asset_tracker.json \
        docs/ENEMY_INTERACTION_PASS_T006.md \
        tools/apply_enemy_interaction_t006.py \
        tools/validate_enemy_interaction_t006.py

git commit -m "Add enemy interaction pass for player abilities"
```
