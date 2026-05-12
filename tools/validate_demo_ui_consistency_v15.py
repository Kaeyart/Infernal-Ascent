#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
REQUIRED = [
    "scripts/iso/ui/InfernalUIRoot.gd",
    "scripts/iso/Circle0RunHUD.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "scripts/iso/RunChoiceGate.gd",
    "scripts/iso/RunRoomInteractable.gd",
    "docs/DEMO_UI_CONSISTENCY_PASS_V15.md",
]

TOKENS = {
    "scripts/iso/ui/InfernalUIRoot.gd": [
        "V15 — UI Consistency Pass",
        "update_from_run_state",
        "set_focus_payload",
        "clear_focus_payload",
        "_update_route_cards",
        "_update_summary",
        "RUN VICTORY",
        "RUN DEATH",
        "[E] ENTER",
        "_reward_exact_text",
    ],
    "scripts/iso/RunRoomInteractable.gd": [
        "_prompt_text_for_kind",
        "[E] CLAIM",
        "[E] DRINK",
        "[E] INSPECT",
    ],
    "scripts/iso/IsoRoomLocalLoopController.gd": [
        '"run_finished": run_finished',
        '"victory": current_phase == RunPhase.RUN_VICTORY',
    ],
}

errors = []
for rel in REQUIRED:
    path = ROOT / rel
    if not path.exists():
        errors.append(f"missing required file: {rel}")

for rel, tokens in TOKENS.items():
    path = ROOT / rel
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            errors.append(f"{rel} missing token: {token}")

if errors:
    print("V15 validation failed:")
    for err in errors:
        print(" -", err)
    sys.exit(1)

print("V15 validation passed: UI consistency files are present and scoped correctly.")
