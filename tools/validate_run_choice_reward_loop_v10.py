#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "scripts/iso/RunChoiceGate.gd",
    "scripts/iso/RunRoomInteractable.gd",
    "docs/RUN_CHOICE_REWARD_LOOP_V1.md",
]
TOKENS = {
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd": [
        "signal combat_room_cleared", "route_choice_flow_handles_room_clear",
        "start_combat_encounter", "prepare_non_combat_room", "get_choice_gate_positions",
    ],
    "scripts/iso/IsoRoomLocalLoopController.gd": [
        "Run Choice & Reward Loop V1", "_spawn_choice_gates_deferred", "_enter_reward_room",
        "_enter_fountain_room", "_apply_reward", "route_history", "reward_history",
    ],
    "scripts/iso/RunChoiceGate.gd": [
        "class_name RunChoiceGate", "signal gate_chosen", "Press E - Enter",
    ],
    "scripts/iso/RunRoomInteractable.gd": [
        "class_name RunRoomInteractable", "signal activated", "Press E - Claim",
    ],
}

def fail(msg: str) -> None:
    print("[V10 VALIDATION FAILED]", msg)
    sys.exit(1)

for rel in REQUIRED:
    if not (ROOT / rel).exists():
        fail(f"Missing required file: {rel}")

for rel, tokens in TOKENS.items():
    text = (ROOT / rel).read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"{rel} missing token: {token}")

# Light syntax sanity checks. This does not replace opening Godot.
for rel in REQUIRED:
    if not rel.endswith(".gd"):
        continue
    text = (ROOT / rel).read_text(encoding="utf-8")
    if "\t" not in text:
        fail(f"{rel} appears to have no tab indentation; check formatting")
    if "\r" in text:
        fail(f"{rel} has CRLF line endings")

print("[V10 VALIDATION OK] Run Choice & Reward Loop V1 files are present.")
print("Next: run Godot and test combat clear -> 3 gates -> reward/fountain/forge/shop -> return hub.")
