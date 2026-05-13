#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"
DOC = ROOT / "docs/Q_ABILITY_PLACEHOLDER_T004.md"

FAILURES: list[str] = []

def require(cond: bool, msg: str) -> None:
    if not cond:
        FAILURES.append(msg)

def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)

def find_item(data: Any, item_id: str) -> dict[str, Any] | None:
    if isinstance(data, dict):
        if data.get("id") == item_id:
            return data
        for value in data.values():
            found = find_item(value, item_id)
            if found is not None:
                return found
    elif isinstance(data, list):
        for value in data:
            found = find_item(value, item_id)
            if found is not None:
                return found
    return None

require(PLAYER.exists(), "Missing scripts/iso/IsoPhysicsTestPlayer.gd")
require(DOC.exists(), "Missing docs/Q_ABILITY_PLACEHOLDER_T004.md")

if PLAYER.exists():
    text = PLAYER.read_text(encoding="utf-8")
    require("T004_Q_ABILITY_PLACEHOLDER_START" in text, "Player script missing T004 config marker")
    require("T004_Q_ABILITY_PLACEHOLDER_FUNCTIONS_START" in text, "Player script missing T004 function marker")
    require("_t004_consume_q_input()" in text, "Player script missing Q input consumption call")
    require("_t004_try_start_q_ability()" in text, "Player script missing Q start call")
    require("_t004_apply_q_ability_hit()" in text, "Player script missing Q hit application")
    require("q_ability_cooldown_remaining" in text, "Player script missing Q cooldown state")
    require("KEY_Q" in text, "Player script missing Q key fallback")

if TRACKER.exists():
    try:
        data = load_json(TRACKER)
        item = find_item(data, "S-003")
        require(item is not None, "Tracker missing S-003 Q Ability item")
        if item is not None:
            status = str(item.get("status", ""))
            require(status in {"Placeholder", "In Progress", "Accepted"}, f"S-003 has unexpected status: {status}")
    except Exception as exc:
        require(False, f"Could not read tracker JSON: {exc}")
else:
    print("WARNING: tracker JSON not found; skipping tracker status check.")

if FAILURES:
    print("T-004 validation FAILED:")
    for failure in FAILURES:
        print(f" - {failure}")
    raise SystemExit(1)

print("T-004 validation passed.")
