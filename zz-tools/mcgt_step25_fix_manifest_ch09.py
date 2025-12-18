#!/usr/bin/env python
from __future__ import annotations

import json
import hashlib
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timezone


# Cibles à resynchroniser dans le manifest
TARGETS = [
    "zz-data/chapter09/09_metrics_phase.json",
    "zz-figures/chapter09/09_fig_01_phase_overlay.png",
]

def compute_sha256(path: Path) -> str:
    """Calcule le SHA-256 du fichier donné."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def compute_mtime_iso(path: Path) -> str:
    st = path.stat()
    return (
        datetime.fromtimestamp(st.st_mtime, tz=timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def compute_git_hash_blob(root: Path, relpath: str) -> str:
    """Hash Git de type blob (ce que diag_consistency utilise)."""
    try:
        return subprocess.check_output(
            ["git", "hash-object", "--", relpath],
            cwd=root,
            text=True,
        ).strip()
    except subprocess.CalledProcessError as e:  # noqa: BLE001
        print(f"[ERROR] git hash-object a échoué pour {relpath} : {e}", file=sys.stderr)
        sys.exit(1)


def patch_manifest_entries(obj, relpath: str, payload: dict) -> int:
    """Parcours récursif du JSON pour patcher toutes les entrées correspondant à relpath."""
    patched = 0
    if isinstance(obj, dict):
        path_val = (
            obj.get("path")
            or obj.get("relpath")
            or obj.get("name")
            or obj.get("filename")
        )
        if path_val == relpath:
            obj["size_bytes"] = payload["size_bytes"]
            obj["sha256"] = payload["sha256"]
            obj["mtime_iso"] = payload["mtime_iso"]
            obj["git_hash"] = payload["git_hash"]
            patched += 1
        for v in obj.values():
            patched += patch_manifest_entries(v, relpath, payload)
    elif isinstance(obj, list):
        for item in obj:
            patched += patch_manifest_entries(item, relpath, payload)
    return patched


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    manifest_path = root / "zz-manifests" / "manifest_master.json"

    print("=== STEP25 : resync CH09 metrics & fig dans le manifest ===")
    print(f"[INFO] Repo root      : {root}")
    print(f"[INFO] Manifest path  : {manifest_path}")

    try:
        with manifest_path.open("r", encoding="utf-8") as f:
            manifest = json.load(f)
    except Exception as e:  # noqa: BLE001
        print(f"[ERROR] Impossible de lire le manifest : {e}", file=sys.stderr)
        sys.exit(1)

    total_patched = 0

    for rel in TARGETS:
        path = root / rel
        if not path.is_file():
            print(f"[WARN] Fichier manquant, ignoré : {rel}")
            continue

        size_bytes = path.stat().st_size
        sha256 = compute_sha256(path)
        mtime_iso = compute_mtime_iso(path)
        git_hash = compute_git_hash_blob(root, rel)

        print(f"[INFO] {rel} :")
        print(f"       size_bytes = {size_bytes}")
        print(f"       sha256     = {sha256}")
        print(f"       mtime_iso  = {mtime_iso}")
        print(f"       git_hash   = {git_hash}")

        payload = {
            "size_bytes": size_bytes,
            "sha256": sha256,
            "mtime_iso": mtime_iso,
            "git_hash": git_hash,
        }

        patched = patch_manifest_entries(manifest, rel, payload)
        print(f"[INFO] Blocs patchés pour {rel} : {patched}")
        total_patched += patched

    if total_patched == 0:
        print("[WARN] Aucun bloc mis à jour dans le manifest (vérifier structure / chemins).")
        sys.exit(1)

    try:
        with manifest_path.open("w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, sort_keys=True)
            f.write("\n")
    except Exception as e:  # noqa: BLE001
        print(f"[ERROR] Impossible d'écrire le manifest mis à jour : {e}", file=sys.stderr)
        sys.exit(1)

    print(f"[INFO] Manifest mis à jour : {manifest_path}")
    print(f"[INFO] Total blocs patchés : {total_patched}")


if __name__ == "__main__":
    main()
