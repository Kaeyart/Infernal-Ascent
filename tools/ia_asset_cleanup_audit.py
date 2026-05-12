#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import datetime as dt
import fnmatch
import json
import shutil
from pathlib import Path

ROOT = Path.cwd()
ART_ROOTS = [Path("art")]
ASSET_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".ase", ".aseprite"}
TEXT_EXTS = {".tscn", ".tres", ".gd", ".godot", ".cfg", ".json", ".csv", ".md", ".txt"}
EXCLUDE_DIRS = {".git", ".godot", ".import", "__pycache__", "_quarantine_unused_art", "builds", "exports"}
PRODUCTION_SOURCE_PATTERNS = [
    "art/**/source_sheets/**",
    "art/**/contact_sheets/**",
    "art/**/*manifest*",
    "art/**/*.csv",
    "art/**/*.json",
]

def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()

def excluded(p: Path) -> bool:
    return any(part in EXCLUDE_DIRS for part in p.parts)

def match_any(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pat) for pat in patterns)

def iter_project_files():
    for p in ROOT.rglob("*"):
        if p.is_file() and not excluded(p):
            yield p

def collect_assets() -> list[Path]:
    out = []
    for art_root in ART_ROOTS:
        full = ROOT / art_root
        if not full.exists():
            continue
        for p in full.rglob("*"):
            if p.is_file() and not excluded(p) and p.suffix.lower() in ASSET_EXTS:
                out.append(p)
    return sorted(out)

def collect_reference_text() -> dict[str, str]:
    refs = {}
    for p in iter_project_files():
        if p.suffix.lower() == ".import":
            continue
        if p.suffix.lower() not in TEXT_EXTS:
            continue
        try:
            refs[rel(p)] = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            pass
    return refs

def import_companion(asset: Path) -> str:
    imp = asset.with_name(asset.name + ".import")
    return rel(imp) if imp.exists() else ""

def is_used(asset_rel: str, texts: dict[str, str]) -> tuple[bool, list[str]]:
    needles = [
        f"res://{asset_rel}",
        asset_rel,
        f"res://{asset_rel.replace(' ', '%20')}",
        asset_rel.replace(" ", "%20"),
    ]
    found = []
    for text_path, content in texts.items():
        if any(n in content for n in needles):
            found.append(text_path)
    return bool(found), found

def classify() -> dict:
    texts = collect_reference_text()
    used, unused, production = [], [], []
    for asset in collect_assets():
        a_rel = rel(asset)
        used_flag, refs = is_used(a_rel, texts)
        row = {
            "path": a_rel,
            "size_bytes": asset.stat().st_size,
            "referenced_by": refs,
            "import_companion": import_companion(asset),
        }
        if used_flag:
            used.append(row)
        elif match_any(a_rel, PRODUCTION_SOURCE_PATTERNS):
            row["reason"] = "production_source_or_manifest"
            production.append(row)
        else:
            row["reason"] = "not_referenced_by_runtime_text_files"
            unused.append(row)
    return {
        "generated_at": dt.datetime.now().isoformat(timespec="seconds"),
        "counts": {
            "used_runtime_assets": len(used),
            "unused_runtime_candidates": len(unused),
            "production_sources_not_runtime": len(production),
            "total_art_assets_scanned": len(used) + len(unused) + len(production),
            "text_files_scanned": len(texts),
        },
        "used_runtime_assets": used,
        "unused_runtime_candidates": unused,
        "production_sources_not_runtime": production,
    }

def write_report(data: dict):
    docs = ROOT / "docs"
    docs.mkdir(exist_ok=True)
    (docs / "ASSET_CLEANUP_AUDIT_V1.json").write_text(json.dumps(data, indent=2), encoding="utf-8")

    with (docs / "ASSET_CLEANUP_UNUSED_CANDIDATES_V1.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["path", "size_bytes", "reason", "import_companion"])
        for row in data["unused_runtime_candidates"]:
            w.writerow([row["path"], row["size_bytes"], row["reason"], row["import_companion"]])

    lines = ["# Asset Cleanup Audit V1", "", "## Counts", ""]
    for k, v in data["counts"].items():
        lines.append(f"- `{k}`: **{v}**")
    lines += ["", "## Runtime-used assets that stay", ""]
    for row in data["used_runtime_assets"][:120]:
        refs = ", ".join(row["referenced_by"][:3])
        lines.append(f"- `{row['path']}` — used by `{refs}`")
    if len(data["used_runtime_assets"]) > 120:
        lines.append(f"- ... plus {len(data['used_runtime_assets']) - 120} more.")

    lines += ["", "## Unused runtime candidates", ""]
    for row in data["unused_runtime_candidates"][:220]:
        lines.append(f"- `{row['path']}`")
    if len(data["unused_runtime_candidates"]) > 220:
        lines.append(f"- ... plus {len(data['unused_runtime_candidates']) - 220} more.")

    lines += ["", "## Production sources not used at runtime", ""]
    for row in data["production_sources_not_runtime"][:120]:
        lines.append(f"- `{row['path']}`")
    if len(data["production_sources_not_runtime"]) > 120:
        lines.append(f"- ... plus {len(data['production_sources_not_runtime']) - 120} more.")

    lines += ["", "## Commands", "", "```bash",
              "python3 tools/ia_asset_cleanup_audit.py audit",
              "python3 tools/ia_asset_cleanup_audit.py quarantine --apply",
              "python3 tools/ia_asset_cleanup_audit.py restore --manifest _quarantine_unused_art/<folder>/RESTORE_MANIFEST.json --apply",
              "python3 tools/ia_asset_cleanup_audit.py delete-quarantine --apply",
              "```", ""]
    (docs / "ASSET_CLEANUP_AUDIT_V1.md").write_text("\n".join(lines), encoding="utf-8")
    print("[audit] wrote docs/ASSET_CLEANUP_AUDIT_V1.md")
    print("[audit] wrote docs/ASSET_CLEANUP_AUDIT_V1.json")
    print("[audit] wrote docs/ASSET_CLEANUP_UNUSED_CANDIDATES_V1.csv")

def quarantine(data: dict, include_sources: bool, apply: bool):
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    qroot = ROOT / "_quarantine_unused_art" / f"unused_art_{stamp}"
    rows = list(data["unused_runtime_candidates"])
    if include_sources:
        rows += list(data["production_sources_not_runtime"])

    moves = []
    for row in rows:
        src = ROOT / row["path"]
        if src.exists():
            moves.append((src, qroot / row["path"], "asset"))
        imp = row.get("import_companion", "")
        if imp:
            isrc = ROOT / imp
            if isrc.exists():
                moves.append((isrc, qroot / imp, "import_companion"))

    print(f"[quarantine] files to move: {len(moves)}")
    print(f"[quarantine] destination: {qroot}")
    if not apply:
        print("[quarantine] dry run only. Add --apply to move.")
        return

    manifest_rows = []
    for src, dst, kind in moves:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        manifest_rows.append({"kind": kind, "original": rel(src), "quarantine": dst.relative_to(qroot).as_posix()})
    qroot.mkdir(parents=True, exist_ok=True)
    (qroot / "RESTORE_MANIFEST.json").write_text(json.dumps({
        "created_at": dt.datetime.now().isoformat(timespec="seconds"),
        "quarantine_root": str(qroot),
        "entries": manifest_rows,
    }, indent=2), encoding="utf-8")
    print(f"[quarantine] moved {len(moves)} files.")
    print(f"[quarantine] restore manifest: {qroot / 'RESTORE_MANIFEST.json'}")

def restore(manifest: Path, apply: bool):
    data = json.loads(manifest.read_text(encoding="utf-8"))
    qroot = Path(data["quarantine_root"])
    entries = data["entries"]
    print(f"[restore] files to restore: {len(entries)}")
    if not apply:
        print("[restore] dry run only. Add --apply.")
        return
    for row in entries:
        src = qroot / row["quarantine"]
        dst = ROOT / row["original"]
        if src.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))
    print("[restore] done.")

def delete_quarantine(apply: bool):
    qroot = ROOT / "_quarantine_unused_art"
    print(f"[delete-quarantine] target: {qroot}")
    if not qroot.exists():
        print("[delete-quarantine] no quarantine folder.")
        return
    if not apply:
        print("[delete-quarantine] dry run only. Add --apply.")
        return
    shutil.rmtree(qroot)
    print("[delete-quarantine] deleted.")

def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("audit")
    q = sub.add_parser("quarantine")
    q.add_argument("--apply", action="store_true")
    q.add_argument("--include-production-sources", action="store_true")
    r = sub.add_parser("restore")
    r.add_argument("--manifest", required=True)
    r.add_argument("--apply", action="store_true")
    d = sub.add_parser("delete-quarantine")
    d.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    if args.cmd == "audit":
        data = classify()
        write_report(data)
        print(json.dumps(data["counts"], indent=2))
    elif args.cmd == "quarantine":
        data = classify()
        write_report(data)
        quarantine(data, args.include_production_sources, args.apply)
    elif args.cmd == "restore":
        restore(Path(args.manifest), args.apply)
    elif args.cmd == "delete-quarantine":
        delete_quarantine(args.apply)

if __name__ == "__main__":
    main()
