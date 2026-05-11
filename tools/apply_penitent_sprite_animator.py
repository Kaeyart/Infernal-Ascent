#!/usr/bin/env python3
from pathlib import Path
import re
import shutil

PLAYER_SCENE_CANDIDATES = [
    Path("scenes/actors/Player.tscn"),
    Path("scenes/player/Player.tscn"),
]

player_scene = None
for candidate in PLAYER_SCENE_CANDIDATES:
    if candidate.exists():
        player_scene = candidate
        break

if player_scene is None:
    raise SystemExit("Could not find Player.tscn. Expected scenes/actors/Player.tscn or scenes/player/Player.tscn")

text = player_scene.read_text()
original = text

backup = player_scene.with_suffix(player_scene.suffix + ".bak_penitent_sprite")
if not backup.exists():
    shutil.copyfile(player_scene, backup)
    print(f"Backup written: {backup}")

script_path = 'res://scripts/player/PlayerSpriteAnimator.gd'
ext_id = "PlayerSpriteAnimator_script"

if script_path not in text:
    def bump_load_steps(match):
        value = int(match.group(1))
        return f"[gd_scene load_steps={value + 1}"

    text = re.sub(r"\[gd_scene load_steps=(\d+)", bump_load_steps, text, count=1)

    insert = f'\n[ext_resource type="Script" path="{script_path}" id="{ext_id}"]\n'

    header_end = text.find("\n\n")
    if header_end != -1:
        text = text[:header_end] + insert + text[header_end:]
    else:
        text += insert

if 'name="SpriteAnimator"' not in text:
    sprite_node = '\n\n[node name="SpriteAnimator" type="Node2D" parent="."]\n'
    sprite_node += f'script = ExtResource("{ext_id}")\n'
    sprite_node += 'position = Vector2(0, 0)\n'
    sprite_node += 'z_index = 80\n'
    text = text.rstrip() + sprite_node

lines = text.splitlines()
out = []
inside_visuals_node = False
inserted_visible = False

for line in lines:
    if line.startswith("[node "):
        if inside_visuals_node and not inserted_visible:
            out.append("visible = false")
        inside_visuals_node = 'name="Visuals"' in line
        inserted_visible = False

    out.append(line)

    if inside_visuals_node and line.strip() == "visible = false":
        inserted_visible = True

if inside_visuals_node and not inserted_visible:
    out.append("visible = false")

text = "\n".join(out) + "\n"

if text != original:
    player_scene.write_text(text)
    print(f"Patched {player_scene}: added SpriteAnimator and hid Visuals if present.")
else:
    print("No changes needed.")

print("\nNext: open Godot, refresh FileSystem, then check Player.tscn contains SpriteAnimator.")
