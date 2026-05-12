# Training Yard V1

This patch upgrades the hub Training Yard from a placeholder into a useful combat test station.

## Added / changed files

- `scripts/iso/hub/IsoHubTrainingDummy.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `scripts/iso/IsoPhysicsTestPlayer.gd`
- `docs/TRAINING_YARD_V1.md`

## What it adds

Training dummy:

- visible HP bar
- current/max HP text
- damage numbers when hit
- broken/dead state
- reset behavior
- no movement
- no run enemy counting

Player attack:

- still damages normal run enemies
- now also damages generic hub `attack_target` nodes
- no attack damage/range/cooldown balance changes

## Hub behavior

At the Training Yard:

1. Press E.
2. Dummy spawns or resets at `TrainingDummyMarker`.
3. Attack with Space or left mouse.
4. Damage numbers appear.
5. HP bar decreases.
6. If HP reaches 0, dummy enters broken state.
7. Press E at the Training Yard again to reset.

## Test checklist

1. Play Project.
2. Walk to Training Yard.
3. Press E.
4. Confirm dummy appears with HP bar.
5. Hit dummy with Space / left mouse.
6. Confirm damage numbers appear.
7. Confirm HP decreases.
8. Kill dummy.
9. Press E at Training Yard again.
10. Confirm dummy resets.
11. Confirm Hell Gate and Ash Intake Hall combat still work.
