#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
required = [
    'scripts/iso/IsoRoomLocalLoopController.gd',
    'scripts/iso/AshWardenBoss.gd',
    'docs/ASH_WARDEN_BOSS_V1.md',
]
missing = [p for p in required if not (ROOT / p).exists()]
if missing:
    print('ERROR: missing files:')
    for path in missing:
        print('  -', path)
    sys.exit(1)
controller = (ROOT / 'scripts/iso/IsoRoomLocalLoopController.gd').read_text(encoding='utf-8')
boss = (ROOT / 'scripts/iso/AshWardenBoss.gd').read_text(encoding='utf-8')
checks = {
    'controller has BOSS phase': 'BOSS,' in controller and 'return "BOSS"' in controller,
    'controller loads AshWardenBoss at runtime': 'ash_warden_boss_script_path' in controller and 'load(ash_warden_boss_script_path)' in controller,
    'controller spawns Ash Warden boss': '_spawn_ash_warden_boss' in controller,
    'controller handles Ash Warden defeat': '_on_ash_warden_defeated' in controller,
    'controller handles player death': '_on_player_died' in controller,
    'boss receives player hit': 'func receive_player_hit' in boss,
    'boss has phase thresholds': 'phase_two_ratio' in boss and 'phase_three_ratio' in boss,
    'boss has furnace seal stagger': 'Furnace Seal Stagger' in boss or '_check_furnace_seal_stagger' in boss,
    'boss has final verdict': 'final_verdict' in boss,
    'boss can summon adds': '_spawn_summons' in boss,
    'boss emits defeated': 'emit_signal("defeated")' in boss,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print('ERROR: V24 validation failed:')
    for name in failed:
        print('  -', name)
    sys.exit(1)
print('V24 Ash Warden Boss validation passed.')
