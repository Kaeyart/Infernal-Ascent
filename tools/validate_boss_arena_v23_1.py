#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
controller = root / "scripts/iso/IsoRoomLocalLoopController.gd"
placeholder = root / "scripts/iso/AshWardenBossPlaceholder.gd"

errors = []
for path in [controller, placeholder]:
    if not path.exists():
        errors.append(f"missing {path}")

if controller.exists():
    text = controller.read_text()
    required = [
        'preload("res://scripts/iso/AshWardenBossPlaceholder.gd")',
        'var _boss_placeholder: Node2D',
        'ASH_WARDEN_BOSS_PLACEHOLDER_SCRIPT.new()',
        'node.is_in_group("boss_placeholder")',
    ]
    for token in required:
        if token not in text:
            errors.append(f"missing controller token: {token}")
    forbidden = [
        'var _boss_placeholder: AshWardenBossPlaceholder',
        'var boss: AshWardenBossPlaceholder',
        'AshWardenBossPlaceholder.new()',
        'node is AshWardenBossPlaceholder',
    ]
    for token in forbidden:
        if token in text:
            errors.append(f"forbidden stale type reference remains: {token}")

if placeholder.exists():
    text = placeholder.read_text()
    for token in ['class_name AshWardenBossPlaceholder', 'add_to_group("boss_placeholder")', 'signal placeholder_defeated']:
        if token not in text:
            errors.append(f"missing placeholder token: {token}")

if errors:
    print("V23.1 validation failed:")
    for e in errors:
        print(" -", e)
    raise SystemExit(1)

print("V23.1 boss arena parser hotfix validation passed.")
