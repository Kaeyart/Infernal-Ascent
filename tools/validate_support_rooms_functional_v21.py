#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
files = [
    ROOT / 'scripts/iso/IsoRoomLocalLoopController.gd',
    ROOT / 'scripts/iso/RunRoomInteractable.gd',
    ROOT / 'scripts/iso/ui/InfernalUIRoot.gd',
    ROOT / 'docs/SUPPORT_ROOMS_FUNCTIONAL_PASS_V21.md',
]
missing = [str(p) for p in files if not p.exists()]
if missing:
    raise SystemExit('Missing V21 files:\n' + '\n'.join(missing))

controller = files[0].read_text(encoding='utf-8')
interactable = files[1].read_text(encoding='utf-8')
ui = files[2].read_text(encoding='utf-8')

required_controller_terms = [
    'V21 — Fountain / Shop / Forge Functional Pass',
    '@export_category("V21 Support Rooms")',
    'fountain_heal_ratio_v21',
    'starting_run_ash',
    'run_ash_shards',
    'func _spawn_forge_marks()',
    'func _forge_mark_catalogue()',
    'Serrated Edge',
    'Grave Weight',
    'Ash Step',
    'func _spawn_shop_items()',
    'func _shop_catalogue()',
    'Blood Poultice',
    "Pilgrim's Edge",
    'Sealed Boon',
    'func _on_shop_item_bought',
    'Run Ash',
    'Recorded V21 run results',
]
for term in required_controller_terms:
    if term not in controller:
        raise SystemExit(f'Controller missing V21 term: {term}')

for bad in [
    'Forge room placeholder. Use the cold forge',
    'Shop room placeholder. Use the merchant marker',
    'Forge mechanics are reserved for V21',
    'Shop economy is reserved for V21',
]:
    if bad in controller + ui:
        raise SystemExit(f'V21 still contains placeholder wording: {bad}')

for term in ['forge_mark', 'shop_item', '[E] FORGE', '[E] BUY']:
    if term not in interactable:
        raise SystemExit(f'Interactable missing V21 support kind/prompt: {term}')

for term in ['forge_mark', 'shop_item', 'Forge this mark', 'Buy this item']:
    if term not in ui:
        raise SystemExit(f'UI missing V21 support panel term: {term}')

print('V21 support rooms functional validation passed.')
