#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "scripts/iso/IsoRoomHazard.gd",
    "scripts/iso/IsoRoomSetDressing.gd",
    "scripts/iso/IsoRoomIntroToast.gd",
    "scripts/iso/RunChoiceGate.gd",
    "scripts/iso/RunRoomInteractable.gd",
    "docs/CIRCLE0_ASH_INTAKE_ZONE_V1.md",
]
TOKENS = {
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd": [
        "Circle 0 Ash Intake Zone V1", "configure_room_presentation", "refresh_room_presentation_only",
        "_spawn_room_presentation_nodes", "_build_hazard_specs", "_get_variant_enemy_spawn_positions",
        "route_gate_crossing",
    ],
    "scripts/iso/IsoRoomLocalLoopController.gd": [
        "V11 Circle 0 Ash Intake Zone V1", "combat_variants", "room_variant_history",
        "_select_combat_variant", "_show_intro", "Circle 0 - Ash Intake Zone V1",
    ],
    "scripts/iso/IsoRoomHazard.gd": [
        "class_name IsoRoomHazard", "ash_vent", "ember_grate", "falling_cinder", "_apply_active_damage",
    ],
    "scripts/iso/IsoRoomSetDressing.gd": [
        "class_name IsoRoomSetDressing", "cinder_drain", "furnace_vestibule", "chain_reservoir", "ember_sorting_floor",
    ],
    "scripts/iso/IsoRoomIntroToast.gd": [
        "class_name IsoRoomIntroToast", "show_intro", "toast_duration",
    ],
    "scripts/iso/RunChoiceGate.gd": [
        "class_name RunChoiceGate", "rarity", "_draw_icon", "Press E - Enter",
    ],
}

def fail(msg: str) -> None:
    print("[V11 VALIDATION FAILED]", msg)
    sys.exit(1)

for rel in REQUIRED:
    if not (ROOT / rel).exists():
        fail(f"Missing required file: {rel}")

for rel, tokens in TOKENS.items():
    text = (ROOT / rel).read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"{rel} missing token: {token}")

for rel in REQUIRED:
    if not rel.endswith(".gd"):
        continue
    text = (ROOT / rel).read_text(encoding="utf-8")
    if "\r" in text:
        fail(f"{rel} has CRLF line endings")
    if "func " not in text:
        fail(f"{rel} appears to contain no functions")
    if "\t" not in text:
        fail(f"{rel} appears to have no tab indentation")

print("[V11 VALIDATION OK] Circle 0 Ash Intake Zone V1 files are present.")
print("Next: run Godot and test Combat -> hazards -> route gates -> reward/fountain/forge/shop -> return hub.")
