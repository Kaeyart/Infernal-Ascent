#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path.cwd()
FAIL: list[str] = []
WARN: list[str] = []
PASS: list[str] = []

REQUIRED_FILES = [
    "project.godot",
    "scripts/iso/IsoRoomLocalLoopController.gd",
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd",
    "scripts/iso/IsoPhysicsTestPlayer.gd",
    "scripts/iso/IsoTestEnemy.gd",
    "scripts/iso/AshWardenBoss.gd",
    "scripts/iso/AshBoltProjectile.gd",
    "scripts/iso/IsoRoomHazard.gd",
    "scripts/iso/IsoRoomSetDressing.gd",
    "scripts/iso/RunChoiceGate.gd",
    "scripts/iso/RunRoomInteractable.gd",
    "scripts/iso/ui/InfernalUIRoot.gd",
    "scripts/iso/hub/IsoHubRuntimeController.gd",
    "scripts/run/RunEconomyData.gd",
    "scripts/run/RunSessionData.gd",
    "scripts/run/PermanentUpgradeData.gd",
    "scripts/run/SaveGameData.gd",
    "docs/KNOWN_ISSUES.md",
]

REQUIRED_PATTERNS = [
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"HUB", "run phase HUB exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"RUN_START", "run phase RUN_START exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"ROOM_INTRO", "run phase ROOM_INTRO exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"COMBAT", "run phase COMBAT exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"ROUTE_CHOICE", "run phase ROUTE_CHOICE exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"REWARD", "run phase REWARD exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"FOUNTAIN", "run phase FOUNTAIN exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"SHOP", "run phase SHOP exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"FORGE", "run phase FORGE exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"RUN_VICTORY", "run phase RUN_VICTORY exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"RUN_DEATH", "run phase RUN_DEATH exists"),
    ("scripts/iso/IsoRoomLocalLoopController.gd", r"RETURN_TO_HUB", "run phase RETURN_TO_HUB exists"),
    ("scripts/iso/AshWardenBoss.gd", r"Phase|phase", "Ash Warden phase logic exists"),
    ("scripts/run/SaveGameData.gd", r"infernal_ascent_demo_save_v1\.json", "save file path is v1"),
    ("scripts/run/PermanentUpgradeData.gd", r"Iron Vow|iron", "permanent upgrades present"),
    ("scripts/iso/ui/InfernalUIRoot.gd", r"victory|death|result|summary", "UI result panel support present"),
]

KNOWN_BAD_PATTERNS = [
    (r"class_name\s+IsoRoomLocalLoopController", "Unexpected class_name IsoRoomLocalLoopController can break parsing if inserted inside class body"),
    (r"Array\[Node\]\s*=\s*get_tree\(\)\.get_nodes_in_group", "Typed Array[Node] assignment from group lookup can break on some Godot versions"),
    (r"preload\(\s*\"res://scripts/iso/AshWardenBossPlaceholder\.gd\"", "Fragile AshWardenBossPlaceholder preload should not remain"),
    (r"Debug:\s*C\s*=\s*simulate clear", "Live debug instruction text should not remain"),
]

LIVE_DEBUG_PHRASES = [
    "PlayerSpawn",
    "RewardSocket",
    "Patron Flow",
    "Door L",
    "Door C",
    "Door R",
]


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def gd_files() -> Iterable[Path]:
    for base in [ROOT / "scripts", ROOT / "scenes"]:
        if base.exists():
            yield from base.rglob("*.gd")


def check_required_files() -> None:
    for item in REQUIRED_FILES:
        path = ROOT / item
        if not path.exists():
            FAIL.append(f"Missing required file: {item}")
        else:
            PASS.append(f"Found {item}")


def check_required_patterns() -> None:
    for rel_path, pattern, desc in REQUIRED_PATTERNS:
        path = ROOT / rel_path
        if not path.exists():
            continue
        text = read(path)
        if re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE) is None:
            FAIL.append(f"Missing expected pattern for {desc} in {rel_path}")
        else:
            PASS.append(desc)


def check_known_bad_patterns() -> None:
    for path in gd_files():
        text = read(path)
        for pattern, desc in KNOWN_BAD_PATTERNS:
            if re.search(pattern, text):
                FAIL.append(f"{desc}: {rel(path)}")
        for phrase in LIVE_DEBUG_PHRASES:
            if phrase in text and "V34 disabled live debug presentation" not in text:
                WARN.append(f"Potential leftover live/debug phrase '{phrase}' in {rel(path)}. If it is gated behind debug mode, this is acceptable.")


def check_load_paths() -> None:
    path_re = re.compile(r"(?:preload|load)\(\s*\"(res://[^\"]+)\"\s*\)")
    for path in gd_files():
        text = read(path)
        for match in path_re.finditer(text):
            res_path = match.group(1)
            fs_path = ROOT / res_path.replace("res://", "")
            if not fs_path.exists():
                FAIL.append(f"Broken load/preload path in {rel(path)}: {res_path}")
            else:
                PASS.append(f"Load path OK: {res_path}")


def check_duplicate_class_names() -> None:
    class_names: dict[str, list[str]] = {}
    for path in gd_files():
        text = read(path)
        for match in re.finditer(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, flags=re.MULTILINE):
            class_names.setdefault(match.group(1), []).append(rel(path))
    for name, files in class_names.items():
        if len(files) > 1:
            FAIL.append(f"Duplicate GDScript class_name '{name}' in: {', '.join(files)}")


def maybe_run_godot_headless() -> None:
    exe = os.environ.get("GODOT_BIN")
    candidates = [exe] if exe else []
    candidates += ["godot4", "godot", "godot4.3", "godot4.4", "godot4.5", "godot4.6"]
    found = next((c for c in candidates if c and shutil.which(c)), None)
    if not found:
        WARN.append("Godot executable not found in PATH. Static checks ran, but engine parse validation was skipped. Set GODOT_BIN=/path/to/godot to enable it.")
        return
    try:
        result = subprocess.run(
            [found, "--headless", "--quit"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
        )
        if result.returncode != 0:
            FAIL.append("Godot headless parse/open check failed. Output:\n" + result.stdout[-4000:])
        else:
            PASS.append(f"Godot headless parse/open check passed with {found}")
    except Exception as exc:
        WARN.append(f"Could not run Godot headless check: {exc}")


def write_report() -> None:
    report = ROOT / "docs" / "QA_REPORT_V34.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# V34 — Demo QA / Bug Sweep Report",
        "",
        "This report is generated by `tools/validate_demo_qa_bug_sweep_v34.py`.",
        "",
        "## Static Passes",
        "",
    ]
    for item in PASS:
        lines.append(f"- PASS: {item}")
    lines += ["", "## Warnings", ""]
    if WARN:
        for item in WARN:
            lines.append(f"- WARN: {item}")
    else:
        lines.append("- None")
    lines += ["", "## Failures", ""]
    if FAIL:
        for item in FAIL:
            lines.append(f"- FAIL: {item}")
    else:
        lines.append("- None")
    lines += [
        "",
        "## Manual QA Checklist",
        "",
        "- [ ] Start new run.",
        "- [ ] Clear every room type.",
        "- [ ] Choose every gate type.",
        "- [ ] Pick every reward type seen in the run.",
        "- [ ] Use fountain.",
        "- [ ] Use shop.",
        "- [ ] Use forge.",
        "- [ ] Fight Ash Warden.",
        "- [ ] Die in combat.",
        "- [ ] Die to boss.",
        "- [ ] Win boss fight.",
        "- [ ] Return to hub.",
        "- [ ] Save/reload.",
        "- [ ] Start second run.",
        "",
    ]
    report.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    check_required_files()
    check_required_patterns()
    check_known_bad_patterns()
    check_load_paths()
    check_duplicate_class_names()
    maybe_run_godot_headless()
    write_report()

    print("V34 QA validation complete.")
    print(f"PASS: {len(PASS)}")
    print(f"WARN: {len(WARN)}")
    print(f"FAIL: {len(FAIL)}")
    if WARN:
        print("\nWarnings:")
        for item in WARN:
            print(" - " + item)
    if FAIL:
        print("\nFailures:")
        for item in FAIL:
            print(" - " + item)
        print("\nSee docs/QA_REPORT_V34.md for the full report.")
        return 1
    print("\nV34 validation passed. See docs/QA_REPORT_V34.md for the generated report.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
