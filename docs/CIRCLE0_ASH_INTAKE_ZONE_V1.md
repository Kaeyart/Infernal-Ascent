# Circle 0 Ash Intake Zone V1 / V11

V11 is the first biome presentation patch. It keeps the current authored test scene stable and adds a runtime zone layer on top of it.

It does not touch protagonist art, sprite slicing, direction mapping, player combat timing, or enemy attack logic.

## Added combat room variants

```text
Ash Intake Hall
Cinder Drain
Furnace Vestibule
Chain Reservoir
Ember Sorting Floor
```

The variants currently share the same authored Godot room shell, but each variant gets different runtime dressing, enemy spawn positions, and hazards.

## Hazards

```text
ash_vent        warning ring -> burst
ember_grate     warning rectangle -> burn zone
falling_cinder  warning target -> impact
```

Hazards damage the player and can also damage enemies. They use clear warning states before their active damage window.

## Non-combat presentation

```text
reward_altar
ash_fountain
cold_forge
silent_shop
route_gate_crossing
```

These are still runtime-drawn placeholder spaces, but they now read as physical rooms instead of empty test states.

## Files

```text
scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd
scripts/iso/IsoRoomLocalLoopController.gd
scripts/iso/IsoRoomHazard.gd
scripts/iso/IsoRoomSetDressing.gd
scripts/iso/IsoRoomIntroToast.gd
scripts/iso/RunChoiceGate.gd
scripts/iso/RunRoomInteractable.gd
tools/validate_circle0_ash_intake_zone_v11.py
docs/CIRCLE0_ASH_INTAKE_ZONE_V1.md
PATCH_README.txt
```

## Known limitation

This is still runtime-generated presentation art, not handcrafted `.tscn` room scenes. The purpose is to prove the zone structure, hazards, room types, and combat variety before spending time authoring permanent room scenes.
