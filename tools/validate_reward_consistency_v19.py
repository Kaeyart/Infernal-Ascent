#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
controller = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
ui = ROOT / "scripts/iso/ui/InfernalUIRoot.gd"
interactable = ROOT / "scripts/iso/RunRoomInteractable.gd"
doc = ROOT / "docs/REWARD_CONSISTENCY_PASS_V19.md"

required_files = [controller, ui, interactable, doc]
missing = [str(p) for p in required_files if not p.exists()]
if missing:
    raise SystemExit("Missing V19 files:\n" + "\n".join(missing))

text = controller.read_text(encoding="utf-8")
ui_text = ui.read_text(encoding="utf-8")
interactable_text = interactable.read_text(encoding="utf-8")

required_terms = [
    "func _reward_catalogue()",
    "func _reward_data(",
    "rarity",
    "category",
    "exact_effect",
    "current_consequence",
    "reward_display_history",
    "_reward_display_summary",
]
for term in required_terms:
    if term not in text:
        raise SystemExit(f"Controller missing required V19 term: {term}")

ids = re.findall(r'_reward_data\("([^"]+)"', text)
if len(ids) < 20:
    raise SystemExit(f"Expected at least 20 V19 rewards, found {len(ids)}")
if len(ids) != len(set(ids)):
    raise SystemExit("Duplicate reward_id found in V19 reward catalogue")

categories = set(re.findall(r'_reward_data\("[^"]+",\s*"[^"]+",\s*"[^"]+",\s*"([^"]+)"', text))
expected_categories = {"Damage", "Defense", "Mobility", "Utility", "Special"}
missing_categories = expected_categories - categories
if missing_categories:
    raise SystemExit("Missing reward categories: " + ", ".join(sorted(missing_categories)))

ui_terms = ["Current consequence", "exact_effect", "_reward_names_text"]
for term in ui_terms:
    if term not in ui_text:
        raise SystemExit(f"UI missing reward consistency term: {term}")

interactable_terms = ["rarity", "category", "_color_for_reward_category"]
for term in interactable_terms:
    if term not in interactable_text:
        raise SystemExit(f"Interactable missing reward consistency term: {term}")

print(f"V19 reward consistency validation passed. Rewards: {len(ids)} | Categories: {', '.join(sorted(categories))}")
