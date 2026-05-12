#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
doc = root / "docs" / "ASH_WARDEN_BOSS_DESIGN_LOCK_V22.md"
required = [
    "The Ash Warden",
    "The Sentencing Furnace",
    "Furnace Seal Stagger",
    "Chain Sentence",
    "Judgment Heat",
    "Censer Sweep",
    "Warden Slam",
    "Binding Lunge",
    "Falling Cinder",
    "Summon Penitents",
    "Final Verdict Pattern",
    "Phase 1",
    "Phase 2",
    "Phase 3",
    "V23 Arena Implementation Checklist",
    "V24 Boss Implementation Checklist",
]

if not doc.exists():
    raise SystemExit(f"Missing {doc}")
text = doc.read_text(encoding="utf-8")
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("Missing required boss design sections: " + ", ".join(missing))
print("V22 Ash Warden boss design lock validated.")
