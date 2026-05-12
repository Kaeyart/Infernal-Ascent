# V32 — Audio Pass V1

## Goal

Add core audio feedback to the playable demo slice without requiring external sound assets yet.

This pass follows the Production Bible V32 scope:

- player light attack
- player heavy attack
- dash
- player hit
- enemy hit
- enemy death
- gate open
- reward claim
- fountain use
- hazard warning
- hazard active
- boss attack
- boss death
- hub ambience
- combat loop
- boss loop
- victory sting
- death sting

## Implementation

The patch adds `res://scripts/audio/InfernalAudio.gd`.

This is a procedural audio manager. It generates short WAV streams at runtime using simple tones, pulses, impacts, and noise layers. This keeps the project self-contained and avoids blocking on final authored audio assets.

Later, this script can be replaced or extended to load authored `.wav` / `.ogg` assets while preserving the same event names.

## Event hooks added

### Player

- `player_light_attack`
- `player_heavy_attack`
- `player_dash`
- `player_hit`
- `player_death`
- `player_respawn`

### Enemies / projectiles

- `enemy_spawn`
- `enemy_attack_warning`
- `enemy_attack_active`
- `enemy_hit`
- `enemy_death`
- `projectile_fire`
- `projectile_hit`

### Hazards

- `hazard_warning`
- `hazard_active`

### Boss

- `boss_attack`
- `boss_hit`
- `boss_phase_changed`
- `boss_death`

### Run / hub / support rooms

- `gate_open`
- `reward_claim`
- `fountain_use`
- `forge_use`
- `shop_buy`
- `reliquary_purchase`
- `hub_ui_select`
- `victory_sting`
- `death_sting`

## Music / ambience contexts

- `hub`
- `combat`
- `boss`
- `victory`
- `death`

## What this pass does not do

- no final music composition
- no external audio assets
- no balance changes
- no new enemies
- no new rooms
- no new rewards
- no player art changes
- no UI redesign

## Definition of done

- important actions are not silent
- audio supports gameplay readability
- audio does not become noise
- run still reaches Ash Warden
- victory/death/return-to-hub still works
