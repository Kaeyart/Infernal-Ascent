#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path.cwd()

PATRON_FILE = ROOT / "data/patrons/patrons.json"
BOON_FILES = [
    ROOT / "data/boons/azazel_chains_boons.json",
    ROOT / "data/boons/mammon_furnace_boons.json",
    ROOT / "data/boons/minos_judge_boons.json",
]
SYNERGY_FILE = ROOT / "data/boons/patron_synergies.json"
SCRIPT_FILES = [
    ROOT / "scripts/run/PatronData.gd",
    ROOT / "scripts/run/BoonData.gd",
    ROOT / "scripts/run/PatronSynergyData.gd",
    ROOT / "scripts/run/RunBoonState.gd",
]

PATRON_FIELDS = {
    "id", "display_name", "short_name", "title", "domain", "short_theme",
    "base_weight", "first_boon_weight", "keepsake_weight_bonus",
    "boon_quality_bonus_from_keepsake", "color_accent", "icon_path",
    "header_path", "mechanic_tags", "lore_note",
}

BOON_FIELDS = {
    "id", "patron_id", "name", "rarity", "category", "description_exact",
    "effect_id", "effect", "synergy_tags", "upgradeable", "icon_path", "vfx_hook",
}

SYNERGY_FIELDS = {
    "id", "name", "required_patrons", "required_tags", "rarity", "category",
    "description_exact", "effect_id", "effect", "icon_path", "vfx_hook",
}

VALID_RARITIES = {"common", "rare", "legendary"}


def load_json(path: Path) -> Any:
    if not path.exists():
        raise SystemExit(f"Missing file: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc


def require_fields(item: dict[str, Any], required: set[str], label: str) -> None:
    missing = sorted(required - set(item.keys()))
    if missing:
        raise SystemExit(f"{label} missing required fields: {', '.join(missing)}")


def require_unique(items: list[dict[str, Any]], field: str, label: str) -> None:
    seen: set[str] = set()
    for item in items:
        value = str(item.get(field, ""))
        if not value:
            raise SystemExit(f"{label} has empty {field}: {item}")
        if value in seen:
            raise SystemExit(f"Duplicate {label} {field}: {value}")
        seen.add(value)


def main() -> None:
    for script_path in SCRIPT_FILES:
        if not script_path.exists():
            raise SystemExit(f"Missing script: {script_path}")

    patrons_raw = load_json(PATRON_FILE)
    if not isinstance(patrons_raw, list):
        raise SystemExit("patrons.json must contain a list")
    patrons: list[dict[str, Any]] = []
    for entry in patrons_raw:
        if not isinstance(entry, dict):
            raise SystemExit("Every patron entry must be an object")
        require_fields(entry, PATRON_FIELDS, f"Patron {entry.get('id', '<missing>')}")
        if not isinstance(entry["mechanic_tags"], list) or not entry["mechanic_tags"]:
            raise SystemExit(f"Patron {entry['id']} must have mechanic_tags list")
        patrons.append(entry)
    require_unique(patrons, "id", "patron")
    patron_ids = {str(p["id"]) for p in patrons}

    all_boons: list[dict[str, Any]] = []
    for boon_file in BOON_FILES:
        boons_raw = load_json(boon_file)
        if not isinstance(boons_raw, list):
            raise SystemExit(f"{boon_file} must contain a list")
        for entry in boons_raw:
            if not isinstance(entry, dict):
                raise SystemExit(f"Every boon in {boon_file} must be an object")
            require_fields(entry, BOON_FIELDS, f"Boon {entry.get('id', '<missing>')}")
            patron_id = str(entry["patron_id"])
            if patron_id not in patron_ids:
                raise SystemExit(f"Boon {entry['id']} references unknown patron_id: {patron_id}")
            rarity = str(entry["rarity"])
            if rarity not in VALID_RARITIES:
                raise SystemExit(f"Boon {entry['id']} has invalid rarity: {rarity}")
            if not isinstance(entry["effect"], dict):
                raise SystemExit(f"Boon {entry['id']} effect must be an object")
            if not isinstance(entry["synergy_tags"], list):
                raise SystemExit(f"Boon {entry['id']} synergy_tags must be a list")
            all_boons.append(entry)
    require_unique(all_boons, "id", "boon")

    boon_count_by_patron: dict[str, int] = {pid: 0 for pid in patron_ids}
    boon_tags: set[str] = set()
    for boon in all_boons:
        boon_count_by_patron[str(boon["patron_id"])] += 1
        for tag in boon.get("synergy_tags", []):
            boon_tags.add(str(tag))

    for patron_id, count in sorted(boon_count_by_patron.items()):
        if count != 8:
            raise SystemExit(f"Expected exactly 8 boons for {patron_id}, found {count}")

    synergies_raw = load_json(SYNERGY_FILE)
    if not isinstance(synergies_raw, list):
        raise SystemExit("patron_synergies.json must contain a list")
    synergies: list[dict[str, Any]] = []
    for entry in synergies_raw:
        if not isinstance(entry, dict):
            raise SystemExit("Every synergy entry must be an object")
        require_fields(entry, SYNERGY_FIELDS, f"Synergy {entry.get('id', '<missing>')}")
        required_patrons = entry["required_patrons"]
        if not isinstance(required_patrons, list) or len(required_patrons) < 2:
            raise SystemExit(f"Synergy {entry['id']} must require at least 2 patrons")
        for patron_id in required_patrons:
            if str(patron_id) not in patron_ids:
                raise SystemExit(f"Synergy {entry['id']} references unknown patron: {patron_id}")
        required_tags = entry["required_tags"]
        if not isinstance(required_tags, list) or not required_tags:
            raise SystemExit(f"Synergy {entry['id']} must require tags")
        # Tags are allowed to be future-facing, but warn if none are known.
        if not any(str(tag) in boon_tags for tag in required_tags):
            raise SystemExit(f"Synergy {entry['id']} has no required tags found in boon data")
        synergies.append(entry)
    require_unique(synergies, "id", "synergy")

    print("T-007 patron/boon schema validation passed.")
    print(f"Patrons: {len(patrons)}")
    print(f"Boons: {len(all_boons)}")
    print(f"Synergies: {len(synergies)}")


if __name__ == "__main__":
    main()
