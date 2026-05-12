#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "scripts/iso/room_pipeline/IsoGodotTileRoomLoader.gd",
    "scripts/iso/room_pipeline/GeneratedIsoRoomPlayableTest.gd",
    "scenes/iso/rooms/circle0/generated_iso_room_playable_test.tscn",
    "art/iso/room_kits/circle0/debug_tiles/circle0_iso_debug_tiles.png",
    "data/rooms/circle0/tilemap/ash_intake_hall_iso.room.tilemap.runtime.json",
    "data/rooms/circle0/tilemap/cinder_drain_iso.room.tilemap.runtime.json",
    "data/rooms/circle0/tilemap/furnace_vestibule_iso.room.tilemap.runtime.json",
    "data/rooms/circle0/tilemap/chain_reservoir_iso.room.tilemap.runtime.json",
    "data/rooms/circle0/tilemap/ember_sorting_floor_iso.room.tilemap.runtime.json",
    "data/rooms/circle0/tilemap/penitent_crossing_iso.room.tilemap.runtime.json",
]
SCRIPT_DEPENDENCIES = [
    "scripts/iso/IsoPhysicsTestPlayer.gd",
    "scripts/iso/IsoTestEnemy.gd",
    "scripts/iso/IsoRoomHazard.gd",
    "scripts/iso/RunChoiceGate.gd",
]

def fail(message: str) -> None:
    print(f"[R0.5E][FAIL] {message}")
    raise SystemExit(1)

def main() -> int:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    if missing:
        fail("Missing required files:\n" + "\n".join(missing))
    missing_deps = [p for p in SCRIPT_DEPENDENCIES if not (ROOT / p).exists()]
    if missing_deps:
        fail("Missing existing gameplay dependencies. Install the main game patches first:\n" + "\n".join(missing_deps))
    for room_path in sorted((ROOT / "data/rooms/circle0/tilemap").glob("*.tilemap.runtime.json")):
        data = json.loads(room_path.read_text())
        for key in ["display_name", "tile_layers", "player_spawn", "enemy_spawns", "hazard_sockets", "gate_sockets"]:
            if key not in data:
                fail(f"{room_path} missing key {key}")
        if len(data.get("tile_layers", {}).get("floor", [])) < 12:
            fail(f"{room_path} has too few floor cells")
        if len(data.get("gate_sockets", [])) != 3:
            fail(f"{room_path} must expose exactly three gate sockets")
    script = (ROOT / "scripts/iso/room_pipeline/GeneratedIsoRoomPlayableTest.gd").read_text()
    required_tokens = ["PLAYER_SCRIPT", "ENEMY_SCRIPT", "HAZARD_SCRIPT", "GATE_SCRIPT", "_spawn_player", "_spawn_enemies", "_spawn_hazards", "_spawn_route_gates"]
    for token in required_tokens:
        if token not in script:
            fail(f"Generated playable test missing token: {token}")
    print("[R0.5E][OK] Generated isometric room runtime integration files are present and structurally valid.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
