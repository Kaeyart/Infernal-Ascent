#!/usr/bin/env python3
"""R0.5D Godot TileMapLayer room export tool.

Converts R0.5B isometric room specs into Godot-friendly runtime JSON built around
TileMapLayer cells, not arbitrary draw polygons.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SPEC_DIR = ROOT / "rooms" / "circle0"
OUT_DIR = ROOT / "data" / "rooms" / "circle0" / "tilemap"
PREVIEW_DIR = ROOT / "preview" / "rooms" / "tilemap"
TILE_W = 96
TILE_H = 48


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def point_in_poly(x: float, y: float, poly: list[list[float]]) -> bool:
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = float(poly[i][0]), float(poly[i][1])
        xj, yj = float(poly[j][0]), float(poly[j][1])
        if ((yi > y) != (yj > y)):
            x_intersect = (xj - xi) * (y - yi) / max(0.000001, (yj - yi)) + xi
            if x < x_intersect:
                inside = not inside
        j = i
    return inside


def map_to_world(mx: int, my: int) -> tuple[float, float]:
    # Same logical isometric transform used by the tool and mirrored by Godot TileMapLayer.
    return ((mx - my) * (TILE_W * 0.5), (mx + my) * (TILE_H * 0.5))


def world_to_map(x: float, y: float) -> tuple[int, int]:
    mx = (y / (TILE_H * 0.5) + x / (TILE_W * 0.5)) * 0.5
    my = (y / (TILE_H * 0.5) - x / (TILE_W * 0.5)) * 0.5
    return (int(round(mx)), int(round(my)))


def make_floor_cells(poly: list[list[float]]) -> list[dict[str, Any]]:
    xs = [float(p[0]) for p in poly]
    ys = [float(p[1]) for p in poly]
    min_x, max_x = min(xs) - TILE_W, max(xs) + TILE_W
    min_y, max_y = min(ys) - TILE_H, max(ys) + TILE_H
    # Convert the expanded bounding box to a generous map-coordinate range.
    corners = [world_to_map(min_x, min_y), world_to_map(min_x, max_y), world_to_map(max_x, min_y), world_to_map(max_x, max_y)]
    min_mx = min(c[0] for c in corners) - 2
    max_mx = max(c[0] for c in corners) + 2
    min_my = min(c[1] for c in corners) - 2
    max_my = max(c[1] for c in corners) + 2
    cells: list[dict[str, Any]] = []
    for mx in range(min_mx, max_mx + 1):
        for my in range(min_my, max_my + 1):
            wx, wy = map_to_world(mx, my)
            if point_in_poly(wx, wy, poly):
                tile = "floor"
                # Mild deterministic floor variation.
                if (mx * 17 + my * 31) % 11 == 0:
                    tile = "cracked_floor"
                cells.append({"x": mx, "y": my, "tile": tile})
    cells.sort(key=lambda c: (int(c["x"]) + int(c["y"]), int(c["x"])))
    return cells


def with_map_pos(obj: dict[str, Any]) -> dict[str, Any]:
    out = dict(obj)
    mx, my = world_to_map(float(obj.get("x", 0.0)), float(obj.get("y", 0.0)))
    out["map_x"] = mx
    out["map_y"] = my
    return out


def export_spec(spec_path: Path) -> Path:
    spec = load_json(spec_path)
    poly = spec.get("iso_floor_polygon", [])
    if not isinstance(poly, list) or len(poly) < 3:
        raise SystemExit(f"{spec_path}: missing iso_floor_polygon")
    floor_cells = make_floor_cells(poly)
    runtime: dict[str, Any] = {
        "schema_version": "r0.5d_godot_tilemap_room_v1",
        "source_spec": str(spec_path.relative_to(ROOT)),
        "id": spec.get("id", spec_path.stem),
        "display_name": spec.get("display_name", spec_path.stem),
        "template": spec.get("template", "iso_room"),
        "tile_size": {"x": TILE_W, "y": TILE_H},
        "tile_shape": "isometric",
        "tile_layout": "diamond_down",
        "iso_floor_polygon": poly,
        "wall_height": spec.get("wall_height", 96),
        "tile_layers": {
            "floor": floor_cells,
            "decals": [],
            "blocking": [],
        },
        "player_spawn": with_map_pos(spec.get("player_spawn", {"x": 0, "y": 0})),
        "gate_sockets": [with_map_pos(g) for g in spec.get("gate_sockets", [])],
        "enemy_spawns": [with_map_pos(e) for e in spec.get("enemy_spawns", [])],
        "hazard_sockets": [with_map_pos(h) for h in spec.get("hazard_sockets", [])],
        "dressing_zones": {
            "floor_props": [with_map_pos(p) for p in spec.get("dressing_zones", {}).get("floor_props", [])],
            "wall_props": [with_map_pos(p) for p in spec.get("dressing_zones", {}).get("wall_props", [])],
        },
        "combat_notes": spec.get("combat_notes", ""),
        "validation": {
            "floor_cell_count": len(floor_cells),
            "uses_godot_tilemap_layer": True,
            "actors_use_y_sort_world_layer": True,
        }
    }
    out_path = OUT_DIR / f"{spec_path.stem}.tilemap.runtime.json"
    save_json(out_path, runtime)
    return out_path


def validate_runtime(path: Path) -> list[str]:
    data = load_json(path)
    errors: list[str] = []
    if data.get("schema_version") != "r0.5d_godot_tilemap_room_v1":
        errors.append("wrong schema_version")
    cells = data.get("tile_layers", {}).get("floor", [])
    if not cells:
        errors.append("no floor cells")
    if len(cells) < 12:
        errors.append("too few floor cells for a combat room")
    for key in ["player_spawn", "gate_sockets", "enemy_spawns", "hazard_sockets"]:
        if key not in data:
            errors.append(f"missing {key}")
    for key in ["gate_sockets", "enemy_spawns", "hazard_sockets"]:
        for index, item in enumerate(data.get(key, [])):
            if "map_x" not in item or "map_y" not in item:
                errors.append(f"{key}[{index}] missing map_x/map_y")
    return errors


def build_all() -> None:
    specs = sorted(SPEC_DIR.glob("*_iso.room.json"))
    if not specs:
        raise SystemExit(f"No room specs found in {SPEC_DIR}")
    print("Exporting Godot TileMapLayer runtime rooms...")
    for spec in specs:
        out = export_spec(spec)
        errors = validate_runtime(out)
        if errors:
            print(f"FAIL {out}: {errors}")
            raise SystemExit(1)
        print(f"OK {out}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["build-all", "export", "validate"])
    parser.add_argument("path", nargs="?")
    args = parser.parse_args()
    if args.command == "build-all":
        build_all()
    elif args.command == "export":
        if not args.path:
            raise SystemExit("export requires room spec path")
        print(export_spec(ROOT / args.path))
    elif args.command == "validate":
        if not args.path:
            raise SystemExit("validate requires runtime json path")
        errors = validate_runtime(ROOT / args.path)
        if errors:
            for e in errors:
                print(f"FAIL: {e}")
            raise SystemExit(1)
        print("OK")


if __name__ == "__main__":
    main()
