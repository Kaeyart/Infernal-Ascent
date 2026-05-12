#!/usr/bin/env python3
from pathlib import Path
required = [
    Path('scripts/iso/IsoRoomLocalLoopController.gd'),
    Path('scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd'),
    Path('scripts/iso/RunChoiceGate.gd'),
    Path('scripts/iso/RunRoomInteractable.gd'),
    Path('scripts/iso/IsoRoomSetDressing.gd'),
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    raise SystemExit('Missing files: ' + ', '.join(missing))
checks = {
    'scripts/iso/IsoRoomLocalLoopController.gd': [
        'func _get_boss_gate_position() -> Vector2:',
        'runtime_adapter.has_method("get_boss_gate_position")',
        '_spawn_single_interactable(data, _get_boss_gate_position()',
    ],
    'scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd': [
        'func get_boss_gate_position() -> Vector2:',
        '_clamp_to_demo_floor(origin + Vector2(0.0, -82.0))',
        'BossGate',
    ],
    'scripts/iso/RunChoiceGate.gd': ['show_world_gate_label: bool = true'],
    'scripts/iso/RunRoomInteractable.gd': ['_draw_sealed_gate', '_draw_boss_gate_name'],
}
for file, needles in checks.items():
    text = Path(file).read_text(encoding='utf-8')
    for needle in needles:
        if needle not in text:
            raise SystemExit(f'{file} missing expected marker: {needle}')
print('V22.3 boss gate parser hotfix validation passed.')
