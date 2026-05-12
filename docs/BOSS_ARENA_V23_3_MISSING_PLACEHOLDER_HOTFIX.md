# V23.3 — Boss Arena Missing Placeholder Hotfix

## Goal

Fix the parser error:

```text
Could not resolve script "res://scripts/iso/AshWardenBossPlaceholder.gd".
```

## Cause

The V23 controller used a preload for `AshWardenBossPlaceholder.gd`. In some local states Godot parsed the controller before the placeholder script resolved correctly, causing the whole project to fail at parse time.

## Fix

The boss arena placeholder now uses the already-existing `RunRoomInteractable` path instead of preloading a dedicated placeholder script. This keeps V23 as an arena-only milestone and avoids class/preload resolution issues.

## What this does not do

- Does not implement real Ash Warden AI.
- Does not add boss attacks.
- Does not change player art.
- Does not change rewards, enemies, save logic, or run length.

V24 remains the real Ash Warden boss implementation milestone.
