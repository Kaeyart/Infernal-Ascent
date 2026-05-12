#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    'scripts/iso/ui/InfernalUIRoot.gd',
    'scripts/iso/Circle0RunHUD.gd',
    'scripts/iso/IsoRoomLocalLoopController.gd',
    'scripts/iso/RunChoiceGate.gd',
    'scripts/iso/RunRoomInteractable.gd',
    'scripts/iso/IsoRoomHazard.gd',
    'docs/INFERNAL_UI_FRAMEWORK_V1.md',
]
missing = [p for p in required if not (ROOT / p).exists()]
if missing:
    print('Missing V13 files:')
    for p in missing:
        print(' -', p)
    sys.exit(1)

checks = {
    'scripts/iso/ui/InfernalUIRoot.gd': [
        'class_name InfernalUIRoot',
        'extends CanvasLayer',
        'func update_from_run_state',
        'func set_focus_payload',
        'RouteChoiceOverlay',
        'RunSummaryPanel',
    ],
    'scripts/iso/Circle0RunHUD.gd': [
        'extends "res://scripts/iso/ui/InfernalUIRoot.gd"',
        'class_name Circle0RunHUD',
    ],
    'scripts/iso/IsoRoomLocalLoopController.gd': [
        '_player_ui_state()',
        '_on_interactable_focus_changed',
        'set_focus_payload',
        'show_room_intro',
    ],
    'scripts/iso/RunRoomInteractable.gd': [
        'signal focus_changed',
        'emit_signal("focus_changed"',
    ],
    'scripts/iso/IsoRoomHazard.gd': [
        'Warning -> Armed -> Active',
        'draw_text_markers',
    ],
}
failed = []
for rel, needles in checks.items():
    text = (ROOT / rel).read_text(encoding='utf-8')
    for needle in needles:
        if needle not in text:
            failed.append(f'{rel}: missing {needle}')
if failed:
    print('V13 validation failed:')
    for f in failed:
        print(' -', f)
    sys.exit(1)
print('V13 Infernal UI Framework files are present and wired.')
print('Open Godot and test: hub no run HUD, run HUD in combat, route cards only in route choice, reward inspect panel on pedestal focus, and visible hazard warning rings.')
