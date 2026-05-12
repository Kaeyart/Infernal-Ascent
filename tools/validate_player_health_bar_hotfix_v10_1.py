#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path('scripts/iso/IsoPhysicsTestPlayer.gd')
if not path.exists():
    print('[V10.1] Missing scripts/iso/IsoPhysicsTestPlayer.gd')
    sys.exit(1)
text = path.read_text()
required = [
    'func _draw_player_health_bar() -> void:',
    'if show_player_health_bar:',
    '_draw_player_health_bar()',
    'var health_ratio: float = clampf',
]
missing = [item for item in required if item not in text]
if missing:
    print('[V10.1] Missing required health bar hotfix markers:')
    for item in missing:
        print(' -', item)
    sys.exit(1)

if text.count('func _draw_player_health_bar() -> void:') != 1:
    print('[V10.1] Duplicate _draw_player_health_bar definitions found.')
    sys.exit(1)

print('[V10.1] OK: player health bar parser hotfix is installed.')
