#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path.cwd()
required_files = [
    'scripts/audio/InfernalAudio.gd',
    'scripts/iso/IsoPhysicsTestPlayer.gd',
    'scripts/iso/IsoTestEnemy.gd',
    'scripts/iso/AshBoltProjectile.gd',
    'scripts/iso/IsoRoomHazard.gd',
    'scripts/iso/AshWardenBoss.gd',
    'scripts/iso/IsoRoomLocalLoopController.gd',
    'scripts/iso/hub/IsoHubRuntimeController.gd',
    'docs/AUDIO_PASS_V1.md',
]
missing = [path for path in required_files if not (ROOT / path).exists()]
if missing:
    print('[V32 validate] Missing files:')
    for path in missing:
        print(' -', path)
    sys.exit(1)

checks = {
    'scripts/audio/InfernalAudio.gd': [
        'class_name InfernalAudio',
        'play_event_from_node',
        'set_context_from_node',
        'AudioStreamWAV',
        'victory_sting',
        'death_sting',
    ],
    'scripts/iso/IsoPhysicsTestPlayer.gd': [
        'INFERNAL_AUDIO_SCRIPT',
        'player_light_attack',
        'player_heavy_attack',
        'player_dash',
        'player_hit',
        'player_death',
    ],
    'scripts/iso/IsoTestEnemy.gd': [
        'enemy_spawn',
        'enemy_attack_warning',
        'enemy_attack_active',
        'enemy_hit',
        'enemy_death',
    ],
    'scripts/iso/AshBoltProjectile.gd': [
        'projectile_fire',
        'projectile_hit',
    ],
    'scripts/iso/IsoRoomHazard.gd': [
        'hazard_warning',
        'hazard_active',
    ],
    'scripts/iso/AshWardenBoss.gd': [
        'boss_attack',
        'boss_hit',
        'boss_phase_changed',
        'boss_death',
    ],
    'scripts/iso/IsoRoomLocalLoopController.gd': [
        '_audio_context("combat")',
        '_audio_context("boss")',
        'victory_sting',
        'death_sting',
        'reward_claim',
        'fountain_use',
        'forge_use',
        'shop_buy',
    ],
    'scripts/iso/hub/IsoHubRuntimeController.gd': [
        '_audio_context("hub")',
        'gate_open',
        'reliquary_purchase',
    ],
}

failed = []
for path, needles in checks.items():
    text = (ROOT / path).read_text(errors='ignore')
    for needle in needles:
        if needle not in text:
            failed.append(f'{path}: missing {needle!r}')
if failed:
    print('[V32 validate] Failed checks:')
    for item in failed:
        print(' -', item)
    sys.exit(1)

print('[V32 validate] Audio Pass V1 files and hooks are present.')
