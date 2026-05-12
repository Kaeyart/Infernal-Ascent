#!/usr/bin/env python3
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "scripts/iso/room_pipeline/IsoGodotTileRoomLoader.gd",
    "scenes/iso/rooms/circle0/godot_tilemap_room_loader_test.tscn",
    "art/iso/room_kits/circle0/debug_tiles/circle0_iso_debug_tiles.png",
    "tools/room_pipeline/iso_godot_room_tool.py",
    "docs/ISOMETRIC_GODOT_ROOM_PIPELINE_R0_5D.md",
]
RUNTIME_DIR = ROOT / "data" / "rooms" / "circle0" / "tilemap"

errors: list[str] = []
for rel in REQUIRED:
    if not (ROOT / rel).exists():
        errors.append(f"missing required file: {rel}")

script_path = ROOT / "scripts/iso/room_pipeline/IsoGodotTileRoomLoader.gd"
if script_path.exists():
    text = script_path.read_text(encoding="utf-8")
    required_tokens = [
        "TileMapLayer.new()",
        "TileSet.TILE_SHAPE_ISOMETRIC",
        "TileSet.TILE_LAYOUT_DIAMOND_DOWN",
        "set_cell(",
        "y_sort_enabled = true",
        "map_to_local",
        "TileSetAtlasSource.new()",
    ]
    for token in required_tokens:
        if token not in text:
            errors.append(f"loader missing token: {token}")
    # Catch the warning pattern that hit the previous loader: := from Dictionary.get / Variant value.
    suspicious = re.findall(r"var\s+\w+\s*:=\s*[^\n]*\.get\(", text)
    if suspicious:
        errors.append("loader still has Variant inference via := from .get(): " + "; ".join(suspicious[:3]))

if RUNTIME_DIR.exists():
    runtimes = sorted(RUNTIME_DIR.glob("*.tilemap.runtime.json"))
else:
    runtimes = []
if len(runtimes) < 6:
    errors.append(f"expected at least 6 tilemap runtime json files, found {len(runtimes)}")
for runtime in runtimes:
    data = json.loads(runtime.read_text(encoding="utf-8"))
    if data.get("schema_version") != "r0.5d_godot_tilemap_room_v1":
        errors.append(f"{runtime.name}: wrong schema_version")
    if data.get("tile_shape") != "isometric":
        errors.append(f"{runtime.name}: tile_shape is not isometric")
    cells = data.get("tile_layers", {}).get("floor", [])
    if len(cells) < 12:
        errors.append(f"{runtime.name}: not enough floor cells")
    for group in ["gate_sockets", "enemy_spawns", "hazard_sockets"]:
        for i, item in enumerate(data.get(group, [])):
            if "map_x" not in item or "map_y" not in item:
                errors.append(f"{runtime.name}: {group}[{i}] missing map_x/map_y")

if errors:
    print("R0.5D validation failed:")
    for err in errors:
        print(" -", err)
    raise SystemExit(1)
print("R0.5D validation passed: Godot TileMapLayer room pipeline files are present.")
