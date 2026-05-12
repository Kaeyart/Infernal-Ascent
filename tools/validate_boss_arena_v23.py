#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
required = {
    "scripts/iso/IsoRoomLocalLoopController.gd": [
        "BOSS_ARENA_PLACEHOLDER",
        "_enter_boss_arena_placeholder",
        "_spawn_boss_placeholder",
        "_on_boss_placeholder_defeated",
        "_spawn_boss_victory_exit",
        "_get_boss_spawn_position",
        "_get_boss_exit_position",
    ],
    "scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd": [
        "boss_arena_player_entry_offset",
        "get_boss_spawn_position",
        "get_boss_exit_position",
        "sentencing_furnace",
    ],
    "scripts/iso/IsoRoomSetDressing.gd": [
        "sentencing_furnace",
        "_draw_sentencing_furnace",
    ],
    "scripts/iso/RunRoomInteractable.gd": [
        "boss_exit",
        "_draw_boss_exit",
    ],
    "scripts/iso/AshWardenBossPlaceholder.gd": [
        "class_name AshWardenBossPlaceholder",
        "placeholder_defeated",
        "[E] BREAK SEAL",
    ],
}

missing = []
for rel, needles in required.items():
    path = ROOT / rel
    if not path.exists():
        missing.append(f"missing file: {rel}")
        continue
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            missing.append(f"{rel}: missing {needle!r}")

if missing:
    print("V23 validation failed:")
    for item in missing:
        print(" -", item)
    raise SystemExit(1)

print("V23 validation passed: Boss Arena V1 files contain expected arena, placeholder, and exit hooks.")
