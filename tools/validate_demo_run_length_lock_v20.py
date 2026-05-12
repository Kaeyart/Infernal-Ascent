#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
controller = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
doc = ROOT / "docs/DEMO_RUN_LENGTH_LOCK_V20.md"

missing = [str(p) for p in [controller, doc] if not p.exists()]
if missing:
    raise SystemExit("Missing V20 files:\n" + "\n".join(missing))

text = controller.read_text(encoding="utf-8")
required_terms = [
    "V20 — Demo Run Length Lock",
    "@export var rooms_until_run_end: int = 4",
    "demo_run_length_locked",
    "demo_rooms_before_boss",
    "boss_antechamber_variant",
    "force_demo_route_pattern",
    "func _enter_boss_antechamber_placeholder()",
    "func _on_boss_antechamber_used",
    "func _build_locked_demo_gate_choices()",
    "Sealed Ash Warden Gate",
    "Boss Antechamber",
    "rooms_completed >= maxi(1, demo_rooms_before_boss)",
]
for term in required_terms:
    if term not in text:
        raise SystemExit(f"Controller missing required V20 term: {term}")

route_terms = [
    '"combat", "Combat", "Standard fight',
    '"reward", "Reward", "Claim one temporary boon',
    '"fountain", "Fountain", "Recover before',
    '"shop", "Shop", "Reserved economy',
    '"forge", "Forge", "Reserved weapon mark',
    '"elite_combat", "Elite Combat", "Harder final fight',
]
for term in route_terms:
    if term not in text:
        raise SystemExit(f"Locked route pattern missing term: {term}")

if "func _finish_local_run" not in text or "Demo route complete. The Ash Warden gate has been reached." not in text:
    raise SystemExit("V20 run completion route is missing")

print("V20 demo run length lock validation passed.")
