#!/usr/bin/env python3
from pathlib import Path
import sys
root = Path.cwd()
required = [
    root / 'scripts/iso/AshWardenBoss.gd',
    root / 'scripts/iso/IsoRoomLocalLoopController.gd',
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    print('Missing files:')
    print('\n'.join(missing))
    sys.exit(1)
errors = []
for p in required:
    txt = p.read_text(encoding='utf-8')
    if 'Array[Node] = get_tree().get_nodes_in_group("player")' in txt:
        errors.append(f'{p}: still contains typed get_nodes_in_group assignment')
    if 'get_tree().get_nodes_in_group("player")' not in txt:
        errors.append(f'{p}: expected player group lookup not found')
if errors:
    print('V24.1 validation failed:')
    print('\n'.join(errors))
    sys.exit(1)
print('V24.1 validation passed: player group lookups use untyped Array assignments compatible with Godot parsing.')
