#!/usr/bin/env python3
from pathlib import Path
import json
import sys

ROOT = Path.cwd()
errors = []

def require_file(path: str) -> None:
    if not (ROOT / path).exists():
        errors.append(f"Missing file: {path}")

def require_contains(path: str, needle: str) -> None:
    target = ROOT / path
    if not target.exists():
        errors.append(f"Missing file for content check: {path}")
        return
    if needle not in target.read_text():
        errors.append(f"{path} missing required text: {needle}")

def validate_json(path: str, key: str) -> None:
    target = ROOT / path
    if not target.exists():
        errors.append(f"Missing JSON: {path}")
        return
    try:
        data = json.loads(target.read_text())
    except Exception as exc:
        errors.append(f"Invalid JSON {path}: {exc}")
        return
    if key not in data:
        errors.append(f"{path} missing key {key}")

require_file("data/build_identity/forge_marks.json")
require_file("data/build_identity/weapon_ascensions.json")
require_file("data/boons/azazel_mammon_synergies.json")
require_file("docs/BUILD_IDENTITY_SYSTEMS_T011_T013.md")

validate_json("data/build_identity/forge_marks.json", "forge_marks")
validate_json("data/build_identity/weapon_ascensions.json", "weapon_ascensions")
validate_json("data/boons/azazel_mammon_synergies.json", "synergies")

require_contains("scripts/iso/IsoRoomLocalLoopController.gd", "_build_forge_mark_payloads")
require_contains("scripts/iso/IsoRoomLocalLoopController.gd", "_enter_weapon_ascension_room")
require_contains("scripts/iso/IsoRoomLocalLoopController.gd", "_build_azazel_mammon_synergy_choices")
require_contains("scripts/iso/IsoPhysicsTestPlayer.gd", "apply_build_identity_payload")
require_contains("scripts/iso/IsoPhysicsTestPlayer.gd", "_t011_modify_damage_for_build_identity")
require_contains("scripts/iso/IsoTestEnemy.gd", "t011_apply_burning_chains")

if errors:
    print("T-011/T-012/T-013 validation failed:")
    for error in errors:
        print(" -", error)
    sys.exit(1)

print("T-011/T-012/T-013 validation passed.")
