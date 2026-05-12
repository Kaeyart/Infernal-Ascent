#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path.cwd()

FILES = {
    "player": ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd",
    "enemy": ROOT / "scripts/iso/IsoTestEnemy.gd",
    "boss": ROOT / "scripts/iso/AshWardenBoss.gd",
    "hazard": ROOT / "scripts/iso/IsoRoomHazard.gd",
    "loop": ROOT / "scripts/iso/IsoRoomLocalLoopController.gd",
}


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"Missing required file: {path}")
    return path.read_text(encoding="utf-8")


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def replace_export(text: str, name: str, value: str, expected_type: str | None = None) -> str:
    type_part = expected_type if expected_type else r"(?:int|float|bool|String|Vector2|Array\[String\])"
    pattern = rf"(@export(?:_[^\n ]+)?(?:\([^\n]*\))?\s+var\s+{re.escape(name)}\s*:\s*{type_part}\s*=\s*)([^\n]+)"
    new_text, count = re.subn(pattern, rf"\g<1>{value}", text, count=1)
    if count == 0:
        raise SystemExit(f"Could not patch exported variable '{name}'.")
    return new_text


def replace_in_block(text: str, marker: str, name: str, value: str) -> str:
    start = text.find(marker)
    if start == -1:
        raise SystemExit(f"Could not find marker block: {marker}")
    end = text.find("\n\treturn", start)
    if end == -1:
        end = text.find("\n\tenemy_type = \"ash_grunt\"", start)
    if end == -1:
        raise SystemExit(f"Could not determine end for block: {marker}")
    block = text[start:end]
    pattern = rf"(\n\t\t{name}\s*=\s*)([^\n]+)"
    new_block, count = re.subn(pattern, rf"\g<1>{value}", block, count=1)
    if count == 0:
        raise SystemExit(f"Could not patch '{name}' in block '{marker}'.")
    return text[:start] + new_block + text[end:]


def replace_after_marker(text: str, marker: str, name: str, value: str) -> str:
    start = text.find(marker)
    if start == -1:
        raise SystemExit(f"Could not find marker: {marker}")
    tail = text[start:]
    pattern = rf"(\n\t{name}\s*=\s*)([^\n]+)"
    new_tail, count = re.subn(pattern, rf"\g<1>{value}", tail, count=1)
    if count == 0:
        raise SystemExit(f"Could not patch '{name}' after marker '{marker}'.")
    return text[:start] + new_tail


def replace_first(text: str, old: str, new: str) -> str:
    if old not in text:
        raise SystemExit(f"Expected text not found: {old}")
    return text.replace(old, new, 1)


def patch_player() -> None:
    path = FILES["player"]
    text = read(path)
    # V33 target: fairer early run without changing player identity or art.
    text = replace_export(text, "max_health", "7", "int")
    text = replace_export(text, "attack_radius", "86.0", "float")
    text = replace_export(text, "heavy_attack_radius_multiplier", "1.18", "float")
    text = replace_export(text, "contact_damage_iframe_duration", "0.68", "float")
    text = replace_export(text, "enemy_hit_knockback_duration", "0.12", "float")
    text = replace_export(text, "dash_cooldown", "0.46", "float")
    text = replace_export(text, "light_attack_arc_degrees", "122.0", "float")
    text = replace_export(text, "heavy_attack_arc_degrees", "152.0", "float")
    text = replace_export(text, "attack_movement_multiplier", "0.66", "float")
    text = replace_export(text, "heavy_attack_movement_multiplier", "0.42", "float")
    write(path, text)


def patch_enemy() -> None:
    path = FILES["enemy"]
    text = read(path)
    text = replace_first(text, "if wave_index >= 3:", "if wave_index >= 4:")

    # Cinder Lunger: clearer, less cheap, still a dodge-check.
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "move_speed", "66.0")
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "attack_windup_duration", "0.64")
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "attack_recovery_duration", "0.80")
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "attack_cooldown", "1.12")
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "lunge_speed", "345.0")
    text = replace_in_block(text, 'if profile_name == "cinder_lunger":', "lunge_duration", "0.18")

    # Ember Spitter: slower projectile pressure, more readable shots.
    text = replace_in_block(text, 'if profile_name == "ember_spitter":', "attack_windup_duration", "0.78")
    text = replace_in_block(text, 'if profile_name == "ember_spitter":', "attack_recovery_duration", "0.92")
    text = replace_in_block(text, 'if profile_name == "ember_spitter":', "attack_cooldown", "1.38")
    text = replace_in_block(text, 'if profile_name == "ember_spitter":', "projectile_speed", "165.0")
    text = replace_in_block(text, 'if profile_name == "ember_spitter":', "projectile_radius", "12.0")

    # Chainbound Penitent: less sponge, still heavy and punishing.
    text = replace_in_block(text, 'if profile_name == "chainbound_penitent":', "max_health", "5")
    text = replace_in_block(text, 'if profile_name == "chainbound_penitent":', "attack_windup_duration", "1.02")
    text = replace_in_block(text, 'if profile_name == "chainbound_penitent":', "attack_recovery_duration", "1.06")
    text = replace_in_block(text, 'if profile_name == "chainbound_penitent":', "attack_cooldown", "1.52")

    # Furnace Imp: fast nuisance, not unfair mosquito.
    text = replace_in_block(text, 'if profile_name == "furnace_imp":', "move_speed", "100.0")
    text = replace_in_block(text, 'if profile_name == "furnace_imp":', "attack_windup_duration", "0.36")
    text = replace_in_block(text, 'if profile_name == "furnace_imp":', "attack_cooldown", "0.68")

    # Bell Wretch: support pressure, not permanent spam.
    text = replace_in_block(text, 'if profile_name == "bell_wretch":', "attack_windup_duration", "0.86")
    text = replace_in_block(text, 'if profile_name == "bell_wretch":', "attack_cooldown", "1.90")
    text = replace_in_block(text, 'if profile_name == "bell_wretch":', "support_pulse_range", "190.0")
    text = replace_in_block(text, 'if profile_name == "bell_wretch":', "support_pulse_strength", "0.32")

    # Ash Grunt baseline.
    text = replace_after_marker(text, 'enemy_type = "ash_grunt"', "move_speed", "54.0")
    text = replace_after_marker(text, 'enemy_type = "ash_grunt"', "attack_windup_duration", "0.52")
    text = replace_after_marker(text, 'enemy_type = "ash_grunt"', "attack_recovery_duration", "0.66")
    text = replace_after_marker(text, 'enemy_type = "ash_grunt"', "attack_cooldown", "0.86")
    write(path, text)


def patch_boss() -> None:
    path = FILES["boss"]
    text = read(path)
    text = replace_export(text, "max_health", "90", "int")
    text = replace_export(text, "idle_duration_min", "0.82", "float")
    text = replace_export(text, "idle_duration_max", "1.18", "float")
    text = replace_export(text, "sweep_windup", "0.80", "float")
    text = replace_export(text, "chain_windup", "0.96", "float")
    text = replace_export(text, "lunge_windup", "0.86", "float")
    text = replace_export(text, "cinder_windup", "0.98", "float")
    text = replace_export(text, "verdict_windup", "1.18", "float")
    text = replace_export(text, "seal_stagger_damage", "10", "int")
    text = replace_export(text, "stagger_damage_multiplier", "1.55", "float")
    text = replace_export(text, "max_summons_per_fight", "3", "int")
    text = replace_export(text, "summon_count_per_cast", "1", "int")
    write(path, text)


def patch_hazard() -> None:
    path = FILES["hazard"]
    text = read(path)
    text = replace_export(text, "radius", "54.0", "float")
    text = replace_export(text, "windup_duration", "1.55", "float")
    text = replace_export(text, "active_duration", "0.38", "float")
    text = replace_export(text, "cooldown_duration", "3.15", "float")
    text = replace_export(text, "player_knockback_force", "130.0", "float")
    write(path, text)


def patch_loop() -> None:
    path = FILES["loop"]
    text = read(path)
    text = replace_export(text, "ash_warden_max_health_v24", "90", "int")
    text = replace_export(text, "demo_victory_ash_sigils", "4", "int")
    text = replace_export(text, "demo_death_base_ash_sigils", "1", "int")
    text = replace_export(text, "fountain_heal_ratio_v21", "0.65", "float")
    text = replace_export(text, "shop_heal_cost", "1", "int")
    text = replace_export(text, "shop_damage_cost", "2", "int")
    text = replace_export(text, "shop_mystery_boon_cost", "2", "int")
    write(path, text)


def main() -> None:
    patch_player()
    patch_enemy()
    patch_boss()
    patch_hazard()
    patch_loop()
    print("V33 demo balance values applied.")


if __name__ == "__main__":
    main()
