#!/usr/bin/env python3
from pathlib import Path
import re
import shutil

PROJECT = Path("/home/kaey/Downloads/infernal_ascent_godot_scaffold")
candidates = [
    PROJECT / "scenes/actors/Player.tscn",
    PROJECT / "scenes/player/Player.tscn",
]

player_scene = None
for candidate in candidates:
    if candidate.exists():
        player_scene = candidate
        break

if player_scene is None:
    raise SystemExit("Could not find Player.tscn")

text = player_scene.read_text()
original = text

backup = player_scene.with_suffix(player_scene.suffix + ".bak_penitent_idle_clean")
if not backup.exists():
    shutil.copyfile(player_scene, backup)
    print(f"Backup written: {backup}")

script_path = 'res://scripts/player/PlayerSpriteAnimator.gd'
ext_id = "PlayerSpriteAnimator_script"

if script_path not in text:
    text = re.sub(
        r"\[gd_scene load_steps=(\d+)",
        lambda m: f"[gd_scene load_steps={int(m.group(1)) + 1}",
        text,
        count=1
    )

    insert = f'\n[ext_resource type="Script" path="{script_path}" id="{ext_id}"]\n'
    header_end = text.find("\n\n")

    if header_end != -1:
        text = text[:header_end] + insert + text[header_end:]
    else:
        text += insert

if 'name="SpriteAnimator"' not in text:
    text = text.rstrip()
    text += '\n\n[node name="SpriteAnimator" type="Node2D" parent="."]\n'
    text += f'script = ExtResource("{ext_id}")\n'
    text += 'position = Vector2(0, 0)\n'
    text += 'z_index = 80\n'

# Hide procedural Visuals child to avoid drawing two players.
lines = text.splitlines()
out = []
inside_visuals = False
has_visible_line = False

for line in lines:
    if line.startswith("[node "):
        if inside_visuals and not has_visible_line:
            out.append("visible = false")

        inside_visuals = 'name="Visuals"' in line
        has_visible_line = False

    if inside_visuals and line.strip().startswith("visible ="):
        line = "visible = false"
        has_visible_line = True

    out.append(line)

if inside_visuals and not has_visible_line:
    out.append("visible = false")

text = "\n".join(out) + "\n"

if text != original:
    player_scene.write_text(text)
    print(f"Patched {player_scene}")
else:
    print("No Player.tscn changes needed")
