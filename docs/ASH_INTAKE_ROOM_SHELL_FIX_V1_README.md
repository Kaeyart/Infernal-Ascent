# Ash Intake Hall 01 — Room Shell Fix V1

This patch fixes the current room-building issue by adding a real U-shaped shell system for Ash Intake Hall 01.

It includes:

- A sliced East/West structural additions kit under `res://art/rooms/circle0/ash_intake_hall_01/east_west_structural_additions/`
- A reusable shell scene: `res://scenes/rooms/circle0/shells/room_shell_ash_intake_01.tscn`
- A direct working room scene: `res://scenes/rooms/circle0/combat_ash_intake_hall_01.tscn`
- A non-overwriting preview copy: `res://scenes/rooms/circle0/combat_ash_intake_hall_01_shellfix_v1_preview.tscn`

## What changed

The room is now built as:

```text
Art
  L0_Background
  L1_Floor
  L2_Shell
  L3_Props_YSorted
  L4_Foreground
Collision
Markers
```

The important change is `L2_Shell`: it contains the north wall, side returns, side bays, front parapets, and foreground trim. This makes the room read as a real chamber instead of a floor platform with props.

## Install

Back up your current scene first if you have edits:

```bash
cd /home/kaey/Downloads/infernal_ascent_godot_scaffold || exit 1
cp scenes/rooms/circle0/combat_ash_intake_hall_01.tscn scenes/rooms/circle0/combat_ash_intake_hall_01.tscn.bak_before_shell_fix_v1 2>/dev/null || true
unzip -o /home/kaey/Downloads/ash_intake_hall_01_room_shell_fix_v1_patch.zip
```

Open:

```text
res://scenes/rooms/circle0/combat_ash_intake_hall_01.tscn
```

If you do not want to overwrite the live room yet, open:

```text
res://scenes/rooms/circle0/combat_ash_intake_hall_01_shellfix_v1_preview.tscn
```

## Editing rule

Move architecture in `L2_Shell`. Move floor tiles in `L1_Floor`. Move props in `L3_Props_YSorted`. Only put foreground occlusion/chain/shadow pieces in `L4_Foreground`.

Do not rebuild the room from zero. Adjust the shell first, then fill the interior.
