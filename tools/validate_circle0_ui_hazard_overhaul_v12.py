#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
required = [
    "scripts/iso/Circle0RunHUD.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd",
    "scripts/iso/IsoRoomHazard.gd",
    "scripts/iso/RunChoiceGate.gd",
    "scripts/iso/RunRoomInteractable.gd",
    "scripts/iso/IsoRoomSetDressing.gd",
]
missing = [p for p in required if not (ROOT / p).exists()]
if missing:
    print("Missing V12 files:")
    for p in missing:
        print(" -", p)
    sys.exit(1)
checks = {
    "scripts/iso/Circle0RunHUD.gd": ["class_name Circle0RunHUD", "update_from_run_state", "ChoiceCard"],
    "scripts/iso/IsoRoomLocalLoopController.gd": ["use_v12_run_hud", "Circle0RunHUD.new", "_objective_text", "_phase_label", "_current_gate_choices"],
    "scripts/iso/IsoRoomHazard.gd": ["V12 readable hazard marker", "DANGER", "_draw_state_warning", "_draw_countdown_ticks"],
    "scripts/iso/RunChoiceGate.gd": ["Press E to enter", "_color_for_room_type", "Walk close"],
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd": ["hazard_draw_warning_labels", "hazard_debug_draw_radius"],
}
failed = False
for path, needles in checks.items():
    text = (ROOT / path).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            print(f"Check failed: {path} missing {needle!r}")
            failed = True
if failed:
    sys.exit(1)
print("V12 Circle 0 UI + hazard readability files are present.")
print("Run Godot and test: combat room hazards, route gates, reward room, fountain, forge/shop placeholders, return loop.")
