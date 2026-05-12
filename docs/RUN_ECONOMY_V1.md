# Run Economy V1

This patch turns the placeholder `Ash Sigils +1` reward into real session currency.

## Added / changed files

- `scripts/run/RunEconomyData.gd`
- `scripts/run/RunSessionData.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/hub/IsoHubRuntimeController.gd`
- `docs/RUN_ECONOMY_V1.md`

## What it adds

Ash Sigils:

- stored in `RunEconomyData`
- current session total
- lifetime session-earned total
- completing the current test run grants +1 Ash Sigil
- hub HUD displays current Ash Sigils
- run room HUD displays current Ash Sigils
- Fountain results display reward gained and total
- Toll Clerk explains the currency

## What it does not add yet

- no spending
- no save file
- no permanent upgrade purchases
- no weapon upgrade purchases
- no patron offerings
- no balancing

## Test checklist

1. Play Project.
2. Confirm hub HUD shows `Ash Sigils: 0`.
3. Enter Hell Gate.
4. Complete Ash Intake Hall local run.
5. Confirm run completion records `Ash Sigils +1`.
6. Return to hub.
7. Confirm hub HUD shows `Ash Sigils: 1`.
8. Walk to Fountain.
9. Press E.
10. Confirm Last Run Results shows Ash Sigils gained and total.
11. Talk to Marta, Toll Clerk.
12. Confirm she explains Ash Sigils.
13. Complete another run and confirm total increases to 2.
