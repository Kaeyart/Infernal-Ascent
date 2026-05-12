#!/usr/bin/env python3
from pathlib import Path

ROOT = Path.cwd()
required = [
    "scripts/run/SaveGameData.gd",
    "scripts/run/RunEconomyData.gd",
    "scripts/run/RunSessionData.gd",
    "scripts/run/PermanentUpgradeData.gd",
    "scripts/iso/hub/IsoHubRuntimeController.gd",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "docs/SAVE_SYSTEM_V1.md",
]
missing = [p for p in required if not (ROOT / p).exists()]
if missing:
    raise SystemExit("Missing required V28 files:\n" + "\n".join(missing))

save_text = (ROOT / "scripts/run/SaveGameData.gd").read_text()
for token in ["class_name SaveGameData", "SAVE_PATH", "load_or_create", "save_game", "apply_save_dict", "build_save_dict"]:
    if token not in save_text:
        raise SystemExit(f"SaveGameData.gd missing token: {token}")

perm_text = (ROOT / "scripts/run/PermanentUpgradeData.gd").read_text()
for token in ["to_save_dict", "apply_save_dict", "reset_upgrades"]:
    if token not in perm_text:
        raise SystemExit(f"PermanentUpgradeData.gd missing token: {token}")

for p in ["scripts/run/RunEconomyData.gd", "scripts/run/RunSessionData.gd"]:
    txt = (ROOT / p).read_text()
    for token in ["to_save_dict", "apply_save_dict"]:
        if token not in txt:
            raise SystemExit(f"{p} missing token: {token}")

hub_text = (ROOT / "scripts/iso/hub/IsoHubRuntimeController.gd").read_text()
loop_text = (ROOT / "scripts/iso/IsoRoomLocalLoopController.gd").read_text()
if "SaveGameData.load_or_create()" not in hub_text:
    raise SystemExit("Hub runtime does not load save data on ready.")
if "SaveGameData.save_game(\"permanent_upgrade_purchase\")" not in hub_text:
    raise SystemExit("Hub runtime does not save after upgrade purchase.")
if "SaveGameData.load_or_create()" not in loop_text:
    raise SystemExit("Run loop does not load save data on ready.")
if "SaveGameData.save_game(\"run_outcome\")" not in loop_text:
    raise SystemExit("Run loop does not save after run outcome.")

print("V28 save system validation passed.")
