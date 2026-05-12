#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
checks = [
    (ROOT / 'scripts/iso/IsoRoomSetDressing.gd', [
        'class_name IsoRoomSetDressing',
        'V17 — Room Design Consistency Pass',
        '_draw_layout_readability_marks',
        '_draw_penitent_crossing',
        '_draw_gate_socket',
        '_draw_pedestal_socket',
    ]),
    (ROOT / 'scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd', [
        'enforce_v17_layout_positions',
        'penitent_crossing',
        '_get_variant_player_spawn_position',
        'get_choice_gate_positions',
        'get_reward_socket_position',
    ]),
    (ROOT / 'scripts/iso/IsoRoomLocalLoopController.gd', [
        'penitent_crossing',
        'combat_variants',
    ]),
]

missing = []
for path, needles in checks:
    if not path.exists():
        missing.append(f'MISSING FILE: {path.relative_to(ROOT)}')
        continue
    text = path.read_text(encoding='utf-8')
    for needle in needles:
        if needle not in text:
            missing.append(f'{path.relative_to(ROOT)} missing: {needle}')

# Basic guardrails: V17 should not add boss/save/sound systems.
for forbidden_path in [
    ROOT / 'scripts/iso/AshWardenBoss.gd',
    ROOT / 'scripts/iso/DemoSaveSystem.gd',
]:
    if forbidden_path.exists():
        missing.append(f'Unexpected out-of-scope file exists in patch target: {forbidden_path.relative_to(ROOT)}')

if missing:
    print('V17 validation FAILED:')
    for item in missing:
        print(' -', item)
    sys.exit(1)

print('V17 validation passed: room layout consistency files are present and scoped.')
