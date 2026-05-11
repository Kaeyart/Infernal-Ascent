# Iso Physics Test Player V1

This patch fixes the collision problem in authored iso rooms.

## Problem

The previous test player was a plain `Node2D`.

That means:
- it ignored `StaticBody2D` walls
- it could walk through room collision
- the only barriers were fake hardcoded clamp values

## Fix

This patch adds:

- `scripts/iso/IsoPhysicsTestPlayer.gd`

The runtime adapter now creates `IsoPhysicsTestPlayer`, which extends `CharacterBody2D`, creates a small `CollisionShape2D`, and moves with `move_and_slide()`.

## Files changed

- `scripts/iso/IsoPhysicsTestPlayer.gd`
- `scripts/iso/IsoAuthoredRoomRuntimeAdapter.gd`

## What to test

1. Open your authored iso room.
2. Make sure it has `RuntimeAdapter`.
3. Run with F6.
4. The adapter should print `Created IsoPhysicsTestPlayer.`
5. Try walking into your `StaticBody2D` wall collisions.
6. You should be blocked.
7. Space / left mouse should still attack test enemies.
8. Killing enemies should still spawn the patron altar.

## Legacy player note

If your scene still has an old `IsoTestPlayer` Node2D, the adapter hides it and spawns the physics player instead.
