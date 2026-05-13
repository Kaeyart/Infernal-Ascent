#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import json

ROOT = Path.cwd()
CONTROLLER = ROOT / "scripts/iso/IsoRoomLocalLoopController.gd"
GATE = ROOT / "scripts/iso/RunChoiceGate.gd"
INTERACTABLE = ROOT / "scripts/iso/RunRoomInteractable.gd"
HUD = ROOT / "scripts/iso/Circle0RunHUD.gd"
TRACKER = ROOT / "data/production/demo_asset_tracker.json"


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing required file: {path}")
    return path.read_text()


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def replace_function(text: str, name: str, body: str, required: bool = True) -> str:
    pattern = re.compile(rf'\nfunc {re.escape(name)}\([^\n]*\) -> [^\n]+:\n(?:(?!\nfunc ).*\n)*', re.MULTILINE)
    m = pattern.search(text)
    if not m:
        if required:
            raise SystemExit(f"ERROR: Could not find function: {name}")
        return text
    return text[:m.start()] + "\n" + body.rstrip() + "\n" + text[m.end():]


def insert_before(text: str, anchor: str, block: str, label: str, required: bool = True) -> str:
    if block.strip() in text:
        return text
    if anchor not in text:
        if required:
            raise SystemExit(f"ERROR: Could not find anchor for {label}: {anchor!r}")
        return text
    return text.replace(anchor, "\n" + block.rstrip() + "\n" + anchor, 1)


def patch_controller() -> None:
    text = read(CONTROLLER)

    helpers = r'''
func _t014_pretty_id(raw_id: String) -> String:
	var clean: String = raw_id.strip_edges()
	if clean == "":
		return "None"
	clean = clean.replace("patron_", "").replace("forge_mark_", "").replace("weapon_ascension_", "")
	clean = clean.replace("_", " ")
	return clean.capitalize()

func _t014_build_status_summary() -> String:
	var forge_text: String = "None"
	if active_forge_mark.strip_edges() != "":
		forge_text = _t014_pretty_id(active_forge_mark)

	var ascension_text: String = "None"
	var ascension_value: Variant = get("weapon_ascension_id")
	if ascension_value != null and str(ascension_value).strip_edges() != "":
		ascension_text = _t014_pretty_id(str(ascension_value))

	var recent: Array[String] = []
	var start_index: int = maxi(0, reward_display_history.size() - 3)
	for i: int in range(start_index, reward_display_history.size()):
		recent.append(str(reward_display_history[i]))
	var boon_text: String = "None"
	if not recent.is_empty():
		boon_text = " | ".join(recent)

	return "BUILD: Boons: %s  ||  Forge: %s  ||  Weapon: %s  ||  Run Gold: %d" % [boon_text, forge_text, ascension_text, run_ash_shards]
'''
    text = insert_before(text, "\nfunc _update_hud() -> void:\n", helpers, "T-014 build status helpers", required=False)

    if '"build_status": _t014_build_status_summary(),' not in text and '"currency": "%s | Run Ash:' in text:
        text = text.replace(
            '\t\t"currency": "%s | Run Ash: %d | %s" % [RunEconomyData.get_currency_summary_line(), run_ash_shards, PERMANENT_UPGRADE_SCRIPT.build_summary_line()],\n',
            '\t\t"currency": "%s | Run Ash: %d | %s" % [RunEconomyData.get_currency_summary_line(), run_ash_shards, PERMANENT_UPGRADE_SCRIPT.build_summary_line()],\n\t\t"build_status": _t014_build_status_summary(),\n',
            1,
        )

    # Add readable description/body fields to patron and route reward gate helpers if they exist.
    text = text.replace(
        '\t\t"exact_effect": consequence,\n\t\t"prompt": "[E] Enter",\n',
        '\t\t"exact_effect": consequence,\n\t\t"description": consequence,\n\t\t"body": consequence,\n\t\t"prompt": "[E] Enter",\n'
    )

    # Improve fallback text HUD if the legacy label path is still used.
    if 'BUILD: " + _t014_build_status_summary()' not in text and 'hud_label.text = "Circle 0 - Demo Route' in text:
        text = text.replace(
            '\t\t"Route: " + _route_summary(),\n\t\tRunEconomyData.get_currency_summary_line()\n\t]\n',
            '\t\t"Route: " + _route_summary(),\n\t\tRunEconomyData.get_currency_summary_line() + "\\n" + _t014_build_status_summary()\n\t]\n',
            1,
        )

    # Mark tracker status if present.
    if TRACKER.exists():
        try:
            data = json.loads(TRACKER.read_text())
            def update_items(items):
                if isinstance(items, list):
                    for item in items:
                        if isinstance(item, dict) and item.get("id") in {"S-014", "T-014"}:
                            item["status"] = "In Progress"
            for value in data.values() if isinstance(data, dict) else []:
                update_items(value)
            TRACKER.write_text(json.dumps(data, indent=2) + "\n")
        except Exception:
            pass

    write(CONTROLLER, text)


def patch_gate() -> None:
    text = read(GATE)

    new_draw = r'''func _draw_minimal_label(display_name: String, icon: String, base_color: Color, pulse: float) -> void:
	# T-014: route gates must read as reward promises, not generic doors.
	var font: Font = ThemeDB.fallback_font
	var clean_name: String = display_name.to_upper()
	var consequence: String = str(choice_data.get("short_consequence", choice_data.get("exact_effect", choice_data.get("description", ""))))
	var compact_consequence: String = _t014_compact_text(consequence, 54)

	var rect_height: float = 24.0
	if _player_in_range and compact_consequence.strip_edges() != "":
		rect_height = 48.0
	var rect: Rect2 = Rect2(Vector2(-78.0, -154.0), Vector2(156.0, rect_height))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.84), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.62 + pulse * 0.12), false, 1.25)
	draw_string(font, Vector2(rect.position.x + 6.0, rect.position.y + 17.0), clean_name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 10, Color(1.0, 0.88, 0.64, 0.96))
	if _player_in_range and compact_consequence.strip_edges() != "":
		draw_string(font, Vector2(rect.position.x + 7.0, rect.position.y + 36.0), compact_consequence, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 14.0, 8, Color(0.80, 0.86, 0.78, 0.90))
	if show_focus_prompt and _player_in_range:
		_draw_focus_prompt(base_color, pulse)
'''
    text = replace_function(text, "_draw_minimal_label", new_draw, required=False)

    helper = r'''
func _t014_compact_text(value: String, max_len: int = 58) -> String:
	var clean: String = value.replace("\n", " ").strip_edges()
	if clean.length() <= max_len:
		return clean
	return clean.substr(0, maxi(0, max_len - 3)).strip_edges() + "..."
'''
    text = insert_before(text, "\nfunc _color_for_room_type(room_type: String) -> Color:\n", helper, "T-014 gate compact text", required=False)

    write(GATE, text)


def patch_interactable() -> None:
    text = read(INTERACTABLE)

    # Normalize payload kind so boon/ascension/forge cards draw with the correct treatment.
    if 'var reward_kind: String = str(payload.get("reward_kind", ""))' not in text:
        text = text.replace(
            'func setup(data: Dictionary, spawn_position: Vector2) -> void:\n\tpayload = data.duplicate(true)\n',
            'func setup(data: Dictionary, spawn_position: Vector2) -> void:\n\tpayload = data.duplicate(true)\n\tvar reward_kind: String = str(payload.get("reward_kind", ""))\n\tif not payload.has("kind") or str(payload.get("kind", "")).strip_edges() == "":\n\t\tif reward_kind == "boon" or reward_kind == "synergy_boon" or reward_kind == "weapon_ascension":\n\t\t\tpayload["kind"] = "reward"\n\t\telif reward_kind == "forge_mark":\n\t\t\tpayload["kind"] = "forge_mark"\n\t\telif reward_kind == "gold_payout" or reward_kind == "health_boost":\n\t\t\tpayload["kind"] = "reward"\n',
            1,
        )

    new_prompt = r'''func _draw_prompt(title: String, base_color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var kind: String = str(payload.get("kind", "object"))
	if kind == "boss_antechamber" or kind == "boss_exit":
		_draw_boss_gate_name(title, base_color)
		return

	var has_meta: bool = kind == "reward" or kind == "forge_mark" or kind == "shop_item"
	var effect_text: String = _t014_payload_effect_text()
	var has_effect: bool = effect_text.strip_edges() != ""
	var rect_height: float = 48.0
	if has_meta:
		rect_height = 64.0
	if has_effect:
		rect_height += 22.0
	var rect: Rect2 = Rect2(Vector2(-132.0, 30.0), Vector2(264.0, rect_height))
	draw_rect(rect, Color(0.018, 0.013, 0.010, 0.90), true)
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.82), false, 1.5)
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 16.0), title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color(1.0, 0.90, 0.68, 1.0))

	var y: float = rect.position.y + 34.0
	if has_meta:
		var meta: String = "%s · %s" % [str(payload.get("rarity", "common")).to_upper(), str(payload.get("category", "Boon")).to_upper()]
		if kind == "shop_item":
			meta = "COST %d RUN GOLD" % int(payload.get("cost", 0))
		draw_string(font, Vector2(rect.position.x + 8.0, y), meta, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 10, Color(0.80, 0.72, 0.58, 0.96))
		y += 16.0

	if has_effect:
		draw_string(font, Vector2(rect.position.x + 10.0, y), _t014_compact_text(effect_text, 84), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 9, Color(0.78, 0.86, 0.76, 0.96))
		y += 20.0

	var prompt: String = _prompt_text_for_kind(kind)
	if _used:
		prompt = "USED"
	elif not _player_in_range:
		prompt = "APPROACH"
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y - 8.0), prompt, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color(0.72, 0.94, 1.0, 1.0 if _player_in_range else 0.68))
'''
    text = replace_function(text, "_draw_prompt", new_prompt, required=False)

    helpers = r'''
func _t014_payload_effect_text() -> String:
	var keys: Array[String] = ["exact_effect", "description", "body", "short_consequence", "current_consequence"]
	for key: String in keys:
		var value: String = str(payload.get(key, "")).strip_edges()
		if value != "":
			return value
	return ""

func _t014_compact_text(value: String, max_len: int = 86) -> String:
	var clean: String = value.replace("\n", " ").strip_edges()
	if clean.length() <= max_len:
		return clean
	return clean.substr(0, maxi(0, max_len - 3)).strip_edges() + "..."
'''
    text = insert_before(text, "\nfunc _prompt_text_for_kind(kind: String) -> String:\n", helpers, "T-014 interactable text helpers", required=False)

    write(INTERACTABLE, text)


def patch_hud() -> None:
    if not HUD.exists():
        return
    text = read(HUD)

    if 'var build_status: String = str(data.get("build_status", ""))' not in text and 'var currency: String = str(data.get("currency", ""))' in text:
        text = text.replace(
            'var currency: String = str(data.get("currency", ""))\n',
            'var currency: String = str(data.get("currency", ""))\n\tvar build_status: String = str(data.get("build_status", ""))\n',
            1,
        )

    if 'build_status' in text and 'BUILD:' not in text:
        # Older HUD route label line. Add build status if possible.
        text = text.replace(
            '\t_route_label.text = "PHASE: %s\\nROUTE: %s\\nREWARDS: %s  |  FOUNTAINS: %d  |  BONUS SIGILS: %d\\n%s" % [phase, str(data.get("route", "start")), str(rewards), fountains, bonus_sigils, currency]\n',
            '\t_route_label.text = "PHASE: %s\\nROUTE: %s\\nREWARDS: %s  |  FOUNTAINS: %d  |  BONUS SIGILS: %d\\n%s\\n%s" % [phase, str(data.get("route", "start")), str(rewards), fountains, bonus_sigils, currency, build_status]\n',
            1,
        )

    # Choice cards should prefer exact effects / consequences, not blank descriptions.
    text = text.replace(
        'var description: String = str(choice.get("description", ""))',
        'var description: String = str(choice.get("description", choice.get("exact_effect", choice.get("short_consequence", choice.get("current_consequence", "")))))'
    )
    text = text.replace(
        'label.text = "%d. [%s] %s\n%s\n%s" % [i + 1, icon, display_name, rarity, description]',
        'label.text = "%d. [%s] %s\n%s\n%s" % [i + 1, icon, display_name, rarity, _t014_compact_text(description, 72)]'
    )

    helper = r'''
func _t014_compact_text(value: String, max_len: int = 72) -> String:
	var clean: String = value.replace("\n", " ").strip_edges()
	if clean.length() <= max_len:
		return clean
	return clean.substr(0, maxi(0, max_len - 3)).strip_edges() + "..."
'''
    text = insert_before(text, "\nfunc _build_ui() -> void:\n", helper, "T-014 HUD compact text", required=False)

    write(HUD, text)


def main() -> None:
    patch_controller()
    patch_gate()
    patch_interactable()
    patch_hud()
    print("Applied T-014 Choice UI + Build Status Presentation Pass.")


if __name__ == "__main__":
    main()
