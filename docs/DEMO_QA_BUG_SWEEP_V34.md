# V34 — Demo QA / Bug Sweep

## Goal

Stabilize the current playable demo slice before packaging. This pass is not content expansion and not polish expansion. It is a focused regression sweep.

## What this pass checks

- Parser/runtime blockers from recent milestone patches.
- Broken load/preload script paths.
- Duplicate `class_name` declarations.
- Known fragile Godot typed-array group lookups.
- Run phase presence.
- Boss, save, permanent upgrade, UI, route, and result-loop file presence.
- Remaining live debug/presentation strings that should not appear in normal play.
- Optional Godot headless project-open check if a Godot executable is available in `PATH` or `GODOT_BIN`.

## What this pass does not change

- No new rooms.
- No new enemies.
- No new rewards.
- No new boss mechanics.
- No balance tuning.
- No UI redesign.
- No player art changes.
- No save schema expansion.

## Manual QA Checklist

Run the generated report and then test the demo manually:

```text
Start new run.
Clear every room type.
Choose every gate type.
Pick every reward type seen in the run.
Use fountain.
Use shop.
Use forge.
Fight Ash Warden.
Die in combat.
Die to boss.
Win boss fight.
Return to hub.
Save/reload.
Start second run.
```

## Definition of done

- No parser errors.
- No stuck rooms.
- No missing gates.
- No invisible damage.
- No broken return loop.
- No save corruption.
- Generated QA report has no failures.

## Expected output

The validator writes:

```text
docs/QA_REPORT_V34.md
```

Commit it with the V34 files if the report is clean.
