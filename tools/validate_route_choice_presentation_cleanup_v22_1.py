#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
checks = [
    (root / 'scripts/iso/IsoRoomLocalLoopController.gd', [
        'show_route_debug_labels: bool = false',
        'hide_live_authoring_overlays',
        'bottom route cards match left, center, and right',
    ]),
    (root / 'scripts/iso/RunChoiceGate.gd', [
        'show_world_gate_label: bool = false',
        'show_focus_prompt: bool = true',
        'func _draw_focus_prompt',
    ]),
    (root / 'scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd', [
        'hide_authoring_markers_in_play: bool = true',
        'hide_legacy_patron_flow_visuals: bool = true',
        'func hide_live_authoring_overlays',
        'func _hide_patron_flow_visuals',
        'func _clamp_to_demo_floor',
    ]),
    (root / 'scripts/iso/IsoRoomSetDressing.gd', [
        'show_layout_readability_marks: bool = false',
        'V22.1: route choice should be quiet',
        '_draw_gate_socket(Vector2(-168.0, -70.0)',
    ]),
]

errors = []
for path, needles in checks:
    if not path.exists():
        errors.append(f'Missing {path.relative_to(root)}')
        continue
    text = path.read_text()
    for needle in needles:
        if needle not in text:
            errors.append(f'{path.relative_to(root)} missing: {needle}')

if errors:
    print('V22.1 validation failed:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('V22.1 route-choice presentation cleanup validation passed.')
