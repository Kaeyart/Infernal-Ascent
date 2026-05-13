# Infernal Ascent V2 — Demo Asset + System Tracker

This document separates what is **logic**, what is **art**, what is **data**, and what is **integration**, then gives the exact implementation order for the demo rebuild.

## Status Values
Missing / Placeholder / In Progress / Accepted / Rework

## Lane Rules
- **LOGIC**: behavior, combat, state, application rules.
- **ART**: sprites, room plates, UI frames, VFX, icons, audio.
- **DATA**: patrons, boons, rewards, enemy stats, room specs.
- **INTEGRATION**: connects art/data/logic inside the playable loop.

## Exact Implementation Order

0. **Tracker and Folder Discipline** [DATA] — Create tracker docs/json/validator and folder discipline. Acceptance: Everything has a status.
1. **Combat Kit Design Lock** [LOGIC] — Spec light/heavy/Q/ultimate/meter/dash/cancel rules. Acceptance: No ambiguity about player kit.
2. **Combat Kit Logic Prototype** [LOGIC] — Implement combo, heavy, Q, ultimate, Judgment meter with placeholders. Acceptance: Player stops being left-click-only.
3. **Enemy Interaction Logic Pass** [LOGIC] — Rebuild enemy stagger/knockback/vulnerability around new kit. Acceptance: First enemies teach different responses.
4. **Patron Data Schema** [DATA] — Data model for patrons, boons, synergies, active run state. Acceptance: Patrons load from data.
5. **Two Patrons Per Run** [LOGIC] — Exactly two active patrons in each run. Acceptance: Rewards pull from active patrons.
6. **First Patron: Chain Saint** [DATA/LOGIC] — Implement 8 Chain Saint boons. Acceptance: Build identity recognizable.
7. **Second Patron: Furnace Mother + Synergy** [DATA/LOGIC] — Implement burn/ash boons + first synergies. Acceptance: Two-patron synergy works.
8. **Forge Marks Logic** [LOGIC] — Serrated Edge, Grave Weight, Ash Step. Acceptance: Forge changes weapon behavior.
9. **Weapon Ascension Logic** [LOGIC] — Martyr Blade, Warden Breaker, Ash Serpent Edge. Acceptance: Mid-run evolution changes combat.
10. **Choice UI Presentation** [INTEGRATION] — Reward/patron/forge/ascension cards. Acceptance: No debug choice UI.
11. **Enemy Art Batch 1** [ART] — Ash Grunt, Cinder Lunger, Ember Spitter. Acceptance: Enemies visually distinct.
12. **Ash Intake Hall Real Room** [ART/INTEGRATION] — Room plate, collision, spawns, hazards, gates. Acceptance: One room feels real.
13. **Hazard Art States** [ART] — Idle/warning/active/cooldown visuals. Acceptance: Danger language works visually.
14. **Support Room Function + Art** [INTEGRATION] — Reward/fountain/shop/forge become presentable. Acceptance: Support rooms worth entering.
15. **Enemy Art Batch 2** [ART] — Chainbound, Imp, Bell Wretch. Acceptance: Six-enemy roster readable.
16. **Remaining Combat Rooms** [ART/INTEGRATION] — Five remaining combat rooms. Acceptance: Run no longer feels repeated.
17. **Blind Judge + Full Synergies** [DATA/LOGIC] — Third patron and remaining synergy pairs. Acceptance: Multiple run identities exist.
18. **Ash Warden Art + Arena** [ART/INTEGRATION] — Boss sprite, animations, arena, VFX. Acceptance: Boss feels like a boss.
19. **Hub Art + Progression Presentation** [INTEGRATION] — Hub station art and progression UI. Acceptance: Hub feels like a place.
20. **Audio Replacement** [AUDIO/INTEGRATION] — Replace procedural noise with usable SFX/music. Acceptance: Audio supports gameplay.
21. **QA / Balance / Packaging** [INTEGRATION] — Stabilize, export, README, controls. Acceptance: Someone else can play it.

## Systems Tracker

| ID | System | Lane | Status | Priority | Need | Acceptance |
|---|---|---|---|---|---|---|
| S-001 | Player Combat Kit Spec | LOGIC | Missing | P0 | Lock light combo, heavy, Q, ultimate, Judgment meter, dash/cancel rules. | Spec accepted; no ambiguity about player buttons. |
| S-002 | Judgment Meter | LOGIC | Missing | P0 | Meter gained from hits, kills, dodges/ripostes; spent by ultimate. | Visible in HUD; persists only during run; resets correctly. |
| S-003 | Q Ability: Penitent Riposte / Ashen Cleave | LOGIC | Missing | P0 | Skill-expression ability; riposte preferred, cleave fallback. | Works in combat with placeholder VFX and cooldown. |
| S-004 | Ultimate: Judgment Break | LOGIC | Missing | P0 | Full-meter execution slash with stagger/boss value. | Consumes meter, damages enemies, has readable windup/impact. |
| S-005 | Enemy Interaction Rebuild | LOGIC | Missing | P0 | Stagger, knockback, vulnerability windows, Q/ultimate reactions. | First three enemies teach different responses. |
| S-006 | Patron Data Schema | DATA | Missing | P0 | Patron, boon, synergy, active run patron structures. | Data loads cleanly; not hardcoded in UI scripts. |
| S-007 | Two Patrons Per Run | LOGIC | Missing | P0 | Each run has exactly two active patrons. | Reward pool uses active patrons plus neutral boons. |
| S-008 | Chain Saint Boon Set | DATA/LOGIC | Missing | P0 | 8 stagger/control/riposte boons. | A Chain Saint build is recognizable in gameplay. |
| S-009 | Furnace Mother Boon Set | DATA/LOGIC | Missing | P1 | 8 burn/ash/area-denial boons. | Furnace playstyle is distinct and synergizes with Chain Saint. |
| S-010 | Blind Judge Boon Set | DATA/LOGIC | Missing | P2 | 8 mark/verdict/execution/timing boons. | Judged state is visible and mechanically relevant. |
| S-011 | Patron Synergy Boons | DATA/LOGIC | Missing | P1 | Rare boons unlocked by active patron pairs. | At least Chain+Furnace synergies work. |
| S-012 | Forge Marks V1 | LOGIC | Placeholder | P0 | Serrated Edge, Grave Weight, Ash Step affect weapon behavior. | Forge visit changes combat for the run. |
| S-013 | Weapon Ascension Choice | LOGIC | Missing | P1 | Mid-run evolution into Martyr Blade, Warden Breaker, Ash Serpent Edge. | One of three ascensions meaningfully changes combat. |
| S-014 | Boon/Forge/Ascension UI Presentation | INTEGRATION | Missing | P1 | Non-debug card/menu presentation for choices. | Player understands choices without debug text. |
| S-015 | Room Plate / Authored Room Loader | INTEGRATION | Placeholder | P1 | Load room plate + sockets + collision mask. | One authored room plays correctly. |
| S-016 | Ash Warden Visual Integration | ART/INTEGRATION | Missing | P2 | Replace boss placeholder with real boss art/animations. | Boss feels like a boss, not a large test enemy. |
| S-017 | Audio Replacement Pass | AUDIO | Placeholder | P3 | Replace procedural noise with curated/usable SFX/music. | Important actions are readable through sound. |

## Asset Tracker

| ID | Category | Asset | Lane | Status | Priority | Need | Acceptance |
|---|---|---|---|---|---|---|---|
| A-P001 | Player | player_q_riposte_4dir.png | ART | Missing | P1 | Directional Q/riposte animation or fallback skill animation. | Readable in combat; does not obscure hazards. |
| A-P002 | Player | player_ultimate_judgment_break_4dir.png | ART | Missing | P1 | Directional ultimate animation or strong impact pose. | Readable in combat; does not obscure hazards. |
| A-P003 | Player | vfx_player_dash_trail.png | ART | Missing | P1 | Readable dash trail aligned to isometric movement. | Readable in combat; does not obscure hazards. |
| A-P004 | Player | vfx_player_hit_spark.png | ART | Missing | P1 | Small hit feedback on player/enemy contact. | Readable in combat; does not obscure hazards. |
| A-P005 | Player | vfx_player_judgment_meter_gain.png | ART | Missing | P1 | Tiny gain pulse for Judgment meter. | Readable in combat; does not obscure hazards. |
| A-P006 | Player | vfx_player_ultimate_slash_4dir.png | ART | Missing | P1 | Large directional slash effect. | Readable in combat; does not obscure hazards. |
| A-E001 | Enemy | ash_grunt_idle_4dir.png | ART | Missing | P1 | Ash Grunt idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E002 | Enemy | ash_grunt_walk_4dir.png | ART | Missing | P1 | Ash Grunt walk_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E003 | Enemy | ash_grunt_attack_warning_4dir.png | ART | Missing | P1 | Ash Grunt attack_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E004 | Enemy | ash_grunt_attack_active_4dir.png | ART | Missing | P1 | Ash Grunt attack_active_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E005 | Enemy | ash_grunt_hit_4dir.png | ART | Missing | P1 | Ash Grunt hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E006 | Enemy | ash_grunt_death_4dir.png | ART | Missing | P1 | Ash Grunt death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E007 | Enemy | ash_grunt_icon.png | ART | Missing | P1 | Ash Grunt icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E008 | Enemy | cinder_lunger_idle_4dir.png | ART | Missing | P1 | Cinder Lunger idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E009 | Enemy | cinder_lunger_crouch_warning_4dir.png | ART | Missing | P1 | Cinder Lunger crouch_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E010 | Enemy | cinder_lunger_lunge_4dir.png | ART | Missing | P1 | Cinder Lunger lunge_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E011 | Enemy | cinder_lunger_recovery_4dir.png | ART | Missing | P1 | Cinder Lunger recovery_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E012 | Enemy | cinder_lunger_hit_4dir.png | ART | Missing | P1 | Cinder Lunger hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E013 | Enemy | cinder_lunger_death_4dir.png | ART | Missing | P1 | Cinder Lunger death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E014 | Enemy | cinder_lunger_icon.png | ART | Missing | P1 | Cinder Lunger icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E015 | Enemy | ember_spitter_idle_4dir.png | ART | Missing | P1 | Ember Spitter idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E016 | Enemy | ember_spitter_move_4dir.png | ART | Missing | P1 | Ember Spitter move_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E017 | Enemy | ember_spitter_charge_warning_4dir.png | ART | Missing | P1 | Ember Spitter charge_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E018 | Enemy | ember_spitter_spit_attack_4dir.png | ART | Missing | P1 | Ember Spitter spit_attack_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E019 | Enemy | ember_spitter_hit_4dir.png | ART | Missing | P1 | Ember Spitter hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E020 | Enemy | ember_spitter_death_4dir.png | ART | Missing | P1 | Ember Spitter death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E021 | Enemy | ember_spitter_projectile.png | ART | Missing | P1 | Ember Spitter projectile sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E022 | Enemy | ember_spitter_projectile_impact.png | ART | Missing | P1 | Ember Spitter projectile_impact sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E023 | Enemy | ember_spitter_icon.png | ART | Missing | P1 | Ember Spitter icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E024 | Enemy | chainbound_penitent_idle_4dir.png | ART | Missing | P2 | Chainbound Penitent idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E025 | Enemy | chainbound_penitent_walk_4dir.png | ART | Missing | P2 | Chainbound Penitent walk_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E026 | Enemy | chainbound_penitent_heavy_warning_4dir.png | ART | Missing | P2 | Chainbound Penitent heavy_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E027 | Enemy | chainbound_penitent_heavy_swing_4dir.png | ART | Missing | P2 | Chainbound Penitent heavy_swing_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E028 | Enemy | chainbound_penitent_stagger_4dir.png | ART | Missing | P2 | Chainbound Penitent stagger_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E029 | Enemy | chainbound_penitent_hit_4dir.png | ART | Missing | P2 | Chainbound Penitent hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E030 | Enemy | chainbound_penitent_death_4dir.png | ART | Missing | P2 | Chainbound Penitent death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E031 | Enemy | chainbound_penitent_icon.png | ART | Missing | P2 | Chainbound Penitent icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E032 | Enemy | furnace_imp_idle_4dir.png | ART | Missing | P2 | Furnace Imp idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E033 | Enemy | furnace_imp_scuttle_4dir.png | ART | Missing | P2 | Furnace Imp scuttle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E034 | Enemy | furnace_imp_attack_warning_4dir.png | ART | Missing | P2 | Furnace Imp attack_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E035 | Enemy | furnace_imp_attack_active_4dir.png | ART | Missing | P2 | Furnace Imp attack_active_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E036 | Enemy | furnace_imp_hit_4dir.png | ART | Missing | P2 | Furnace Imp hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E037 | Enemy | furnace_imp_death_4dir.png | ART | Missing | P2 | Furnace Imp death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E038 | Enemy | furnace_imp_icon.png | ART | Missing | P2 | Furnace Imp icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E039 | Enemy | bell_wretch_idle_4dir.png | ART | Missing | P2 | Bell Wretch idle_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E040 | Enemy | bell_wretch_move_4dir.png | ART | Missing | P2 | Bell Wretch move_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E041 | Enemy | bell_wretch_alarm_warning_4dir.png | ART | Missing | P2 | Bell Wretch alarm_warning_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E042 | Enemy | bell_wretch_alarm_cast_4dir.png | ART | Missing | P2 | Bell Wretch alarm_cast_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E043 | Enemy | bell_wretch_hit_4dir.png | ART | Missing | P2 | Bell Wretch hit_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E044 | Enemy | bell_wretch_death_4dir.png | ART | Missing | P2 | Bell Wretch death_4dir sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E045 | Enemy | bell_wretch_buff_or_alarm_vfx.png | ART | Missing | P2 | Bell Wretch buff_or_alarm_vfx sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-E046 | Enemy | bell_wretch_icon.png | ART | Missing | P2 | Bell Wretch icon sprite/asset. | Enemy role reads at gameplay scale; animation aligns with hit timing. |
| A-B001 | Boss | ash_warden_idle_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B002 | Boss | ash_warden_walk_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B003 | Boss | ash_warden_melee_sweep_warning_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B004 | Boss | ash_warden_melee_sweep_attack_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B005 | Boss | ash_warden_chain_slam_warning_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B006 | Boss | ash_warden_chain_slam_attack_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B007 | Boss | ash_warden_lunge_warning_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B008 | Boss | ash_warden_lunge_attack_4dir.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B009 | Boss | ash_warden_phase_transition.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B010 | Boss | ash_warden_stagger.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B011 | Boss | ash_warden_hit.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B012 | Boss | ash_warden_death.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-B013 | Boss | ash_warden_boss_portrait.png | ART | Missing | P3 | Ash Warden boss presentation asset. | Boss silhouette and attack state are readable. |
| A-R001 | Room | ash_intake_hall_room_plate.png | ART | Missing | P1 | Authored isometric room plate for ash_intake_hall. | Room shape is readable; props do not hide danger. |
| A-R101 | Room | ash_intake_hall_collision_mask.json | DATA | Missing | P1 | Collision polygon / playable bounds for ash_intake_hall. | Player stays inside valid floor; gates/spawns legal. |
| A-R002 | Room | cinder_drain_room_plate.png | ART | Missing | P2 | Authored isometric room plate for cinder_drain. | Room shape is readable; props do not hide danger. |
| A-R102 | Room | cinder_drain_collision_mask.json | DATA | Missing | P2 | Collision polygon / playable bounds for cinder_drain. | Player stays inside valid floor; gates/spawns legal. |
| A-R003 | Room | furnace_vestibule_room_plate.png | ART | Missing | P2 | Authored isometric room plate for furnace_vestibule. | Room shape is readable; props do not hide danger. |
| A-R103 | Room | furnace_vestibule_collision_mask.json | DATA | Missing | P2 | Collision polygon / playable bounds for furnace_vestibule. | Player stays inside valid floor; gates/spawns legal. |
| A-R004 | Room | chain_reservoir_room_plate.png | ART | Missing | P2 | Authored isometric room plate for chain_reservoir. | Room shape is readable; props do not hide danger. |
| A-R104 | Room | chain_reservoir_collision_mask.json | DATA | Missing | P2 | Collision polygon / playable bounds for chain_reservoir. | Player stays inside valid floor; gates/spawns legal. |
| A-R005 | Room | ember_sorting_floor_room_plate.png | ART | Missing | P2 | Authored isometric room plate for ember_sorting_floor. | Room shape is readable; props do not hide danger. |
| A-R105 | Room | ember_sorting_floor_collision_mask.json | DATA | Missing | P2 | Collision polygon / playable bounds for ember_sorting_floor. | Player stays inside valid floor; gates/spawns legal. |
| A-R006 | Room | penitent_crossing_room_plate.png | ART | Missing | P2 | Authored isometric room plate for penitent_crossing. | Room shape is readable; props do not hide danger. |
| A-R106 | Room | penitent_crossing_collision_mask.json | DATA | Missing | P2 | Collision polygon / playable bounds for penitent_crossing. | Player stays inside valid floor; gates/spawns legal. |
| A-S001 | Support Room | reward_altar_room_plate.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S002 | Support Room | reward_pedestal_common.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S003 | Support Room | fountain_room_plate.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S004 | Support Room | fountain_basin_idle.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S005 | Support Room | shop_room_plate.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S006 | Support Room | ash_merchant_sprite_idle.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S007 | Support Room | forge_room_plate.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S008 | Support Room | cold_forge_anvil_idle.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S009 | Support Room | boss_antechamber_plate.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-S010 | Support Room | sealed_ash_warden_gate_closed.png | ART | Missing | P2 | Support-room or interactable art. | Object silhouette + label + [E] prompt reads clearly. |
| A-H001 | Hub | hub_threshold_nave_plate.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H002 | Hub | hub_hell_gate_idle.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H003 | Hub | hub_memory_pool_idle.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H004 | Hub | hub_reliquary_altar_idle.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H005 | Hub | hub_forge_station_idle.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H006 | Hub | hub_codex_lectern_idle.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-H007 | Hub | hub_sealed_descent_door_locked.png | ART | Missing | P3 | Hub station or base art. | Station purpose readable without debug label overload. |
| A-U001 | UI | ui_panel_reward_choice.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U002 | UI | ui_panel_route_choice.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U003 | UI | ui_panel_shop.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U004 | UI | ui_panel_forge.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U005 | UI | ui_panel_reliquary.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U006 | UI | ui_panel_run_result.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U007 | UI | ui_panel_weapon_ascension.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U008 | UI | ui_health_frame.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U009 | UI | ui_judgment_meter_frame.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U010 | UI | ui_boss_health_frame.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U011 | UI | ui_prompt_e_key.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U012 | UI | ui_rarity_common_trim.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U013 | UI | ui_rarity_rare_trim.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-U014 | UI | ui_rarity_legendary_trim.png | ART | Missing | P1 | Interface frame/icon for non-debug presentation. | Readable, thematically consistent, does not cover combat. |
| A-BO001 | Patron/Boon | patron_chain_saint_icon.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO002 | Patron/Boon | patron_chain_saint_header.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO003 | Patron/Boon | boon_chain_stagger.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO004 | Patron/Boon | boon_chain_root.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO005 | Patron/Boon | boon_chain_heavy_bonus.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO006 | Patron/Boon | boon_chain_dash_bind.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO007 | Patron/Boon | boon_chain_riposte_mark.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO008 | Patron/Boon | boon_chain_ultimate_shackle.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO009 | Patron/Boon | boon_chain_echo_lash.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO010 | Patron/Boon | boon_chain_execution_meter.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO011 | Patron/Boon | patron_furnace_mother_icon.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO012 | Patron/Boon | patron_furnace_mother_header.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO013 | Patron/Boon | boon_furnace_burn.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO014 | Patron/Boon | boon_furnace_ash_trail.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO015 | Patron/Boon | boon_furnace_explosion.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO016 | Patron/Boon | boon_furnace_hazard_boost.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO017 | Patron/Boon | boon_furnace_low_hp_fire.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO018 | Patron/Boon | boon_furnace_heavy_ember.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO019 | Patron/Boon | boon_furnace_dash_ignite.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO020 | Patron/Boon | boon_furnace_final_flame.png | ART | Missing | P1 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO021 | Patron/Boon | patron_blind_judge_icon.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO022 | Patron/Boon | patron_blind_judge_header.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO023 | Patron/Boon | boon_judge_mark.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO024 | Patron/Boon | boon_judge_crit.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO025 | Patron/Boon | boon_judge_execution.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO026 | Patron/Boon | boon_judge_meter_gain.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO027 | Patron/Boon | boon_judge_perfect_dodge.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO028 | Patron/Boon | boon_judge_ultimate_damage.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO029 | Patron/Boon | boon_judge_first_strike.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-BO030 | Patron/Boon | boon_judge_sentence.png | ART | Missing | P2 | Patron/boon identity icon or header art. | Icon is readable at UI size and reinforces patron identity. |
| A-F001 | Forge/Weapon | forge_mark_serrated_edge_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-F002 | Forge/Weapon | forge_mark_grave_weight_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-F003 | Forge/Weapon | forge_mark_ash_step_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-F004 | Forge/Weapon | weapon_ascension_martyr_blade_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-F005 | Forge/Weapon | weapon_ascension_warden_breaker_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-F006 | Forge/Weapon | weapon_ascension_ash_serpent_edge_icon.png | ART | Missing | P1 | Forge mark or weapon ascension icon. | Choice is visually distinct and mechanically clear. |
| A-Z001 | Hazard | hazard_ash_vent_idle.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z002 | Hazard | hazard_ash_vent_warning.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z003 | Hazard | hazard_ash_vent_active.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z004 | Hazard | hazard_ash_vent_cooldown.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z005 | Hazard | hazard_ember_grate_idle.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z006 | Hazard | hazard_ember_grate_warning.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z007 | Hazard | hazard_ember_grate_active.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z008 | Hazard | hazard_ember_grate_cooldown.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z009 | Hazard | hazard_falling_cinder_warning_marker.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-Z010 | Hazard | hazard_falling_cinder_impact.png | ART | Missing | P1 | Hazard state visual. | Warning/active/cooldown readable without debug markers. |
| A-V001 | VFX | vfx_light_attack_arc_4dir.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V002 | VFX | vfx_heavy_attack_arc_4dir.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V003 | VFX | vfx_q_riposte_guard.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V004 | VFX | vfx_q_riposte_counter_slash.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V005 | VFX | vfx_ultimate_judgment_break_windup.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V006 | VFX | vfx_ultimate_judgment_break_slash.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V007 | VFX | vfx_enemy_hit_spark.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V008 | VFX | vfx_enemy_death_ash_burst.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V009 | VFX | vfx_dash_trail.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V010 | VFX | vfx_reward_claim.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-V011 | VFX | vfx_heal.png | ART | Missing | P1 | Combat or interaction VFX. | Adds readability/impact without obscuring gameplay. |
| A-A001 | Audio | sfx_player_light_attack.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A002 | Audio | sfx_player_heavy_attack.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A003 | Audio | sfx_player_dash.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A004 | Audio | sfx_player_hit.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A005 | Audio | sfx_enemy_warning.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A006 | Audio | sfx_enemy_hit.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A007 | Audio | sfx_enemy_death.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A008 | Audio | sfx_gate_open.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A009 | Audio | sfx_reward_claim.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A010 | Audio | sfx_fountain_use.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A011 | Audio | sfx_forge_apply.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A012 | Audio | sfx_hazard_warning.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A013 | Audio | sfx_boss_phase.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A014 | Audio | sfx_boss_death.wav | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A015 | Audio | music_hub_ambience_loop.ogg | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A016 | Audio | music_combat_loop_01.ogg | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A017 | Audio | music_boss_loop_ash_warden.ogg | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A018 | Audio | music_victory_sting.ogg | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |
| A-A019 | Audio | music_death_sting.ogg | AUDIO | Missing | P3 | SFX/music asset. | Supports readability and does not become noise. |