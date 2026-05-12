#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path.cwd()
controller = ROOT / 'scripts' / 'iso' / 'IsoRoomLocalLoopController.gd'
placeholder = ROOT / 'scripts' / 'iso' / 'AshWardenBossPlaceholder.gd'
errors = []

if not controller.exists():
    errors.append('missing scripts/iso/IsoRoomLocalLoopController.gd')
else:
    text = controller.read_text(encoding='utf-8')
    if re.search(r'^\s*class_name\s+IsoRoomLocalLoopController\s*$', text, re.MULTILINE):
        errors.append('IsoRoomLocalLoopController.gd still contains class_name IsoRoomLocalLoopController')
    if 'AshWardenBossPlaceholder' in text and 'AshWardenBossPlaceholder.gd' not in text:
        errors.append('IsoRoomLocalLoopController.gd still references AshWardenBossPlaceholder type name without preload path')
    if 'AshWardenBossPlaceholder.gd' not in text:
        errors.append('IsoRoomLocalLoopController.gd does not reference/preload AshWardenBossPlaceholder.gd')

if not placeholder.exists():
    errors.append('missing scripts/iso/AshWardenBossPlaceholder.gd')
else:
    ptext = placeholder.read_text(encoding='utf-8')
    if re.search(r'^\s*class_name\s+AshWardenBossPlaceholder\s*$', ptext, re.MULTILINE):
        errors.append('AshWardenBossPlaceholder.gd still contains class_name AshWardenBossPlaceholder; not needed for preload-based use')

if errors:
    print('V23.2 validation FAILED:')
    for e in errors:
        print(f'  - {e}')
    sys.exit(1)

print('V23.2 validation OK: boss arena parser class_name issue is sanitized.')
