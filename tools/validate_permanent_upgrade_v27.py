#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    ROOT / "scripts/run/PermanentUpgradeData.gd",
    ROOT / "scripts/iso/hub/IsoHubRuntimeController.gd",
    ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd",
    ROOT / "scripts/iso/IsoRoomLocalLoopController.gd",
    ROOT / "docs/PERMANENT_UPGRADE_V1.md",
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    print("[V27] Missing files:")
    for p in missing:
        print(" -", p)
    sys.exit(1)

texts = {p.name: p.read_text(encoding="utf-8") for p in required}
checks = {
    "PermanentUpgradeData class": "class_name PermanentUpgradeData" in texts["PermanentUpgradeData.gd"],
    "purchase_upgrade": "purchase_upgrade" in texts["PermanentUpgradeData.gd"],
    "apply_to_player": "apply_to_player" in texts["PermanentUpgradeData.gd"],
    "run modifiers": "get_run_start_modifiers" in texts["PermanentUpgradeData.gd"],
    "hub preload": "PermanentUpgradeData.gd" in texts["IsoHubRuntimeController.gd"],
    "hub purchase input": "_try_purchase_reliquary_upgrade" in texts["IsoHubRuntimeController.gd"],
    "player applies upgrades": "apply_to_player(self)" in texts["IsoPhysicsTestPlayer.gd"],
    "loop applies run modifiers": "get_run_start_modifiers" in texts["IsoRoomLocalLoopController.gd"],
    "four reward support": "reward_choices_per_room >= 4" in texts["IsoRoomLocalLoopController.gd"],
}
errors = [name for name, ok in checks.items() if not ok]
if errors:
    print("[V27] Validation failed:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("[V27] Permanent Upgrade V1 files validated.")
print("[V27] This validation checks patch structure only; run the Godot test checklist in-game.")
