# T-010 — Mammon Boon Mechanics V1

Goal: make Mammon, the Gilded Furnace, affect combat in-game instead of existing only as boon data.

This is a placeholder mechanics pass. Final fire art, icons, SFX, UI frames, and balance are deferred.

## Implemented mechanics

- Mammon boon ownership is recorded on the player when a Mammon boon is claimed.
- Cinder/burn-style boons ignite enemies on light-style hits.
- Ash Step / dash-style boons create a brief burning dash trail and empower the first attack after dash.
- Scorched Heavy / ember-style boons create a small burn burst around heavy-style hits.
- Kindled Wounds deals bonus damage when Q hits a burning enemy.
- Coal Heart / low-HP fire gives a small damage bonus when the player is under 40% HP.
- Furnace Bloom / explosion boons create a small burn burst when a burning enemy dies.
- Final Flame-style boons make ultimate hits burn survivors.

## Deferred

- Real flame VFX.
- Real boon icons.
- Proper UI explanation beyond the current quick boon description.
- Final audio.
- Balance.
- Shop/gold-specific Mammon economy effects.

## Test checklist

1. Start a run.
2. Claim a Mammon boon.
3. Confirm console prints `[T010] Mammon boon received`.
4. Use light attacks on enemies. If the boon is burn/cinder related, enemies should take burn ticks.
5. If the boon is Ash Step/dash related, dash through/near enemies and attack after dash.
6. If the boon is heavy/ember related, use heavy-style attacks and confirm nearby enemies burn.
7. If the boon is Kindled Wounds, use Q on burning enemies and confirm bonus damage.
8. Confirm Azazel/Mammon/Minos route reward flow still works.
9. Confirm no parser/runtime errors.

## Commit

```bash
git add scripts/iso/IsoPhysicsTestPlayer.gd \
 scripts/iso/IsoTestEnemy.gd \
 scripts/iso/IsoRoomLocalLoopController.gd \
 data/production/demo_asset_tracker.json \
 docs/MAMMON_BOON_MECHANICS_T010.md \
 tools/apply_mammon_boon_mechanics_t010.py \
 tools/validate_mammon_boon_mechanics_t010.py

git commit -m "Add Mammon boon mechanics"
```
