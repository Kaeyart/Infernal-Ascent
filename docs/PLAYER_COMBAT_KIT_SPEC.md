# Infernal Ascent V2 — Player Combat Kit Spec

Status: Design Lock Candidate  
Ticket: T-002 — Write Player Combat Kit Spec  
Lane: LOGIC  
Next ticket after acceptance: T-003 — Implement Judgment Meter Placeholder

---

## 1. Purpose

This document locks the first real combat kit for the Penitent Knight.

The current combat is too shallow: the player mostly moves, dashes, and left-clicks a simple area attack. The new kit must give the player clear combat verbs before we add more enemies, patrons, forge marks, weapon ascensions, or boss polish.

This spec defines:

```text
movement role
dash role
light combo role
heavy attack role
Q ability role
ultimate role
Judgment meter rules
hitstop / knockback / stagger rules
cancel rules
UI feedback requirements
placeholder VFX requirements
acceptance tests
```

No final combat art should be made until this spec is accepted and the placeholder implementation proves the kit works.

---

## 2. Design Target

Combat should feel:

```text
heavy
readable
punishing but fair
skill-based
not spammy
not only left-click
built around timing, commitment, and punishment
```

The Penitent Knight is not a fast ninja. He is a heavy crusader/executioner. His combat identity should be:

```text
controlled aggression
deliberate swings
short violent bursts
riposte timing
judgment meter build-up
big execution moments
```

---

## 3. Control Layout

Recommended default inputs:

```text
WASD / Left Stick      Move
Shift / South Face     Dash
Left Mouse / J         Light Attack
Right Mouse / K        Heavy Attack
Q / Left Shoulder      Weapon Skill
R / Right Shoulder     Ultimate
E                    Interact
Esc                  Pause
```

Fallback keyboard-only testing layout:

```text
J = Light Attack
K = Heavy Attack
Q = Weapon Skill
R = Ultimate
Shift = Dash
E = Interact
```

Implementation note:

```text
The input map should support actions, not hardcoded key checks.
```

Required action names:

```text
move_up
move_down
move_left
move_right
dash
attack_light
attack_heavy
weapon_skill
ultimate
interact
```

---

## 4. Movement

Movement should remain understandable and stable before animation polish.

Rules:

```text
Player moves in 2D isometric world space.
Movement acceleration is allowed but should not feel slippery.
Player can turn/face while moving.
Facing direction updates from last meaningful movement input.
If the player stops, idle direction remains the last facing direction.
```

Target feel:

```text
responsive enough for dodging
heavy enough to match the knight fantasy
not floaty
not instant-snappy arcade movement
```

Implementation targets:

```text
walk_speed: current accepted value or 180–220 px/s
acceleration: moderate
deceleration: moderate-fast
minimum input threshold before changing facing: 0.15
```

---

## 5. Dash

Dash is a defensive repositioning tool, not a permanent speed tool.

Rules:

```text
Dash moves in current input direction.
If no input direction exists, dash uses current facing direction.
Dash grants brief invulnerability.
Dash has a clear cooldown.
Dash does not cancel everything for free.
Dash should not slide forever after ending.
```

Suggested timing:

```text
dash_duration: 0.16–0.22 s
dash_iframe_start: 0.02 s
dash_iframe_end: 0.16 s
dash_recovery: 0.08–0.14 s
dash_cooldown: 0.65–0.90 s
```

Dash interaction rules:

```text
Can dash from neutral/movement.
Can dash during light recovery only after a small cancel window.
Cannot dash during heavy windup.
Cannot dash during ultimate.
Can dash after Q recovery unless Q succeeded as riposte, then short lockout applies.
```

Placeholder feedback:

```text
small afterimage/trail
short blue/gold iframe ring or flash
cooldown shown on HUD
```

---

## 6. Light Attack

Light attack is the basic DPS and meter-building tool.

Structure:

```text
Light 1 → Light 2 → Light 3 finisher
```

Role:

```text
fast
low-medium commitment
builds Judgment meter
keeps pressure
safe enough against grunts
not strong enough to solve armored enemies alone
```

Suggested timing:

```text
Light 1:
  windup: 0.08 s
  active: 0.08 s
  recovery: 0.18 s

Light 2:
  windup: 0.09 s
  active: 0.08 s
  recovery: 0.20 s

Light 3:
  windup: 0.12 s
  active: 0.10 s
  recovery: 0.28 s
```

Damage/stagger baseline:

```text
Light 1 damage: 1
Light 2 damage: 1
Light 3 damage: 2
Light 1 stagger: low
Light 2 stagger: low
Light 3 stagger: medium
```

Meter gain:

```text
Light 1 hit: +4 Judgment
Light 2 hit: +4 Judgment
Light 3 hit: +8 Judgment
```

Movement during light attacks:

```text
Light attacks should slow movement, not fully freeze the player.
Movement modifier during windup/active: 30–50%
Movement modifier during recovery: 50–75%
```

Combo rules:

```text
The next light input during recovery queues the next combo step.
Combo resets if no next input after combo_window.
Combo resets after dash unless dash-cancel rules explicitly preserve it later.
Combo resets after heavy/Q/ultimate.
```

Suggested combo window:

```text
0.45–0.70 s after each light hit/recovery start
```

VFX placeholder:

```text
directional pale-gold slash arc
small enemy hit spark
brief hitstop on contact
```

---

## 7. Heavy Attack

Heavy attack is not “light attack but bigger.” It is the stagger and commitment tool.

Role:

```text
higher damage
higher stagger
armor-breaking / guard-breaking role
punishes staggered or marked enemies
works with Chain Saint and Warden Breaker builds
```

Suggested timing:

```text
windup: 0.28–0.38 s
active: 0.12–0.16 s
recovery: 0.42–0.55 s
```

Damage/stagger baseline:

```text
damage: 4
stagger: high
knockback: medium-high
```

Meter gain:

```text
Heavy hit: +12 Judgment
Heavy hit on staggered/marked enemy: +16 Judgment
```

Movement:

```text
Heavy windup: minimal movement or rooted
Heavy active: rooted
Heavy recovery: slow movement returns late
```

Cancel rules:

```text
Cannot be canceled during windup.
Can be dash-canceled only late in recovery.
Cannot be chained into light immediately unless recovery is complete.
```

VFX placeholder:

```text
larger pale-gold slash arc
heavier impact burst
shorter but stronger hitstop
```

---

## 8. Q Ability — Penitent Riposte

Preferred Q ability:

```text
Penitent Riposte
```

Role:

```text
skill-expression defensive punish
rewards reading enemy telegraphs
makes combat more than attacking first
strong synergy with Chain Saint and Blind Judge
```

Core behavior:

```text
Press Q to enter a short guarded stance.
If the player is hit during the guard window, damage is prevented and the player counter-slashes toward the attacker.
If no hit occurs during the guard window, the player performs a weaker forward thrust or exits with recovery.
```

Suggested timing:

```text
startup: 0.06 s
guard_window: 0.22–0.32 s
successful_counter_windup: 0.04 s
successful_counter_active: 0.12 s
successful_counter_recovery: 0.28 s
failed_recovery: 0.42 s
cooldown: 5.5–7.0 s
```

Successful counter:

```text
damage: 3
stagger: high
Judgment gain: +20
brief enemy hitstop
can mark enemy if Blind Judge boon exists
can bind/stagger enemy if Chain Saint boon exists
```

Failed Q:

```text
damage: 1 or 0 depending implementation simplicity
stagger: low or none
Judgment gain: 0
longer recovery than normal attack
```

Simpler fallback if riposte is too complex:

```text
Ashen Cleave
A short-cooldown directional shockwave slash.
damage: 2
stagger: medium
cooldown: 5 s
Judgment gain on hit: +8
```

Decision rule:

```text
Attempt Penitent Riposte first.
Use Ashen Cleave only if riposte blocks implementation/testing.
```

VFX placeholder:

```text
guard ring / brief gold shield flash
counter slash arc
small successful timing flash
cooldown icon on HUD
```

---

## 9. Ultimate — Judgment Break

Ultimate name:

```text
Judgment Break
```

Role:

```text
major execution moment
full-meter payoff
boss/stagger value
run-build payoff
not a normal attack
```

Cost:

```text
100 Judgment meter
```

Suggested timing:

```text
windup: 0.35–0.55 s
active: 0.18–0.25 s
recovery: 0.45–0.65 s
```

Effect:

```text
Large directional execution slash.
High damage.
High stagger.
Bonus damage to staggered, rooted, burning, or Judged enemies depending boons.
```

Baseline:

```text
damage: 8
stagger: very high
boss damage: capped/tuned separately if needed
Judgment cost: 100
```

Safety:

```text
Player should not be fully invulnerable by default.
During windup, player is vulnerable unless later upgraded.
During active frames, brief armor or damage reduction may be allowed if needed.
```

VFX placeholder:

```text
large directional slash
screen shake
hitstop
meter empties on cast
ultimate-ready HUD flash before cast
```

---

## 10. Judgment Meter

Judgment meter is the core combat resource.

Range:

```text
0–100
```

Built by:

```text
Light 1 hit: +4
Light 2 hit: +4
Light 3 hit: +8
Heavy hit: +12
Q successful riposte: +20
Enemy kill: +8
Perfect dash through active danger: +10
Boss stagger event: +15
```

Spent by:

```text
Judgment Break ultimate: -100
```

Reset rules:

```text
Starts at 0 when run starts.
Persists between rooms during a run.
Resets on run death.
Resets on run victory return to hub.
Does not persist as permanent progression.
```

UI requirements:

```text
Meter visible in combat HUD.
Meter should not dominate screen.
At 100, ultimate-ready state is obvious.
When meter gains, small pulse appears.
When ultimate is unavailable, R/Ultimate prompt should look inactive.
```

---

## 11. Stagger Rules

Stagger is the shared enemy-control language for heavy attacks, Chain Saint, Warden Breaker, and boss openings.

Enemy stagger values:

```text
Each enemy has hidden stagger_meter and stagger_threshold.
Light hits add small stagger.
Heavy hits add high stagger.
Q riposte adds high stagger.
Ultimate adds very high stagger.
```

Suggested thresholds:

```text
Ash Grunt: 10
Cinder Lunger: 12
Ember Spitter: 10
Furnace Imp: 8
Chainbound Penitent: 24
Bell Wretch: 10
Ash Warden: phase-specific stagger events, not ordinary full stun spam
```

When staggered:

```text
enemy enters brief stagger state
enemy action is interrupted
enemy takes bonus heavy/ultimate interaction if applicable
stagger meter resets or partially decays
```

Suggested stagger duration:

```text
normal enemies: 0.6–1.1 s
large enemies: 0.4–0.8 s
boss: scripted short opening only
```

---

## 12. Hitstop, Knockback, and Impact

Hitstop gives attacks weight.

Suggested hitstop:

```text
Light hit: 0.035–0.055 s
Light finisher: 0.06–0.08 s
Heavy hit: 0.08–0.11 s
Q counter hit: 0.10–0.13 s
Ultimate hit: 0.14–0.20 s
```

Knockback:

```text
Light 1/2: tiny
Light 3: small
Heavy: medium
Q counter: medium-high
Ultimate: high or stagger-opening
```

Rules:

```text
Knockback must not push enemies through walls.
Knockback must not make enemies unreadable.
Boss knockback is replaced by hit reaction/stagger event.
```

---

## 13. Cancel Rules

Cancel rules prevent spam and define skill.

Baseline:

```text
Movement can continue during light attacks with slow modifier.
Light attacks can queue into next light.
Light attacks cannot instantly cancel into heavy except after recovery.
Light recovery can late-cancel into dash.
Heavy cannot be canceled during windup/active.
Heavy can late-cancel into dash.
Q cannot be canceled during guard window.
Successful Q counter has committed recovery.
Ultimate cannot be canceled.
Taking damage interrupts light/heavy unless player has later boon/armor state.
```

Future boon hooks:

```text
Forge marks or boons may alter cancel rules later.
Those changes must be explicit and shown in reward text.
```

---

## 14. Enemy Interaction Requirements

The first three enemies must teach the new kit.

### Ash Grunt

Should teach:

```text
light combo
basic dash
heavy stagger
```

Interaction:

```text
Light combo can kill it.
Heavy can stagger it.
Q can counter its simple swing.
```

### Cinder Lunger

Should teach:

```text
dash timing
riposte timing
lane telegraph reading
```

Interaction:

```text
Dash avoids lunge.
Q riposte counters lunge if timed.
Heavy can punish recovery.
```

### Ember Spitter

Should teach:

```text
target priority
movement pressure
dash through projectile lines
```

Interaction:

```text
Projectile can be dashed through.
Q may counter projectile only if implementation supports ranged riposte later; not required for first pass.
Light attacks kill quickly once reached.
```

---

## 15. UI Requirements

Combat HUD must show:

```text
health
Judgment meter
Q cooldown
ultimate readiness
active forge mark if any
active ascension if any later
two active patrons later
```

For the first implementation, minimum HUD:

```text
health
Judgment meter
Q cooldown placeholder
ultimate ready marker
```

Do not use large debug panels in combat.

---

## 16. VFX and Audio Placeholder Requirements

For T-003/T-004/T-005 implementation, placeholder VFX are acceptable.

Minimum placeholder VFX:

```text
light slash arc
heavy slash arc
Q guard flash
Q counter slash
ultimate windup ring
ultimate slash
meter gain pulse
hit spark
dash trail
```

Minimum audio hooks:

```text
light attack
heavy attack
Q start
Q success
ultimate start
ultimate hit
meter full
```

Audio can remain procedural placeholder until audio replacement pass.

---

## 17. Art Dependency Rules

Do not produce final art for:

```text
Q animation
ultimate animation
patron VFX
forge VFX
weapon ascension VFX
```

until the logic pass proves the timings and gameplay role work.

Allowed now:

```text
simple arcs
simple rings
simple flashes
debug icons
HUD placeholders
```

---

## 18. Implementation Tickets After This Spec

After this spec is accepted, implement in this order:

```text
T-003 — Judgment Meter Placeholder
T-004 — Q Ability Placeholder
T-005 — Ultimate Placeholder
T-006 — Enemy Interaction Pass for First Three Enemies
```

Do not start patrons before the player has the combat resource and ability hooks needed to support boon effects.

---

## 19. Acceptance Test for Spec

The spec is accepted when:

```text
Player buttons are defined.
Light attack role is defined.
Heavy attack role is defined.
Q role is defined.
Ultimate role is defined.
Judgment meter gain/spend is defined.
Dash role is defined.
Cancel rules are defined.
Enemy interaction requirements are defined.
Art dependencies are clear.
Next implementation tickets are clear.
```

---

## 20. Acceptance Test for First Implementation

When T-003/T-004/T-005 are implemented, test:

```text
Start combat test room.
Move normally.
Dash in each direction.
Use Light 1 → Light 2 → Light 3.
Use heavy attack.
Build Judgment meter through hits.
Use Q successfully.
Use Q unsuccessfully.
Fill Judgment meter to 100.
Use Judgment Break.
Confirm meter empties.
Confirm Q cooldown appears.
Confirm ultimate unavailable when meter is below 100.
Fight Ash Grunt.
Fight Cinder Lunger.
Fight Ember Spitter.
Die and confirm meter resets.
Start another run and confirm meter starts at 0.
```

---

## 21. Commit Message

When this spec is added:

```bash
git add docs/PLAYER_COMBAT_KIT_SPEC.md
git commit -m "Lock player combat kit design"
```
