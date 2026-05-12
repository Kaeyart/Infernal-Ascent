#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
script = root / "scripts/iso/IsoRoomSetDressing.gd"
doc = root / "docs/ROOM_ART_PASS_V31.md"
errors = []

if not script.exists():
    errors.append(f"Missing {script}")
if not doc.exists():
    errors.append(f"Missing {doc}")

if script.exists():
    text = script.read_text()
    required = [
        "V31 — Room Art Pass V1",
        "room_art_pass_enabled",
        "ambient_ember_enabled",
        "_draw_global_circle0_texture",
        "_draw_foreground_depth_lip",
        "_draw_ambient_embers",
        "_draw_floor_shadow_gradient",
        "_draw_iso_floor_tiles",
        "_draw_floor_cracks",
        "_draw_back_wall_mass",
        "_draw_side_buttress",
        "_draw_soul_intake_rune",
        "_draw_drain_runoff",
        "_draw_heat_haze_band",
        "_draw_chain_anchor",
        "_draw_bone_sort_pile",
        "_draw_penitent_rows",
        "sentencing_furnace",
    ]
    for token in required:
        if token not in text:
            errors.append(f"IsoRoomSetDressing.gd missing token: {token}")
    forbidden = [
        "PlayerSpawn",
        "Enemy 0",
        "RewardSocket",
        "Debug: C",
    ]
    for token in forbidden:
        if token in text:
            errors.append(f"IsoRoomSetDressing.gd still contains live debug token: {token}")

if doc.exists():
    text = doc.read_text()
    for token in ["Goal", "Scope", "Definition of done", "Test checklist"]:
        if token not in text:
            errors.append(f"ROOM_ART_PASS_V31.md missing section: {token}")

if errors:
    print("V31 validation failed:")
    for e in errors:
        print(" -", e)
    raise SystemExit(1)

print("V31 validation passed: room art pass files are present and scoped.")
