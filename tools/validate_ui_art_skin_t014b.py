#!/usr/bin/env python3
from pathlib import Path
import json
from PIL import Image
ROOT=Path.cwd()
required=['art/iso/ui/infernal_skin_v1/panels/ui_panel_reward_choice.png','art/iso/ui/infernal_skin_v1/panels/ui_panel_route_choice.png','art/iso/ui/infernal_skin_v1/panels/ui_panel_forge.png','art/iso/ui/infernal_skin_v1/panels/ui_panel_weapon_ascension.png','art/iso/ui/infernal_skin_v1/hud/ui_health_frame.png','art/iso/ui/infernal_skin_v1/hud/ui_judgment_meter_frame.png','art/iso/ui/infernal_skin_v1/hud/ui_boss_health_frame.png','art/iso/ui/infernal_skin_v1/trims/ui_rarity_common_trim.png','art/iso/ui/infernal_skin_v1/trims/ui_rarity_rare_trim.png','art/iso/ui/infernal_skin_v1/trims/ui_rarity_legendary_trim.png','art/iso/ui/infernal_skin_v1/icons/patron_azazel_icon.png','art/iso/ui/infernal_skin_v1/icons/patron_mammon_icon.png','art/iso/ui/infernal_skin_v1/icons/patron_minos_icon.png','scripts/iso/ui/InfernalUISkinV1.gd','data/ui/infernal_ui_skin_v1_manifest.json']
missing=[p for p in required if not (ROOT/p).exists()]
if missing: raise SystemExit('Missing T014B files:\n'+'\n'.join(missing))
for rel in required:
    if rel.endswith('.png'):
        img=Image.open(ROOT/rel)
        if img.mode!='RGBA': raise SystemExit(rel+' is not RGBA')
manifest=json.loads((ROOT/'data/ui/infernal_ui_skin_v1_manifest.json').read_text())
if len(manifest.get('assets',[])) < 25: raise SystemExit('manifest too small')
print('T014B UI art skin validation passed.')
