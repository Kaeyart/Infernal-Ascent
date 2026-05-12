# V23 — Boss Arena V1

## Goal

Build the physical Ash Warden boss arena without implementing the real boss fight yet.

This follows the Production Bible: V23 is the boss arena milestone. The real Ash Warden AI, phases, damage windows, and fight implementation are reserved for V24.

## What this patch adds

- The Sealed Ash Warden Gate no longer completes the run directly.
- Interacting with the sealed gate now moves the player into **The Sentencing Furnace**.
- The Sentencing Furnace has a dedicated boss-arena dressing variant.
- The arena has a safe player entry position, boss placeholder spawn point, boss exit point, and visual furnace/seal sockets.
- A non-combat **Ash Warden Placeholder** appears inside the arena.
- The placeholder has a visible boss-style nameplate and health bar.
- Pressing E near the placeholder breaks the seal and opens a victory exit marker.
- Pressing E at the victory exit completes the demo route and returns through the existing run-complete flow.

## What this patch does not do

- No real boss AI.
- No boss damage phases.
- No new enemies.
- No reward changes.
- No save changes.
- No player art changes.

## Test checklist

1. Start a run.
2. Clear enough rooms to reach Boss Antechamber.
3. Interact with the Sealed Ash Warden Gate.
4. Confirm the player enters The Sentencing Furnace.
5. Confirm the door/arena presentation reads as a boss arena.
6. Confirm the Ash Warden placeholder appears inside the room.
7. Confirm the boss-style health bar/nameplate appears.
8. Approach the placeholder and press E.
9. Confirm an exit marker opens.
10. Use the exit marker.
11. Confirm the normal run-complete panel appears.
12. Press E to return to hub.

## Acceptance

Accept only if the arena is readable, the placeholder is inside the room, the exit flow works, and there are no parser errors.
