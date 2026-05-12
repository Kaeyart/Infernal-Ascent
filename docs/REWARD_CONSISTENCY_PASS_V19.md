# V19 — Reward Consistency Pass

## Goal

Make temporary run rewards clear, useful, and consistently presented.

This follows the Demo Production Bible scope for V19. It standardizes reward data, descriptions, categories, rarity, application logic, panel display, and pickup presentation. It does not touch boss systems, room layouts, enemy AI, permanent upgrades, or save systems.

## What changed

- Replaced the small rough reward list with a standardized 26-boon catalogue.
- Every reward now has:
  - `reward_id`
  - `display_name`
  - `rarity`
  - `category`
  - `description`
  - `exact_effect`
  - `current_consequence`
  - `icon`
- Reward categories are now consistent:
  - Damage
  - Defense
  - Mobility
  - Utility
  - Special
- Reward choices try to avoid duplicate categories inside a single reward room.
- Claimed reward display names are tracked for the run summary.
- Reward pedestals now show rarity/category metadata in-world.
- The reward inspect panel now shows exact effect and current consequence instead of hard-coded vague text.

## Catalogue size

The V19 reward catalogue contains 26 temporary run rewards.

## Definition of done

- Rewards are not vague.
- Rewards affect gameplay.
- Rewards display consistent text.
- Rewards can be tested.
- Reward choices feel meaningful.

## Test checklist

1. Enter a run.
2. Choose Reward from route gates.
3. Walk near each reward pedestal.
4. Confirm the right-side panel shows rarity, category, exact effect, and consequence.
5. Claim one reward.
6. Confirm the other rewards disappear/disable.
7. Confirm the reward affects gameplay.
8. Finish the run.
9. Confirm the run summary lists boon names instead of raw IDs.
10. Confirm route choice / combat / return loop still works.

## Commit message

```bash
git commit -m "Standardize temporary run rewards"
```
