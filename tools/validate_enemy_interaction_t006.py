#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path.cwd()
PLAYER = ROOT / "scripts/iso/IsoPhysicsTestPlayer.gd"
ENEMY = ROOT / "scripts/iso/IsoTestEnemy.gd"
DOC = ROOT / "docs/ENEMY_INTERACTION_PASS_T006.md"

checks = []

def check(condition: bool, message: str) -> None:
    checks.append((condition, message))

player_text = PLAYER.read_text() if PLAYER.exists() else ""
enemy_text = ENEMY.read_text() if ENEMY.exists() else ""

check(PLAYER.exists(), "player script exists")
check(ENEMY.exists(), "enemy script exists")
check(DOC.exists(), "T-006 doc exists")
check("func _t004_call_damage_method(target: Node, arg1: Variant" in player_text, "player damage dispatcher is flexible")
check("receive_player_ability_interaction" in player_text, "player calls enemy interaction hook")
check("get_player_ability_damage_multiplier" in player_text, "player reads enemy damage multiplier")
check("AshWardenBoss.gd" in player_text, "boss damage signature branch retained")
check("func receive_player_ability_interaction" in enemy_text, "enemy interaction hook exists")
check("func get_player_ability_damage_multiplier" in enemy_text, "enemy damage multiplier hook exists")
check("func _t006_update_enemy_interaction" in enemy_text, "enemy timer update exists")
check("_t006_update_enemy_interaction(" in enemy_text, "enemy update hook is called")
check("var t006_stagger_value" in enemy_text, "enemy stagger state exists")
check("var t006_vulnerability_timer" in enemy_text, "enemy vulnerability state exists")
check("func take_damage" in enemy_text, "enemy take_damage still exists")

failed = [msg for ok, msg in checks if not ok]
for ok, msg in checks:
    print(("OK  " if ok else "FAIL") + msg)

if failed:
    print("\nT-006 validation failed:")
    for msg in failed:
        print("- " + msg)
    sys.exit(1)

print("\nT-006 validation passed.")
