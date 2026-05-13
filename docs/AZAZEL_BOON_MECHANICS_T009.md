# T-009 — Azazel Boon Mechanics V1

Goal: make the first patron mechanically visible in combat.

This patch does not add final patron art. It wires the Azazel boon payloads into the player/enemy runtime using placeholder effects.

Implemented V1 hooks:

- Iron Sentence: heavy attacks apply extra stagger pressure.
- Bound Step: dashing through enemies slows them briefly.
- Condemned Mark: Q hits mark enemies; the next heavy hit consumes the mark for bonus damage.
- Chain Echo: repeated light hits trigger a small chain lash on a nearby enemy.
- Final Shackle: Judgment Break roots surviving enemies briefly.
- Dragged Below: heavy attacks pull enemies slightly toward the player.
- Rebel's Mercy / Rusted Oath are registered in the player boon list but are deferred for cleaner death/damage-event hooks.

Acceptance:

- Claiming an Azazel boon notifies the player.
- Q, light, heavy, ultimate still work.
- Condemned Mark can be seen through debug prints/meta behavior and heavy bonus damage.
- Bound Step / Final Shackle / Dragged Below visibly affect enemies through placeholder slow/root/pull behavior.
- No parser errors.
