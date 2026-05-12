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
    'scripts/iso/IsoRoomLocalLoopController.gd': ['_get_boss_gate_position', 'gate.show_world_gate_label = true'],
    'scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd': ['strip_authoring_overlay_text_in_play', 'boss_antechamber', '_clear_existing_hazards()'],
    'scripts/iso/RunChoiceGate.gd': ['show_world_gate_label: bool = true', 'V22.2: keep the door name above the door'],
    'scripts/iso/RunRoomInteractable.gd': ['_draw_sealed_gate', '_draw_boss_gate_name'],
    'scripts/iso/IsoRoomSetDressing.gd': ['_draw_minimal_runtime_shadow', '_draw_boss_antechamber_placeholder'],
}
for file, needles in checks.items():
    text = Path(file).read_text(encoding='utf-8')
    for needle in needles:
        if needle not in text:
            raise SystemExit(f'{file} missing expected marker: {needle}')
print('V22.2 route-choice/boss placeholder presentation cleanup validation passed.')
