# Run Choice & Reward Loop V1 / V10

This patch turns the single Ash Intake Hall test loop into the first physical roguelite route loop.

It does not touch protagonist art, slicing, enemy art, or player combat timing.

## Core loop

```text
Hub
-> Hell Gate
-> Combat Room
-> Room Clear
-> Choose 1 of 3 physical gates
-> Combat / Reward / Fountain / Forge placeholder / Shop placeholder / Elite Combat
-> Continue until run end
-> Press E to return to hub
-> Fountain in hub can read the run result
```

## Files changed

```text
scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd
scripts/iso/IsoRoomLocalLoopController.gd
scripts/iso/RunChoiceGate.gd
scripts/iso/RunRoomInteractable.gd
tools/validate_run_choice_reward_loop_v10.py
docs/RUN_CHOICE_REWARD_LOOP_V1.md
PATCH_README.txt
```

## Route system

The route loop reuses the current authored Ash Intake Hall shell. This avoids needing new room scenes before the core flow is proven.

After each completed room, the controller spawns three physical gates. Each gate has a label, description, color marker, and E interaction.

Room types:

```text
combat        - starts the next Ash Intake encounter cycle
elite_combat  - starts a harder encounter cycle
reward        - spawns three physical upgrade pickups; choose one
fountain      - spawns one fountain; restores HP once
forge         - placeholder interaction: the forge is cold
shop          - placeholder interaction: merchant not ready yet
```

## Reward room V1

Reward rooms spawn physical pickups. The player walks to one and presses E.

Implemented rewards:

```text
+1 Max HP
+1 Light Damage
+1 Heavy Damage
Quicker Dash
Ashen Stride
Longer Reach
Iron Penance
Ash Tithe
Blood Vow
```

## Notes

The old patron flow is kept alive for compatibility, but V10 route gates now own room advancement. `IsoAuthoredRoomRuntimeAdapter` emits `combat_room_cleared`, and `IsoRoomLocalLoopController` handles gates/rewards.
