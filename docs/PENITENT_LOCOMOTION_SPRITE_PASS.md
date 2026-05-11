# Penitent Locomotion Sprite Pass

This pass implements the Fallen Crusader / Penitent player locomotion sprites.

Expected source files:

```text
/home/kaey/Desktop/Assets/Penitent_Idle.png
/home/kaey/Desktop/Assets/Penitent_Run.png
/home/kaey/Desktop/Assets/Penitent_Dash.png
```

or folders:

```text
/home/kaey/Desktop/Assets/Penitent_Idle/*.png
/home/kaey/Desktop/Assets/Penitent_Run/*.png
/home/kaey/Desktop/Assets/Penitent_Dash/*.png
```

Each sheet:

```text
4 rows x 4 columns
row 1 = down/front
row 2 = right/east
row 3 = left/west
row 4 = up/back
columns = frames 1-4
```

If left and right are swapped, edit `ROW_NAMES` in `tools/slice_penitent_locomotion.py` and rerun.

## Install

```bash
cd /home/kaey/Downloads/infernal_ascent_godot_scaffold

unzip -o ~/Downloads/penitent_locomotion_sprite_pass.zip
python3 tools/slice_penitent_locomotion.py
python3 tools/apply_penitent_sprite_animator.py
```

Open the contact sheet:

```bash
xdg-open art/actors/player/penitent/_contact_sheet.png
```

Then refresh/reopen Godot.

## Tuning

In `scripts/player/PlayerSpriteAnimator.gd`:

```gdscript
@export var sprite_scale: Vector2 = Vector2(0.32, 0.32)
```

Increase if too small. Decrease if too large.

This pass only handles:

```text
idle
run
dash
```

Attack animations should be a separate pass because they must sync with `WeaponController` attack events.
