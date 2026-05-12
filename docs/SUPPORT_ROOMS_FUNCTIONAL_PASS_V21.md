# V21 — Fountain / Shop / Forge Functional Pass

## Goal

Make support rooms useful instead of placeholders.

This follows the Demo Production Bible scope for V21. The run already has a locked demo length from V20. V21 keeps that run structure and gives the Fountain, Shop, and Forge real one-room functions.

## What changed

### Fountain V1

- The Ashen Fountain now restores 60% of max HP.
- It remains one-use-only.
- After drinking, the room completes and route choices appear.

### Shop V1

The Silent Ash Merchant now offers one purchase per shop room using temporary **Run Ash**.

Run Ash is intentionally temporary. It is not the permanent Ash Sigil economy and does not require the save system.

Shop items:

```text
Blood Poultice
Cost: 1 Run Ash
Heal 3 HP immediately.

Pilgrim's Edge
Cost: 2 Run Ash
Light attack damage +1 for this run.

Sealed Boon
Cost: 2 Run Ash
Grants a deterministic mystery boon from the current reward catalogue.
```

### Forge V1

The Cold Forge now offers one run-only sword mark.

Forge marks:

```text
Serrated Edge
Light attack damage +1 and attack arc +8°.

Grave Weight
Heavy attack damage +2, but heavy recovery becomes slower.

Ash Step
Dash cooldown -0.06s and dash duration +0.02s.
```

These are practical run-only mutations. They establish the forge function without building the final weapon-mutation system yet.

## Does not touch

- Boss implementation
- Save system
- Permanent upgrades
- New enemies
- New rooms
- Player sprite art
- Room layout pass

## Definition of done

- Fountain is worth visiting.
- Shop is worth visiting.
- Forge changes playstyle slightly.
- All support rooms use the same interaction UI language.
- Route loop still reaches the boss antechamber after the locked V20 structure.

## Test checklist

1. Start a run.
2. Clear Room 1.
3. Choose Fountain when available.
4. Confirm the fountain heals and then opens route choices.
5. Choose Shop when available.
6. Confirm three shop items appear.
7. Buy one item.
8. Confirm the effect applies and route choices appear.
9. Choose Forge when available.
10. Confirm three forge marks appear.
11. Choose one forge mark.
12. Confirm the effect applies and route choices appear.
13. Continue to the boss antechamber placeholder.
14. Return to hub.

## Commit message

```bash
git commit -m "Make support rooms functional"
```
