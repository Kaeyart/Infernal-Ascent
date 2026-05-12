#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path.cwd()
controller = ROOT / 'scripts' / 'iso' / 'IsoRoomLocalLoopController.gd'
placeholder = ROOT / 'scripts' / 'iso' / 'AshWardenBossPlaceholder.gd'

changed = []

if not controller.exists():
    print(f'ERROR: missing {controller}')
    sys.exit(1)

text = controller.read_text(encoding='utf-8')
original = text

# Godot parser fix: the controller must not declare class_name inside/after its class body.
text = re.sub(r'^\s*class_name\s+IsoRoomLocalLoopController\s*\n', '', text, flags=re.MULTILINE)

# Remove any remaining static references to the boss placeholder class from the controller.
# The controller should use preload/create + group cleanup, not a globally resolved class name.
text = text.replace(': AshWardenBossPlaceholder', ': Node2D')
text = text.replace(' as AshWardenBossPlaceholder', ' as Node2D')
text = text.replace('is AshWardenBossPlaceholder', 'is Node2D')

# Ensure there is a preload for the placeholder if the script instantiates it.
if 'AshWardenBossPlaceholder.gd' in text and 'preload("res://scripts/iso/AshWardenBossPlaceholder.gd")' not in text and "preload('res://scripts/iso/AshWardenBossPlaceholder.gd')" not in text:
    lines = text.splitlines()
    insert_at = 0
    # Keep extends at very top if present, then insert constants after it.
    for i, line in enumerate(lines[:20]):
        if line.strip().startswith('extends '):
            insert_at = i + 1
            break
    lines.insert(insert_at, 'const ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT: Script = preload("res://scripts/iso/AshWardenBossPlaceholder.gd")')
    text = '\n'.join(lines) + ('\n' if original.endswith('\n') else '')

if text != original:
    controller.write_text(text, encoding='utf-8')
    changed.append(str(controller.relative_to(ROOT)))

# Optional cleanup: class_name on the placeholder is not required because the controller preloads the script.
# Leave the script otherwise untouched.
if placeholder.exists():
    ptext = placeholder.read_text(encoding='utf-8')
    poriginal = ptext
    ptext = re.sub(r'^\s*class_name\s+AshWardenBossPlaceholder\s*\n', '', ptext, flags=re.MULTILINE)
    if ptext != poriginal:
        placeholder.write_text(ptext, encoding='utf-8')
        changed.append(str(placeholder.relative_to(ROOT)))

if changed:
    print('V23.2 parser hotfix applied:')
    for item in changed:
        print(f'  - {item}')
else:
    print('V23.2 parser hotfix: no changes needed; files already sanitized.')
