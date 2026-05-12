#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    'scripts/iso/IsoRoomLocalLoopController.gd',
    'docs/RUN_FLOW_CONSISTENCY_PASS_V14.md',
]
missing = [p for p in required if not (ROOT / p).exists()]
if missing:
    print('Missing V14 files:')
    for p in missing:
        print(' -', p)
    sys.exit(1)

controller = (ROOT / 'scripts/iso/IsoRoomLocalLoopController.gd').read_text(encoding='utf-8')
needles = [
    'enum RunPhase',
    'HUB',
    'RUN_START',
    'ROOM_INTRO',
    'COMBAT',
    'ROOM_CLEAR',
    'ROUTE_CHOICE',
    'REWARD',
    'FOUNTAIN',
    'SHOP',
    'FORGE',
    'BOSS_LOCKED_PLACEHOLDER',
    'RUN_VICTORY',
    'RUN_DEATH',
    'RETURN_TO_HUB',
    'func _set_phase',
    'func _phase_label',
    'func _phase_can_complete_room',
    'func _schedule_route_choice_spawn',
    'func _spawn_choice_gates_deferred(expected_phase_serial: int)',
    'Cancelled stale route-choice spawn request',
    'Ignored gate choice outside ROUTE_CHOICE phase',
    'current_phase != RunPhase.REWARD',
    'current_phase != RunPhase.FOUNTAIN',
    'current_phase != RunPhase.FORGE',
    'current_phase != RunPhase.SHOP',
]
failed = [n for n in needles if n not in controller]
if failed:
    print('V14 validation failed. Missing expected state-machine markers:')
    for n in failed:
        print(' -', n)
    sys.exit(1)

for forbidden in ['new enemy', 'Ash Warden Boss V1', 'Permanent Upgrade V1']:
    if forbidden in controller:
        print(f'V14 scope warning: found forbidden content marker: {forbidden}')
        sys.exit(1)

print('V14 Run Flow Consistency files are present.')
print('Open Godot and test: hub -> Hell Gate -> combat -> route choice -> reward/fountain/shop/forge -> route choice -> run complete -> E return to hub.')
