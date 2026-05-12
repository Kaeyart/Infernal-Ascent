#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
required_files = [
    ROOT / "scripts/iso/hub/IsoHubRuntimeController.gd",
    ROOT / "scripts/iso/hub/IsoHubStationMarker.gd",
    ROOT / "docs/HUB_STATIONS_V1.md",
]
missing = [str(p) for p in required_files if not p.exists()]
if missing:
    print("[V26] Missing files:")
    for p in missing:
        print(" -", p)
    sys.exit(1)

runtime = (ROOT / "scripts/iso/hub/IsoHubRuntimeController.gd").read_text(encoding="utf-8")
marker = (ROOT / "scripts/iso/hub/IsoHubStationMarker.gd").read_text(encoding="utf-8")

required_runtime_tokens = [
    "V26 — Hub Stations V1",
    "STATION_MARKER_SCRIPT",
    "Hell Gate",
    "Training Yard",
    "Memory Pool",
    "Reliquary Altar",
    "Hub Forge",
    "Codex Lectern",
    "Sealed Descent Door",
    "_spawn_station_markers",
    "_get_station_world_position",
    "_build_reliquary_panel_text",
    "_build_hub_forge_panel_text",
    "_build_codex_panel_text",
]
required_marker_tokens = [
    "class_name IsoHubStationMarker",
    "func setup",
    "func set_focused",
    "station_kind == \"run_start\"",
    "station_kind == \"training_dummy\"",
    "station_kind == \"memory_pool\"",
    "station_kind == \"upgrade_altar\"",
    "station_kind == \"hub_forge\"",
    "station_kind == \"codex\"",
    "station_kind == \"sealed_door\"",
]

errors = []
for token in required_runtime_tokens:
    if token not in runtime:
        errors.append(f"Runtime missing token: {token}")
for token in required_marker_tokens:
    if token not in marker:
        errors.append(f"Marker missing token: {token}")
if "Boss" in runtime and "AshWardenBoss" in runtime:
    errors.append("V26 runtime unexpectedly references boss implementation details.")
if errors:
    print("[V26] Validation failed:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("[V26] Hub Stations V1 files validated.")
print("[V26] This validation checks patch structure only; run the Godot test checklist in-game.")
