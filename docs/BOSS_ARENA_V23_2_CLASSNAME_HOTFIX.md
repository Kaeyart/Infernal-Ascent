# V23.2 — Boss Arena Parser Hotfix

## Problem

Godot reported:

```text
Unexpected "class_name" in class body. class_name IsoRoomLocalLoopController
```

The controller script should not declare `class_name IsoRoomLocalLoopController` inside/after the script body. The boss placeholder should be loaded explicitly by script path instead of relying on global class resolution.

## Fix

This hotfix:

- removes `class_name IsoRoomLocalLoopController` from `scripts/iso/IsoRoomLocalLoopController.gd`
- removes remaining static `AshWardenBossPlaceholder` type references from the controller
- keeps boss placeholder use preload-based
- removes unnecessary `class_name AshWardenBossPlaceholder` from the placeholder script

## Scope

Parser hotfix only. No gameplay, art, rewards, room flow, or boss AI changes.
