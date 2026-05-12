# V15 — UI Consistency Pass

## Goal

Make the current demo UI feel like one system instead of several patched overlays.

This patch follows the Production Bible scope for V15. It does not add rooms, enemies, rewards, boss systems, player art, combat tuning, sound, or save logic.

## Touches

- `scripts/iso/ui/InfernalUIRoot.gd`
- `scripts/iso/Circle0RunHUD.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`
- `scripts/iso/RunChoiceGate.gd`
- `scripts/iso/RunRoomInteractable.gd`

## What changed

### Screen UI

The run HUD now uses one consistent infernal UI language:

- compact combat HUD
- consistent top breadcrumb
- room intro toast
- bottom route choice overlay
- right-side inspect panel
- center run result panel

### Route choices

Route cards now use the same format:

```text
LEFT / CENTER / RIGHT GATE
Icon + Room Type
Risk
Short consequence
[E] ENTER
```

The overlay only appears during `ROUTE CHOICE` when real gate choices exist.

### Interactables

World prompts now use one prompt vocabulary:

```text
[E] CLAIM
[E] DRINK
[E] INSPECT
[E] USE
```

### Rewards

The inspect panel now shows exact mechanical text for the current reward IDs.

### Run end panel

The UI now supports V14's explicit phases:

- `RUN VICTORY`
- `RUN DEATH`

The result panel appears for both outcomes.

## Definition of done

- Hub does not show run HUD.
- Run HUD appears only during the run.
- Room intro appears then fades.
- Route cards appear only during route choice.
- Reward/fountain/shop/forge prompts use the same visual language.
- Reward panel explains the effect exactly.
- Run result panel appears at run end.
- No parser errors.

## Test checklist

1. Start in hub.
2. Confirm no run HUD is visible in hub.
3. Enter Hell Gate.
4. Confirm compact run HUD appears.
5. Clear combat.
6. Confirm route cards appear only with physical gates.
7. Choose reward.
8. Stand near each reward and inspect the panel.
9. Claim one reward.
10. Choose fountain / forge / shop if available.
11. Confirm prompts use the same style.
12. Finish run.
13. Confirm run result panel appears.
14. Press E to return to hub.

## Commit

```bash
git add scripts/iso/ui/InfernalUIRoot.gd scripts/iso/Circle0RunHUD.gd scripts/iso/IsoRoomLocalLoopController.gd scripts/iso/RunChoiceGate.gd scripts/iso/RunRoomInteractable.gd tools/validate_demo_ui_consistency_v15.py docs/DEMO_UI_CONSISTENCY_PASS_V15.md
git commit -m "Unify demo UI presentation"
```
