# V24 — Ash Warden Boss V1

This patch implements the first playable Ash Warden boss fight for the Infernal Ascent V2 demo slice.

It follows the Production Bible scope for V24: boss health, boss phases, melee sweep, chain slam, lunge, falling cinder hazard, summon adds, readable telegraphs, damage windows, boss death state, and boss health bar.

## What this patch touches

- `scripts/iso/AshWardenBoss.gd`
- `scripts/iso/IsoRoomLocalLoopController.gd`

## What this patch does not touch

- player art
- route-choice logic outside boss entry/victory
- new non-boss rooms
- permanent upgrades
- save system
- reward expansion

## Boss mechanics

### Phase 1

- Sweeping melee arc
- Chain slam lane
- Furnace Seal Stagger mechanic introduced

### Phase 2

- Lunge lane attack
- Falling cinder target markers
- Limited add summons

### Phase 3

- Final Verdict pattern
- Cross-lane pressure
- Falling cinders
- Faster pressure loop

## Core mechanic: Furnace Seal Stagger

The arena has armed furnace seals. If the Ash Warden is baited into an armed seal during a committed attack, he staggers and takes bonus seal damage. While staggered, player damage is amplified.

This is the first real boss mechanic: the player should not only attack, but reposition the boss.

## Definition of done

- Player reaches The Sentencing Furnace.
- Ash Warden spawns as a real fight.
- Boss has HP and a health bar.
- Boss changes phases.
- Boss attacks are telegraphed.
- Player can damage boss.
- Player can die to boss.
- Boss can die.
- Victory exit appears after boss death.
- Return-to-hub flow still works.
