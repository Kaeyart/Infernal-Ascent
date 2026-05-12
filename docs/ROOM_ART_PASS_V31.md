# V31 — Room Art Pass V1

## Goal

Make Circle 0 visually more coherent without changing gameplay logic. This is a code-drawn art pass for the current demo rooms: stronger ash-stone floors, clearer wall mass, better prop language, and more consistent furnace/chain/religious punishment motifs.

This is **not** final environment art. It is the first consistency pass that makes the rooms read less like debug arenas while preserving gameplay readability.

## Scope

Touches:

- `scripts/iso/IsoRoomSetDressing.gd`

Does not touch:

- player art
- enemy art
- enemy AI
- boss mechanics
- reward logic
- save system
- run flow
- room routing
- permanent progression
- UI layout

## What changed

### Global Circle 0 language

All non-minimal rooms now share:

- darker ash-stone base floor
- low-contrast isometric tile lines
- edge lip / foreground depth lines
- stronger back-wall mass
- side buttress mass
- ash scratches
- bone dust
- subtle embers
- cracks and floor wear

### Combat rooms

Each room variant now has a clearer identity hook:

- **Ash Intake Hall**: intake grate, soul/rune receiver, hanging chains
- **Cinder Drain**: stronger drain channels and runoff marks
- **Furnace Vestibule**: furnace heat bands, coal scatter, stronger furnace presence
- **Chain Reservoir**: chain anchors, slick reservoir reflection, heavier chain language
- **Ember Sorting Floor**: sorting belt plus bone/ash sorting piles
- **Penitent Crossing**: kneeling penitent rows, ritual crossing identity

### Support and boss spaces

Existing reward, fountain, forge, shop, boss antechamber, and sentencing furnace drawing remains compatible with current interactions and route flow.

### Debug/readability discipline

The pass does not reintroduce live debug labels. Layout readability marks remain controlled by `show_layout_readability_marks` and default to off.

## Definition of done

- Rooms stop feeling like pure debug arenas.
- Circle 0 identity is more visible.
- Floor and wall language feels consistent.
- Props do not hide enemies, hazards, gates, or rewards.
- Route choice, support rooms, boss arena, and return loop still work.
- No new run-flow behavior is introduced.

## Test checklist

1. Start a run.
2. Enter multiple combat rooms.
3. Confirm the floor/wall/prop language feels more consistent.
4. Confirm enemies, hazards, and player remain readable.
5. Confirm route gates are still easy to see.
6. Enter reward room.
7. Enter fountain room.
8. Enter shop and forge rooms.
9. Reach boss arena.
10. Defeat Ash Warden or complete the run outcome flow.
11. Return to hub.

## Commit command

```bash
git status
git add scripts/iso/IsoRoomSetDressing.gd \
 tools/validate_room_art_pass_v31.py \
 docs/ROOM_ART_PASS_V31.md

git commit -m "Improve Circle 0 room art pass"
```
