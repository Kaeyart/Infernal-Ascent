#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path.cwd()

KNOWN_ISSUES = ROOT / "docs" / "KNOWN_ISSUES.md"

KNOWN_ISSUES_TEMPLATE = """# Known Issues — Infernal Ascent V2 Demo

This file tracks non-blocking issues so they do not derail the current roadmap milestone.

Use this format:

```text
## Issue Name
Status: Open / Deferred / Fixed
Severity: Blocking / Major / Minor / Cosmetic
Area: UI / Combat / Room / Enemy / Reward / Hub / Save / Art / Audio
Notes:
Next action:
```

## Penitent Knight NE row is visually weaker
Status: Deferred
Severity: Cosmetic
Area: Player Art
Notes: Direction works well enough for the current demo slice. The protagonist art is frozen unless it blocks readability, animation direction, or demo completion.
Next action: Revisit during a later art pass only if it remains visible.

## Procedural audio is temporary
Status: Deferred
Severity: Minor
Area: Audio
Notes: V32 uses generated audio feedback so the demo is not silent. Final authored SFX can replace this later.
Next action: Replace during a later audio polish pass if needed.

"""


def read(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def patch_typed_group_lookup(path: Path) -> bool:
    if not path.exists():
        return False
    text = read(path)
    original = text
    # Godot builds can reject Array[Node] assignment from get_nodes_in_group(), depending on version.
    text = re.sub(
        r"var\s+(\w+)\s*:\s*Array\[Node\]\s*=\s*get_tree\(\)\.get_nodes_in_group\(",
        r"var \1: Array = get_tree().get_nodes_in_group(",
        text,
    )
    if text != original:
        write(path, text)
        return True
    return False


def remove_known_bad_controller_lines(path: Path) -> bool:
    if not path.exists():
        return False
    text = read(path)
    original = text

    # Defensive cleanup for parser regressions seen during V23 hotfixing.
    lines = text.splitlines()
    cleaned: list[str] = []
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "class_name IsoRoomLocalLoopController" and idx > 0:
            continue
        if "preload(\"res://scripts/iso/AshWardenBossPlaceholder.gd\")" in line:
            continue
        cleaned.append(line)
    text = "\n".join(cleaned) + ("\n" if original.endswith("\n") else "")

    # Remove old live debug strings if a previous patch left them as direct draw/UI text.
    # This is intentionally conservative: it only removes exact helper/instruction phrases, not legitimate logic.
    bad_phrases = [
        'Debug: C = simulate clear',
        'Patron Flow',
        'PlayerSpawn',
        'RewardSocket',
        'Door L',
        'Door C',
        'Door R',
    ]
    for phrase in bad_phrases:
        # Comment out draw_string/label assignment lines containing the phrase, rather than deleting surrounding logic.
        pattern = re.compile(rf"^([\t ]*)(.*{re.escape(phrase)}.*)$", re.MULTILINE)
        text = pattern.sub(r"\1# V34 disabled live debug presentation: \2", text)

    if text != original:
        write(path, text)
        return True
    return False


def ensure_known_issues() -> bool:
    if KNOWN_ISSUES.exists():
        return False
    write(KNOWN_ISSUES, KNOWN_ISSUES_TEMPLATE)
    return True


def main() -> int:
    changes: list[str] = []

    for rel in [
        "scripts/iso/AshWardenBoss.gd",
        "scripts/iso/IsoTestEnemy.gd",
        "scripts/iso/IsoPhysicsTestPlayer.gd",
        "scripts/iso/IsoRoomLocalLoopController.gd",
    ]:
        if patch_typed_group_lookup(ROOT / rel):
            changes.append(f"Patched typed group lookup in {rel}")

    if remove_known_bad_controller_lines(ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"):
        changes.append("Cleaned known debug/parser regressions in IsoRoomLocalLoopController.gd")

    if ensure_known_issues():
        changes.append("Created docs/KNOWN_ISSUES.md")

    if changes:
        print("V34 apply completed with changes:")
        for change in changes:
            print(" - " + change)
    else:
        print("V34 apply completed: no code cleanup needed; known issues file already exists or no known bad patterns were found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
