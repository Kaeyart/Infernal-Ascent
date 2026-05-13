#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path.cwd()
TRACKER_PATH = ROOT / "data/production/demo_asset_tracker.json"


def update_entry(obj: Any) -> bool:
    changed = False
    if isinstance(obj, dict):
        item_id = str(obj.get("id", ""))
        if item_id == "S-006":
            obj["status"] = "Placeholder"
            obj["notes"] = "T-007 added patron, boon, and synergy data schema. Runtime reward integration comes in T-008."
            changed = True
        # Do not set S-007 to accepted; old two-patron ticket is intentionally rejected/renamed.
        if item_id == "S-007":
            obj["status"] = "Rework"
            obj["notes"] = "Old two-patrons-per-run lock rejected. Replace with weighted boon reward pool in T-008."
            changed = True
        for value in obj.values():
            changed = update_entry(value) or changed
    elif isinstance(obj, list):
        for value in obj:
            changed = update_entry(value) or changed
    return changed


def main() -> None:
    required = [
        ROOT / "scripts/run/PatronData.gd",
        ROOT / "scripts/run/BoonData.gd",
        ROOT / "scripts/run/PatronSynergyData.gd",
        ROOT / "scripts/run/RunBoonState.gd",
        ROOT / "data/patrons/patrons.json",
        ROOT / "data/boons/azazel_chains_boons.json",
        ROOT / "data/boons/mammon_furnace_boons.json",
        ROOT / "data/boons/minos_judge_boons.json",
        ROOT / "data/boons/patron_synergies.json",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("Missing T-007 files after unzip:\n" + "\n".join(missing))

    if TRACKER_PATH.exists():
        data = json.loads(TRACKER_PATH.read_text(encoding="utf-8"))
        if update_entry(data):
            TRACKER_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print("Updated tracker statuses for S-006 / S-007.")
        else:
            print("Tracker found, but S-006/S-007 entries were not located. No tracker update made.")
    else:
        print("Tracker JSON not found. Skipping tracker update.")

    print("T-007 files are present.")


if __name__ == "__main__":
    main()
