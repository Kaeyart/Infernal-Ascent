# T-007 — Patron Data + Boon Data Schema

## Goal

Bring the patron system back structurally without locking the run to exactly two patrons.

Patrons are weighted reward sources, not hard run locks.

This patch does not implement reward selection in the live run yet. It creates the data model, loader scripts, first patron definitions, first boon definitions, synergy definitions, and validation tooling.

## Corrected Patron Rule

The run must not be hard-locked to two patrons.

Instead:

```text
All major run rewards flow through the boon/reward system.
The first completed room always offers a boon.
Patrons are selected by weighted probability.
Keepsakes, rapport, or future hub choices can modify patron weights.
Owned boons can make upgrades and synergies appear later.
Neutral rewards can still appear after the first boon.
```

## Demo Patrons

The first demo patron trio uses recognizable infernal, mythic, or literary names with mechanical titles:

```text
Azazel, the Chain-Bound Rebel
Mammon, the Gilded Furnace
Minos, the Blind Judge
```

Lucifer is reserved for the full-game endpoint and must not be a normal demo patron.

## Files Added

```text
scripts/run/PatronData.gd
scripts/run/BoonData.gd
scripts/run/PatronSynergyData.gd
scripts/run/RunBoonState.gd

data/patrons/patrons.json

data/boons/azazel_chains_boons.json
data/boons/mammon_furnace_boons.json
data/boons/minos_judge_boons.json
data/boons/patron_synergies.json

tools/validate_patron_boon_schema_t007.py
tools/apply_patron_boon_schema_t007.py
```

## Patron Schema

Required patron fields:

```text
id
display_name
short_name
title
domain
short_theme
base_weight
first_boon_weight
keepsake_weight_bonus
boon_quality_bonus_from_keepsake
color_accent
icon_path
header_path
mechanic_tags
lore_note
```

## Boon Schema

Required boon fields:

```text
id
patron_id
name
rarity
category
description_exact
effect_id
effect
synergy_tags
upgradeable
icon_path
vfx_hook
```

## Synergy Schema

Required synergy fields:

```text
id
name
required_patrons
required_tags
rarity
category
description_exact
effect_id
effect
icon_path
vfx_hook
```

## Acceptance

```text
Godot opens cleanly.
Patron JSON validates.
Boon JSON validates.
Synergy JSON validates.
Each patron has 8 boons.
Synergies reference valid patron IDs.
No run reward UI changes yet.
No patron reward selection logic yet.
No final art required yet.
```

## Next Ticket

```text
T-008 — Boon Reward Pool + Patron Weighting
```

T-008 connects this data to reward generation. It should guarantee the first room offers a boon and then use weighted patron selection instead of hard-locking the run to two patrons.
