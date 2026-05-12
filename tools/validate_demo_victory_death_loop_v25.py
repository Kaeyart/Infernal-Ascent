#!/usr/bin/env python3
from pathlib import Path

ROOT = Path.cwd()
required = [
    ROOT / "scripts/iso/IsoRoomLocalLoopController.gd",
    ROOT / "scripts/iso/ui/InfernalUIRoot.gd",
    ROOT / "docs/DEMO_VICTORY_DEATH_LOOP_V25.md",
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    raise SystemExit("Missing V25 files:\n" + "\n".join(missing))

controller = (ROOT / "scripts/iso/IsoRoomLocalLoopController.gd").read_text()
ui = (ROOT / "scripts/iso/ui/InfernalUIRoot.gd").read_text()

checks = {
    "V25 controller header": "V25 — Demo Victory and Death Loop" in controller,
    "victory sigil export": "demo_victory_ash_sigils" in controller,
    "death sigil export": "demo_death_base_ash_sigils" in controller,
    "last run summary": "last_run_summary" in controller,
    "economy award": "RunEconomyData.add_ash_sigils" in controller,
    "session result recording": "RunSessionData.record_completed_run(summary)" in controller,
    "boss defeated flag": "boss_defeated_this_run" in controller,
    "death outcome phase": "RunPhase.RUN_DEATH" in controller,
    "victory outcome phase": "RunPhase.RUN_VICTORY" in controller,
    "UI V25 header": "V25 outcome panels" in ui,
    "victory title": "ASH WARDEN DEFEATED" in ui,
    "death title": "DESCENT FAILED" in ui,
    "ash sigils gained text": "Ash Sigils gained" in ui,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("V25 validation failed:\n" + "\n".join("- " + f for f in failed))

print("V25 validation passed: demo victory/death loop files are present and wired.")
