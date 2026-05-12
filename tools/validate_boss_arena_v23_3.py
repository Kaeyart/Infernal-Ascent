#!/usr/bin/env python3
from pathlib import Path
import sys
root = Path.cwd()
controller = root / 'scripts' / 'iso' / 'IsoRoomLocalLoopController.gd'
if not controller.exists():
    print('ERROR: missing scripts/iso/IsoRoomLocalLoopController.gd')
    sys.exit(1)
text = controller.read_text(encoding='utf-8')
errors = []
if 'preload("res://scripts/iso/AshWardenBossPlaceholder.gd")' in text or "preload('res://scripts/iso/AshWardenBossPlaceholder.gd')" in text:
    errors.append('controller still preloads AshWardenBossPlaceholder.gd')
if 'ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT' in text:
    errors.append('controller still references ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT')
if 'class_name IsoRoomLocalLoopController' in text:
    errors.append('controller still contains class_name IsoRoomLocalLoopController')
required = [
    'func _spawn_boss_placeholder() -> void:',
    'RunRoomInteractable.new()',
    'func _on_boss_placeholder_interactable_used(_payload: Dictionary) -> void:',
    'func _on_boss_placeholder_defeated() -> void:',
    'func _spawn_boss_victory_exit() -> void:',
]
for item in required:
    if item not in text:
        errors.append(f'missing required controller content: {item}')
if errors:
    print('V23.3 validation failed:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('V23.3 validation passed: boss arena placeholder no longer depends on a fragile external preload.')
