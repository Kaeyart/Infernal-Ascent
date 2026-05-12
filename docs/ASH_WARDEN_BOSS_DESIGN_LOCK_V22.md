# V22 — Ash Warden Boss Design Lock

Status: DESIGN LOCK  
Milestone: V22 — Boss Design Lock  
Next milestones: V23 — Boss Arena V1, V24 — Ash Warden Boss V1

This document defines the demo boss before implementation. V22 does not add boss code, boss arena code, new rewards, new enemies, new rooms, save logic, or player art changes.

---

# 1. Boss Identity

## Name

**The Ash Warden**

## Role

The Ash Warden is the first gatekeeper of Circle 0. He is a penitential jailer, executioner, and furnace-keeper who guards the descent beyond the ash intake facilities.

He is not a demon clown, not a generic lava brute, and not a random knight. He is an infernal institutional function: the officer who receives, brands, chains, and processes the damned before deeper judgment.

## Theme Pillars

```text
fallen holy authority
ash furnace execution
chain machinery
judgment and sentencing
punishment as bureaucracy
hell as institution
```

## Visual Read

The Ash Warden should read as:

```text
large armored executioner
blackened reliquary plate
furnace glow in chest/helmet seams
heavy chains wrapped around arms and back
ash-caked mantle or execution cloth
ceremonial jailer bell / censer / chain weapon
```

He should feel like a massive corrupted crusader-jailer, not a beast.

---

# 2. Fight Design Goal

The fight teaches the player the demo's combat rules:

```text
watch telegraphs
respect active danger
dash intentionally
bait attacks into arena objects
use reward build advantages
control adds without panic
```

The fight should be readable, fair, and tense. It should not rely on invisible damage, instant hits, or unreadable projectile spam.

Target fight length:

```text
first win: 2.5–4 minutes
good run: 90–150 seconds
bad run: death within 45–90 seconds if careless
```

---

# 3. Arena Concept

## Arena Name

**The Sentencing Furnace**

## Shape

Large isometric chamber, roughly rectangular/diamond readable from the current camera.

Recommended gameplay bounds:

```text
width: 1000–1200 px
height: 650–800 px
```

## Key Arena Objects

```text
1. North Furnace Gate
   Boss entrance / background object.

2. Four Furnace Seals
   NW, NE, SW, SE arena quadrants.
   Used by the main boss mechanic.

3. Chain Anchor Pillars
   Left and right sides.
   Used for chain lane attacks.

4. Player Entry Gate
   Lower/south edge.

5. Victory Descent Seal
   Appears after boss death.
```

## Arena Rules

```text
Player spawn is safe.
Boss starts locked at north/center.
Player cannot leave during fight.
Hazards never cover the entire arena.
At least one safe lane exists during every major pattern.
Adds never spawn directly on the player.
```

---

# 4. Core Boss Mechanics

The Ash Warden needs genuine mechanics, but they must remain implementable in the current Godot prototype.

## Mechanic A — Furnace Seal Stagger

This is the main demo boss mechanic.

Four furnace seals exist in the arena. During the fight, some seals begin glowing with ash heat.

The player can bait specific Ash Warden attacks into a glowing seal. If the boss hits a glowing seal with **Warden Slam** or **Chain Judgment**, the seal erupts under him and briefly staggers him.

### Player Read

```text
Seal idle: dim cracked circle.
Seal armed: bright ember cracks + pulse.
Seal triggered: burst of ash flame.
Boss staggered: kneels / armor opens / head lowered.
```

### Gameplay Function

```text
Armed seal + boss heavy attack impact = boss stagger.
Stagger window = player damage opportunity.
Failing to use seals is allowed, but fight is harder.
```

### Why this matters

This creates a real boss mechanic beyond "hit the big enemy." The player is not only dodging; they are manipulating boss positioning.

---

## Mechanic B — Chain Sentence Lanes

The Ash Warden uses chain anchors to mark long danger lanes across the arena.

### Pattern

```text
1. Boss raises chain.
2. Chain anchor glows.
3. A long lane appears.
4. After wind-up, chain lashes through the lane.
5. Lane fades to cooldown.
```

### Player Counterplay

```text
Move out of lane.
Dash through only during safe timing.
Use lane direction to bait boss toward furnace seals.
```

### Readability Rule

The warning lane must be visible before damage. Active lane must look clearly sharper/brighter than warning.

---

## Mechanic C — Judgment Heat

The arena slowly escalates heat as the fight progresses.

This is not a complex UI meter for V24. It is a simple internal pressure mechanic:

```text
Phase 1: low heat, few hazards.
Phase 2: seals arm more often, more cinders.
Phase 3: chains and seals overlap more aggressively.
```

The player should feel the arena becoming less comfortable without becoming unfair.

---

## Mechanic D — Add Pressure

The boss can summon minor enemies in Phase 2 and Phase 3.

Allowed adds for demo boss:

```text
Ash Grunt
Furnace Imp
```

Do not summon ranged spitters during the first implementation unless the fight is too easy. The first boss should test control, not become visual soup.

Add spawn rule:

```text
never more than 2 adds alive from boss summons
never spawn directly on the player
summon telegraph must show before add appears
```

---

# 5. Boss Stats Target

Initial tuning values for V24 implementation:

```text
max_hp: 90–120
contact_damage: avoid or keep minimal
phase_2_threshold: 65% HP
phase_3_threshold: 30% HP
stagger_duration: 2.2 seconds
post_stagger_resistance: 4 seconds before another seal stagger
```

Damage targets:

```text
basic sweep: 1 HP
chain lane: 1 HP
slam center: 2 HP
slam outer radius: 1 HP
falling cinder: 1 HP
phase 3 judgment slam: 2 HP
```

The boss should kill careless players but should not one-shot normal demo builds.

---

# 6. Boss Phase Structure

## Phase 1 — The Sentencing Begins

HP range:

```text
100% → 65%
```

Purpose:

```text
Teach basic boss attacks.
Teach chain lanes.
Introduce furnace seals without too much overlap.
```

Moves allowed:

```text
Censer Sweep
Chain Sentence
Warden Slam
Slow reposition
```

Furnace Seal behavior:

```text
One seal arms at a time.
Long warning.
Long stagger window if boss is baited into it.
```

No adds in Phase 1.

---

## Phase 2 — The Furnace Opens

HP range:

```text
65% → 30%
```

Purpose:

```text
Introduce overlapping pressure.
Add minor enemies.
Make seal baiting more useful.
```

Moves allowed:

```text
Censer Sweep
Chain Sentence
Warden Slam
Binding Lunge
Falling Cinder
Summon Penitents
```

Furnace Seal behavior:

```text
One or two seals can arm.
Seal warning is shorter than Phase 1.
Boss can be staggered by seal eruption.
```

Adds:

```text
Summons 1–2 Ash Grunts or Furnace Imps.
Never more than 2 summon adds alive.
```

---

## Phase 3 — Final Verdict

HP range:

```text
30% → 0%
```

Purpose:

```text
Final execution pressure.
The player must use everything learned.
```

Moves allowed:

```text
Censer Sweep
Double Chain Sentence
Warden Slam
Binding Lunge
Falling Cinder
Final Verdict Pattern
Limited Summon Penitents
```

Furnace Seal behavior:

```text
Two seals arm more frequently.
Seal stagger still works, but boss gains brief resistance after being staggered.
```

Phase 3 must be harder, not chaotic.

---

# 7. Move List

## Move 1 — Censer Sweep

Role:

```text
basic melee arc
```

Telegraph:

```text
wide arc wedge in front of boss
boss pulls weapon/chain back
0.65s warning
```

Active:

```text
0.18–0.25s damage window
1 damage
knockback away from boss
```

Counterplay:

```text
step behind boss
dash through timing
stay outside arc
```

Use in:

```text
Phase 1, Phase 2, Phase 3
```

---

## Move 2 — Chain Sentence

Role:

```text
long lane control
```

Telegraph:

```text
chain anchor glows
thin warning lane appears
boss raises chain
0.9s warning in Phase 1
0.7s warning in Phase 2+
```

Active:

```text
lane snaps bright
1 damage
short hit stun / knockback sideways
```

Counterplay:

```text
leave lane
dash through only if timed
bait boss toward armed furnace seal
```

Use in:

```text
Phase 1, Phase 2, Phase 3
```

---

## Move 3 — Warden Slam

Role:

```text
large punish / seal interaction move
```

Telegraph:

```text
large circle around boss
floor cracks inward
boss raises both arms/chain
1.1s warning
```

Active:

```text
center radius deals 2 damage
outer radius deals 1 damage
shockwave ring expands briefly
```

Special:

```text
If slam overlaps an armed furnace seal, boss is staggered.
```

Counterplay:

```text
leave circle
bait boss onto armed seal
punish during recovery/stagger
```

Use in:

```text
Phase 1, Phase 2, Phase 3
```

---

## Move 4 — Binding Lunge

Role:

```text
directional dash punish
```

Telegraph:

```text
long rectangular lane from boss toward player
boss crouches / chain tightens
0.85s warning
```

Active:

```text
boss lunges along lane
1 damage
brief knockback
```

Counterplay:

```text
sidestep lane
dash perpendicular
punish recovery
```

Use in:

```text
Phase 2, Phase 3
```

---

## Move 5 — Falling Cinder

Role:

```text
arena pressure
```

Telegraph:

```text
small target marks appear on floor
embers fall from ceiling
0.9s warning
```

Active:

```text
impact burst
1 damage
brief burning patch optional later
```

Counterplay:

```text
leave target markers
use forced movement carefully
```

Use in:

```text
Phase 2, Phase 3
```

---

## Move 6 — Summon Penitents

Role:

```text
temporary add pressure
```

Telegraph:

```text
two ash circles appear near arena edges
chains drag bodies from ash
1.0s warning
```

Active:

```text
1–2 adds spawn
adds are Ash Grunt or Furnace Imp
```

Limits:

```text
max 2 boss-summoned adds alive
minimum 14 seconds between summons
```

Use in:

```text
Phase 2, Phase 3
```

---

## Move 7 — Final Verdict Pattern

Role:

```text
Phase 3 signature pattern
```

Pattern:

```text
1. Two furnace seals arm.
2. Two chain lanes telegraph across the arena.
3. Boss performs Warden Slam.
4. If player baits slam into armed seal, boss staggers.
5. If not, falling cinders follow.
```

Purpose:

This is the final exam of the boss fight. The player must read seals, lanes, and boss position without panic.

Use in:

```text
Phase 3 only
```

Cooldown:

```text
minimum 18–24 seconds
```

---

# 8. Telegraph Rules

The boss uses the same danger language as the rest of the demo.

```text
WARNING = visible floor shape + boss wind-up
ACTIVE = sharper/brighter danger state + damage possible
COOLDOWN = fade-out + no damage
```

Required telegraph shapes:

```text
Censer Sweep = arc wedge
Chain Sentence = long lane
Warden Slam = circle + shockwave ring
Binding Lunge = long rectangle/lane
Falling Cinder = target circles
Summon Penitents = ash spawn circles
Furnace Seal = persistent circular seal, armed by pulse/cracks
```

No boss attack may deal damage without a readable warning.

---

# 9. Boss Damage Windows

The boss should not be constantly vulnerable in the same way as normal enemies.

## Normal vulnerability

The player can damage the boss during normal movement and recovery, but aggressive attacks are risky.

## Stagger vulnerability

When the boss is staggered by a furnace seal:

```text
boss stops attacking
boss takes normal or slightly increased damage
stagger lasts about 2.2 seconds
player gets clear punish window
```

Optional later:

```text
staggered boss takes +25% damage
```

Do not add damage immunity in V24 unless needed. Immunity often feels bad in early prototypes.

---

# 10. Player Failure Rules

Player deaths should feel explainable.

The player should die because:

```text
stood in warned danger
ignored adds
failed to reposition
panicked dash into active lane
stayed greedy during boss wind-up
```

The player should not die because:

```text
invisible hitbox
instant attack
unreadable overlap
camera hiding danger
add spawned on top of player
entire arena became unsafe
```

---

# 11. Victory Reward

When Ash Warden dies, the player gains:

```text
Demo Relic: Cinder Writ
Permanent Ash Sigils reward
Run victory record
```

The Cinder Writ is a proof-of-demo-completion relic. It can unlock or activate the sealed descent door placeholder in the hub later.

Do not implement full post-demo progression yet.

---

# 12. Death Behavior

If the player dies during the boss:

```text
player death animation plays
boss fight stops
run death panel appears
rooms cleared / rewards / sigils gained are shown
player returns to hub
```

This behavior is implemented in V25, not V22.

---

# 13. V23 Arena Implementation Checklist

V23 should implement the arena before boss AI.

Required:

```text
Boss arena room state.
Player entry position.
Boss spawn marker placeholder.
Arena collision bounds.
Four furnace seal nodes/markers.
Two or more chain anchor markers.
Boss gate lock-in.
Victory exit placeholder.
Boss health bar placeholder.
Room intro text: THE SENTENCING FURNACE.
No real boss fight yet, only placeholder boss or dummy.
```

Acceptance for V23:

```text
Player can reach boss antechamber.
Player can enter arena.
Arena locks correctly.
Boss placeholder appears.
Health bar placeholder appears.
Debug/test victory can open exit.
Return loop still works.
```

---

# 14. V24 Boss Implementation Checklist

V24 should implement the actual Ash Warden fight.

Required:

```text
AshWardenBoss.gd
Boss health.
Phase thresholds.
Move scheduler.
Censer Sweep.
Chain Sentence.
Warden Slam.
Binding Lunge.
Falling Cinder.
Summon Penitents.
Final Verdict Pattern.
Furnace Seal Stagger mechanic.
Boss hurt feedback.
Boss death state.
Boss health bar updates.
Victory signal to run controller.
```

Acceptance for V24:

```text
Player can fight the boss.
Boss changes phases.
Every attack warns before damage.
Furnace Seal Stagger works.
Player can die.
Boss can die.
Victory signal fires.
No stuck boss states.
```

---

# 15. Non-Goals

V22 does not implement:

```text
boss code
boss arena
boss sprites
new protagonist art
new permanent upgrades
save data
new full UI system
new enemy roster
new room pool
```

Those belong to later roadmap steps.

---

# 16. Design Lock Summary

The Ash Warden is locked as:

```text
A giant penitential jailer/executioner boss in The Sentencing Furnace.
The fight is built around reading telegraphs, dodging chain lanes, surviving furnace hazards, and baiting the boss into armed furnace seals for stagger windows.
```

The core mechanic is:

```text
Furnace Seal Stagger
```

The signature Phase 3 pattern is:

```text
Final Verdict Pattern
```

The boss should feel like the first real institutional guardian of Hell's machinery.

