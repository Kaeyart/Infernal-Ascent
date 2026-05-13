# T-009 — Azazel Boon Mechanics V1

Status target: placeholder mechanics, not final UI or VFX.

This patch makes the first patron lane mechanically visible after the route-gated boon system.

Patron:

```text
Azazel, the Chain-Bound Rebel
```

Implemented placeholder mechanics:

```text
Condemned Mark
Q marks an enemy. A later heavy-style hit can consume the mark for bonus damage.

Iron Sentence
Heavy-style damage adds extra stagger pressure and a small damage bump.

Dragged Below
Heavy-style hits can pull enemies slightly toward the player.

Final Shackle
Judgment Break roots surviving enemies briefly.

Bound Step
Dashing through enemies slows them briefly.

Chain Echo
Every third light hit lashes a nearby enemy for 1 damage.
```

Deferred:

```text
Rebel's Mercy
Rusted Oath
Final icons
Final UI cards
Final chain VFX
Balance tuning
```

Test checklist:

```text
Start a run.
Claim an Azazel boon.
Confirm the player receives the boon without parser errors.
If Condemned Mark appears: use Q on enemy, then heavy/ability hit.
If Bound Step appears: dash through enemy and confirm brief slow/status tint.
If Final Shackle appears: fill Judgment and use ultimate.
If Chain Echo appears: land repeated light hits and confirm nearby lash.
Confirm Mammon/Minos boons can still be claimed without crashing, even if they have no mechanics yet.
```
