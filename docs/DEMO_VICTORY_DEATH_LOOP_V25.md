# V25 — Demo Victory and Death Loop

## Goal

Finish the first complete demo outcome loop:

```text
Boss victory or player death
→ result panel
→ Ash Sigils awarded
→ run summary recorded
→ press E to return to the Threshold Nave
→ player can start another run
```

This patch does not add permanent upgrades, save-system expansion, new rewards, new enemies, new rooms, new boss attacks, or player art.

## What Changed

### Victory

When the Ash Warden is defeated and the player uses the victory exit, the run ends in `RUN_VICTORY`.

Victory now records:

- outcome = victory
- Ash Warden defeated
- rooms cleared
- boons claimed
- forge mark
- shop purchases
- Ash Sigils earned
- Ash Sigils total
- route history

### Death

When the player dies during the run or boss fight, the run ends in `RUN_DEATH`.

Death now records:

- outcome = death
- reason
- rooms cleared
- boons claimed
- forge mark
- shop purchases
- Ash Sigils earned, if any bonus sigils were gained
- route history

### UI

The run result panel now clearly distinguishes:

- `ASH WARDEN DEFEATED`
- `DESCENT FAILED`

It displays the boss result, rooms cleared, boons, forge mark, shop purchases, Ash Sigils gained, Ash Sigils total, and the reason for the outcome.

## Definition of Done

- Player can kill Ash Warden.
- Victory exit appears.
- Victory result panel appears.
- Ash Sigils are awarded and shown.
- Pressing E returns to hub.
- Player can die during the run or boss fight.
- Death result panel appears.
- Pressing E returns to hub.
- RunSessionData receives a clear summary.
- RunEconomyData receives the Ash Sigils earned.

## Test Checklist

```text
Start a run.
Reach Ash Warden.
Kill boss.
Use victory exit.
Confirm victory panel appears.
Confirm Ash Sigils gained line appears.
Press E to return to hub.
Start another run.
Reach combat or boss.
Die intentionally.
Confirm death panel appears.
Press E to return to hub.
Confirm no stuck state.
```
