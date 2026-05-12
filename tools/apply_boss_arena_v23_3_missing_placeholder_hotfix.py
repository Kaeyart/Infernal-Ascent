#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path.cwd()
controller = ROOT / 'scripts' / 'iso' / 'IsoRoomLocalLoopController.gd'
placeholder = ROOT / 'scripts' / 'iso' / 'AshWardenBossPlaceholder.gd'

if not controller.exists():
    print(f'ERROR: missing {controller}')
    sys.exit(1)

text = controller.read_text(encoding='utf-8')
original = text

# V23.3: remove the fragile external preload. Some project states failed to resolve
# res://scripts/iso/AshWardenBossPlaceholder.gd during parse. The arena placeholder now
# uses the existing RunRoomInteractable path so V23 remains presentation-only and parser-safe.
text = re.sub(r'^\s*const\s+ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT\s*:[^\n]*\n', '', text, flags=re.MULTILINE)
text = re.sub(r'^\s*class_name\s+IsoRoomLocalLoopController\s*\n', '', text, flags=re.MULTILINE)
text = text.replace(': AshWardenBossPlaceholder', ': Node2D')
text = text.replace(' as AshWardenBossPlaceholder', ' as Node2D')
text = text.replace('is AshWardenBossPlaceholder', 'is Node2D')

new_spawn = '''func _spawn_boss_placeholder() -> void:\n\t_clear_boss_placeholder_nodes()\n\tvar data: Dictionary = {\n\t\t"kind": "boss_placeholder",\n\t\t"display_name": "Ash Warden Seal",\n\t\t"description": "A chained furnace seal holds the Ash Warden in place until V24 replaces this placeholder with the real boss fight.",\n\t\t"exact_effect": "Press E to break the placeholder seal and open the victory exit.",\n\t\t"current_consequence": "V23 is arena-only. V24 implements the real Ash Warden AI and damage phases.",\n\t\t"icon": "W",\n\t}\n\tvar boss: RunRoomInteractable = RunRoomInteractable.new()\n\tboss.name = "AshWardenBossPlaceholder"\n\tboss.add_to_group("boss_placeholder")\n\t_get_runtime_parent().add_child(boss)\n\tboss.setup(data, _get_boss_spawn_position())\n\tboss.activated.connect(_on_boss_placeholder_interactable_used)\n\tif boss.has_signal("focus_changed"):\n\t\tboss.focus_changed.connect(_on_interactable_focus_changed)\n\t_active_interactables.append(boss)\n\t_boss_placeholder = boss\n\n'''

# Replace entire _spawn_boss_placeholder body up to the next boss-defeated handler.
pattern = r'func\s+_spawn_boss_placeholder\s*\(\)\s*->\s*void:\n.*?(?=func\s+_on_boss_placeholder_defeated\s*\()'
text, count = re.subn(pattern, new_spawn, text, flags=re.DOTALL)
if count != 1:
    print('ERROR: could not replace _spawn_boss_placeholder() cleanly. No changes written.')
    sys.exit(1)

if 'func _on_boss_placeholder_interactable_used' not in text:
    insert = '''func _on_boss_placeholder_interactable_used(_payload: Dictionary) -> void:\n\t_on_boss_placeholder_defeated()\n\n'''
    text = text.replace('func _on_boss_placeholder_defeated() -> void:\n', insert + 'func _on_boss_placeholder_defeated() -> void:\n')

# Keep cleanup generic and group-based. No external placeholder class references should remain.
text = text.replace('ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT', '')
text = text.replace('AshWardenBossPlaceholder.gd', '')

if text != original:
    controller.write_text(text, encoding='utf-8')
    print('V23.3 missing-placeholder hotfix applied:')
    print('  - scripts/iso/IsoRoomLocalLoopController.gd')
else:
    print('V23.3 missing-placeholder hotfix: no controller changes needed.')

# Ensure the file exists only as a harmless fallback for older references/docs. It is not preloaded by the controller.
placeholder.parent.mkdir(parents=True, exist_ok=True)
if not placeholder.exists():
    placeholder.write_text('''extends Node2D\n\n## V23.3 fallback file. The boss arena placeholder is currently implemented through RunRoomInteractable.\n## This file remains only to avoid missing-file confusion if an older local reference exists.\n\nfunc setup(spawn_position: Vector2) -> void:\n\tglobal_position = spawn_position\n''', encoding='utf-8')
    print('  - scripts/iso/AshWardenBossPlaceholder.gd fallback created')
