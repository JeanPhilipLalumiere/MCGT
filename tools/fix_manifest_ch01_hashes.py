#!/usr/bin/env python
from __future__ import annotations

import datetime as dt
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_DIR = ROOT / "zz-manifests"

MANIFEST_PATHS = [
    MANIFEST_DIR / "manifest_publication.json",
    MANIFEST_DIR / "manifest_master.json",
]

# Les 7 fichiers de chapter01 qui doivent être alignés
TARGET_PATHS = [
    "zz-data/chapter01/01_P_derivative_optimized.csv",
    "zz-data/chapter01/01_P_vs_T.dat",
    "zz-data/chapter01/01_dimensionless_invariants.csv",
    "zz-data/chapter01/01_optimized_data.csv",
    "zz-data/chapter01/01_optimized_data_and_derivatives.csv",
    "zz-data/chapter01/01_relative_error_timeline.csv",
    "zz-data/chapter01/01_timeline_milestones.csv",
]


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: Any) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def iter_entry_lists(obj: Any) -> Iterable[list]:
    """
    Génère toutes les listes d'entrées manifest dans la structure,
    c.-à-d. les listes qui contiennent au moins un dict avec 'path'.
    """
    if isinstance(obj, list):
        if any(isinstance(e, dict) and "path" in e for e in obj):
            yield obj
        # On ne descend pas plus profond dans les listes (les entrées sont plates)
        return

    if isinstance(obj, dict):
        for value in obj.values():
            yield from iter_entry_lists(value)


def collect_fs_metadata(rel_path: str) -> dict | None:
    """
    Récupère mtime, mtime_iso, size_bytes et git_hash pour un chemin donné.
    Retourne None si le fichier n'existe pas ou si git échoue.
    """
    path = ROOT / rel_path
    if not path.is_file():
        print(f"[WARN] Fichier introuvable sur le FS: {rel_path}", file=sys.stderr)
        return None

    st = path.stat()
    mtime = int(st.st_mtime)
    mtime_iso = dt.datetime.fromtimestamp(st.st_mtime, dt.timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )
    size_bytes = st.st_size

    try:
        git_hash = (
            subprocess.check_output(
                ["git", "hash-object", rel_path],
                cwd=ROOT,
            )
            .decode()
            .strip()
        )
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] Échec git hash-object pour {rel_path}: {exc}", file=sys.stderr)
        return None

    return {
        "mtime": mtime,
        "mtime_iso": mtime_iso,
        "size_bytes": size_bytes,
        "git_hash": git_hash,
    }


def apply_metadata_to_manifest(manifest: Any, meta_by_path: dict[str, dict]) -> int:
    """
    Applique les métadonnées calculées à toutes les entrées du manifest.
    Retourne le nombre d'entrées mises à jour.
    """
    updated = 0
    for lst in iter_entry_lists(manifest):
        for entry in lst:
            if not isinstance(entry, dict):
                continue
            rel_path = entry.get("path")
            if rel_path is None:
                continue
            meta = meta_by_path.get(rel_path)
            if meta is None:
                continue

            entry["git_hash"] = meta["git_hash"]
            entry["mtime"] = meta["mtime"]
            entry["mtime_iso"] = meta["mtime_iso"]
            entry["size_bytes"] = meta["size_bytes"]
            if "size" in entry:
                entry["size"] = meta["size_bytes"]

            updated += 1
    return updated


def main() -> None:
    # Pré-calcul des métadonnées FS + git pour tous les chemins cibles
    meta_by_path: dict[str, dict] = {}
    for rel_path in TARGET_PATHS:
        meta = collect_fs_metadata(rel_path)
        if meta is not None:
            meta_by_path[rel_path] = meta

    if not meta_by_path:
        print("[ERROR] Aucune métadonnée collectée, abandon.", file=sys.stderr)
        sys.exit(1)

    for manifest_path in MANIFEST_PATHS:
        if not manifest_path.is_file():
            print(f"[WARN] Manifest introuvable: {manifest_path}", file=sys.stderr)
            continue

        backup = manifest_path.with_suffix(
            manifest_path.suffix + ".bak_before_ch01_fixhashes"
        )
        shutil.copy2(manifest_path, backup)
        print(f"[BACKUP] Copie sauvegarde -> {backup}")

        manifest = load_json(manifest_path)
        updated = apply_metadata_to_manifest(manifest, meta_by_path)

        save_json(manifest_path, manifest)

        print(f"[UPDATE] {manifest_path.name} :")
        print(f"         - entrées mises à jour : {updated}")

    print("[DONE] fix_manifest_ch01_hashes terminé.")


if __name__ == "__main__":
    main()
