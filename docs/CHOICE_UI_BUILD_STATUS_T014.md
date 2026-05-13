# T-014 — Choice UI + Build Status Presentation Pass

Goal: make the current build systems readable without doing final UI art.

This patch improves presentation for:

- Patron route gates
- Gold / health / shop / forge / fountain route gates
- Boon choice interactables
- Forge mark and weapon ascension choices
- Build status in the run HUD payload

It does not add final UI art, enemy art, room art, audio, boss work, or new patrons.

## Acceptance

- Boon cards show a short exact effect before claim.
- Route gates show reward-source consequences when focused.
- HUD receives a build summary line.
- Claimed boons / forge mark / weapon ascension are easier to track.
- Route-gated patron reward flow still works.
- No parser errors.
