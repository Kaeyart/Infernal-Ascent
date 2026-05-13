#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
checks = [
    ("scripts/iso/IsoRoomLocalLoopController.gd", ["_t014_build_status_summary", '"build_status": _t014_build_status_summary()']),
    ("scripts/iso/RunChoiceGate.gd", ["_t014_compact_text", "route gates must read as reward promises"]),
    ("scripts/iso/RunRoomInteractable.gd", ["_t014_payload_effect_text", "reward_kind"]),
]
optional = [
    ("scripts/iso/Circle0RunHUD.gd", ["_t014_compact_text"]),
]
errors = []
for rel, needles in checks:
    path = ROOT / rel
    if not path.exists():
        errors.append(f"Missing required file: {rel}")
        continue
    text = path.read_text()
    for needle in needles:
        if needle not in text:
            errors.append(f"Missing marker {needle!r} in {rel}")
for rel, needles in optional:
    path = ROOT / rel
    if path.exists():
        text = path.read_text()
        for needle in needles:
            if needle not in text:
                errors.append(f"Optional HUD file exists but missing marker {needle!r} in {rel}")
if errors:
    print("T-014 validation failed:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("T-014 validation passed.")
