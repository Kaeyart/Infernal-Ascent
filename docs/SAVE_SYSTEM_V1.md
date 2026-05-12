# V28 — Save System V1

## Goal

Make demo progress persist after quitting and reopening the game.

This milestone follows the Production Bible V28 scope.

## Saves

- Ash Sigils
- Lifetime Ash Sigils earned
- Permanent upgrade levels
- Last run summary
- Completed run count
- Best run depth
- Ash Warden defeated flag

## Save file

```text
user://infernal_ascent_demo_save_v1.json
```

The save is intentionally JSON for the demo stage so it is easy to inspect and debug.

## Load points

- Hub runtime loads save data on `_ready()`.
- Local run runtime also loads save data on `_ready()` so direct room testing is safe.

## Save points

- After a run outcome is recorded.
- After buying a permanent upgrade at the Reliquary Altar.
- When a default save file is first created.

## Does not include

- Multiple save slots.
- Cloud saves.
- Settings menu persistence.
- Full codex/discovery tracking.
- Save migration beyond the V1 schema.

Those belong to later polish/QA passes if needed.

## Test checklist

1. Earn Ash Sigils from a run.
2. Buy a permanent upgrade.
3. Quit the game.
4. Reopen the project/game.
5. Confirm Ash Sigils persist.
6. Confirm upgrade level persists.
7. Start a new run and confirm upgrade effects apply.
8. Defeat Ash Warden or die.
9. Return to hub and confirm Memory Pool result persists after another restart.
