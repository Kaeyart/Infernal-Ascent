# V13 — Infernal UI Framework V1

This patch corrects the V12 direction. It does not add more combat content. It replaces the noisy run presentation with a proper UI layer.

## Design target

Infernal Ascent should not use generic debug labels as UI. The interface should read like an infernal manuscript / crusader reliquary: ash-black panels, dull gold trim, red/orange danger language, minimal combat HUD, physical world prompts, and readable reward inspection.

The player must always understand:

1. current room state,
2. next required action,
3. consequence of a choice,
4. danger timing.

## Architecture

### Screen UI

Added:

```text
res://scripts/iso/ui/InfernalUIRoot.gd
```

This is a real `CanvasLayer` and `Control` HUD. It owns:

- combat status panel,
- HP/currency line,
- top breadcrumb,
- room intro toast,
- route choice overlay,
- reward/interactable inspection panel,
- run summary panel.

`Circle0RunHUD.gd` is now only a compatibility shim that extends `InfernalUIRoot.gd`, so existing runtime code can still call `Circle0RunHUD.new()`.

### World UI

Updated:

```text
RunChoiceGate.gd
RunRoomInteractable.gd
IsoRoomHazard.gd
```

World-space UI is now limited to physical markers and short prompts. Description text moves into the screen-space inspection/route panels.

## Behavior changes

- Combat HUD is compact.
- Room intro appears briefly, then disappears.
- Route cards appear only during route-choice phase.
- Route cards match physical gates left-to-right.
- Reward/fountain/forge/shop details appear only when the player focuses the object.
- Hazards use stronger warning rings, countdown ticks, and active danger markers.
- V13 does not touch protagonist art, enemy AI, attack timing, or room spawning.

## Test checklist

1. Hub should not feel covered by a run HUD.
2. Enter Hell Gate.
3. Combat HUD appears compactly.
4. Room intro appears briefly and then hides.
5. Hazards should be clearly visible before damage.
6. Clear combat.
7. Route cards appear only when choices exist.
8. Route cards match the physical gates left-to-right.
9. Choose Reward.
10. Walk near each reward pedestal.
11. Right-side inspection panel should show reward details.
12. Press E to claim one reward.
13. Fountain/Forge/Shop placeholders should show one clean prompt and one clean panel.
14. Finish run and confirm summary panel appears.
