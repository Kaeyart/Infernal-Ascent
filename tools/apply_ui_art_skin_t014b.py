#!/usr/bin/env python3
from pathlib import Path
import json
ROOT = Path.cwd()

def patch_run_choice_gate():
    path = ROOT / 'scripts/iso/RunChoiceGate.gd'
    if not path.exists():
        print('[T014B] RunChoiceGate.gd missing; skipped.')
        return
    text = path.read_text()
    changed = False
    preload = 'const UI_SKIN_SCRIPT: Script = preload("res://scripts/iso/ui/InfernalUISkinV1.gd")\n'
    if preload not in text:
        text = text.replace('class_name RunChoiceGate\n', 'class_name RunChoiceGate\n\n' + preload)
        changed = True
    helper = """
func _draw_skin_panel_texture(rect: Rect2, kind: String = "route", alpha: float = 0.92) -> bool:
	if UI_SKIN_SCRIPT == null:
		return false
	var texture: Texture2D = UI_SKIN_SCRIPT.panel_texture(kind)
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
	return true
"""
    if 'func _draw_skin_panel_texture' not in text:
        text = text.replace('\nfunc _draw_minimal_label', helper + '\nfunc _draw_minimal_label')
        changed = True
    old = '\tdraw_rect(rect, Color(0.018, 0.013, 0.010, 0.82), true)\n\tdraw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.62 + pulse * 0.12), false, 1.25)'
    new = '\tvar skinned_rect: Rect2 = rect.grow(8.0)\n\tif not _draw_skin_panel_texture(skinned_rect, "route", 0.88):\n\t\tdraw_rect(rect, Color(0.018, 0.013, 0.010, 0.82), true)\n\t\tdraw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.62 + pulse * 0.12), false, 1.25)'
    if old in text and 'var skinned_rect: Rect2 = rect.grow(8.0)' not in text:
        text = text.replace(old, new)
        changed = True
    if changed:
        path.write_text(text)
        print('[T014B] Patched RunChoiceGate.gd.')
    else:
        print('[T014B] RunChoiceGate.gd already patched or pattern not found.')

def patch_interactable():
    path = ROOT / 'scripts/iso/RunRoomInteractable.gd'
    if not path.exists():
        print('[T014B] RunRoomInteractable.gd missing; skipped.')
        return
    text = path.read_text()
    changed = False
    preload = 'const UI_SKIN_SCRIPT: Script = preload("res://scripts/iso/ui/InfernalUISkinV1.gd")\n'
    if preload not in text:
        text = text.replace('class_name RunRoomInteractable\n', 'class_name RunRoomInteractable\n\n' + preload)
        changed = True
    helper = """
func _t014b_get_choice_panel_texture() -> Texture2D:
	if UI_SKIN_SCRIPT == null:
		return null
	return UI_SKIN_SCRIPT.panel_texture("reward")
"""
    if 'func _t014b_get_choice_panel_texture' not in text:
        if '\nfunc _draw' in text:
            text = text.replace('\nfunc _draw', helper + '\nfunc _draw')
        else:
            text += '\n' + helper
        changed = True
    if changed:
        path.write_text(text)
        print('[T014B] Patched RunRoomInteractable.gd.')
    else:
        print('[T014B] RunRoomInteractable.gd already patched.')

def update_tracker():
    path = ROOT / 'data/production/demo_asset_tracker.json'
    if not path.exists(): return
    try: data = json.loads(path.read_text())
    except Exception: return
    def visit(o):
        if isinstance(o, dict):
            val = (str(o.get('asset','')) + ' ' + str(o.get('id',''))).lower()
            if 'ui_' in val and o.get('status') == 'Missing':
                o['status'] = 'Placeholder'
                o['notes'] = 'T-014B UI skin placeholder generated.'
            for v in o.values(): visit(v)
        elif isinstance(o, list):
            for v in o: visit(v)
    visit(data)
    path.write_text(json.dumps(data, indent=2))
    print('[T014B] Updated tracker UI placeholders.')

def main():
    required = [ROOT/'art/iso/ui/infernal_skin_v1/panels/ui_panel_reward_choice.png', ROOT/'scripts/iso/ui/InfernalUISkinV1.gd', ROOT/'data/ui/infernal_ui_skin_v1_manifest.json']
    missing = [str(p) for p in required if not p.exists()]
    if missing: raise SystemExit('Missing expected T014B files:\n' + '\n'.join(missing))
    patch_run_choice_gate()
    patch_interactable()
    update_tracker()
    print('[T014B] Apply complete.')
if __name__ == '__main__': main()
