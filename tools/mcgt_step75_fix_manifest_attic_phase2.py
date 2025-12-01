#!/usr/bin/env python
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, List, Dict


def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def compute_git_hash(path: Path) -> str:
    # Blob hash de la version courante sur le disque
    out = subprocess.check_output(["git", "hash-object", str(path)], text=True)
    return out.strip()


def find_entries_list(doc: Any) -> List[Dict[str, Any]]:
    """
    Essaie de retrouver la liste des entrées manifest qui contiennent des dict avec une clé 'path'.
    - Supporte :
      * manifest = [ {...}, {...}, ... ]
      * manifest = {"files": [ {...}, ...], ...}
      * manifest = {"whatever": [ {...}, ...], ...} où le premier élément contient 'path'.
    """
    # Cas 1 : top-level list
    if isinstance(doc, list):
        return doc

    # Cas 2 : dict avec clé 'files'
    if isinstance(doc, dict) and isinstance(doc.get("files"), list):
        return doc["files"]  # type: ignore[return-value]

    # Cas 3 : dict avec une autre clé contenant la vraie liste
    if isinstance(doc, dict):
        for key, value in doc.items():
            if isinstance(value, list) and value:
                first = value[0]
                if isinstance(first, dict) and "path" in first:
                    # On suppose que c’est la bonne liste d’entrées
                    return value  # type: ignore[return-value]

    raise RuntimeError("Impossible de trouver la liste des entrées manifest (pas de liste de dict avec 'path').")


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    manifest_path = repo_root / "zz-manifests" / "manifest_master.json"

    if not manifest_path.is_file():
        print(f"[ERROR] Manifest introuvable : {manifest_path}", file=sys.stderr)
        sys.exit(1)

    print(f"[INFO] Repo root      : {repo_root}")
    print(f"[INFO] Manifest path  : {manifest_path}")

    raw = manifest_path.read_text(encoding="utf-8")
    try:
        doc = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"[ERROR] JSON invalide dans manifest_master.json : {e}", file=sys.stderr)
        sys.exit(1)

    try:
        entries = find_entries_list(doc)
    except RuntimeError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)

    mapping = {
        # CH09
        "zz-data/chapter09/09_comparison_milestones.flagged.csv": "attic/zz-data/chapter09/09_comparison_milestones.flagged.csv",
        "zz-data/chapter09/09_phase_diff.csv": "attic/zz-data/chapter09/09_phase_diff.csv",
        "zz-scripts/chapter09/check_p95_methods.py": "attic/zz-scripts/chapter09/check_p95_methods.py",
        "zz-scripts/chapter09/flag_jalons.py": "attic/zz-scripts/chapter09/flag_jalons.py",
        # CH10
        "zz-data/chapter10/10_mc_results.circ.agg.csv": "attic/zz-data/chapter10/10_mc_results.circ.agg.csv",
        "zz-scripts/chapter10/diag_phi_fpeak.py": "attic/zz-scripts/chapter10/diag_phi_fpeak.py",
        "zz-scripts/chapter10/inspect_topk_residuals.py": "attic/zz-scripts/chapter10/inspect_topk_residuals.py",
        "zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py": "attic/zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py",
    }

    patched = 0

    for old_path, new_path in mapping.items():
        fs_path = repo_root / new_path
        if not fs_path.exists():
            print(f"[WARN] Fichier cible manquant, on ignore : {new_path}", file=sys.stderr)
            continue

        st = fs_path.stat()
        size = int(st.st_size)
        mtime = int(st.st_mtime)
        mtime_iso = datetime.fromtimestamp(st.st_mtime, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        sha256 = compute_sha256(fs_path)
        git_hash = compute_git_hash(fs_path)

        print(f"[INFO] FS/Git pour {new_path} :")
        print(f"       size_bytes = {size}")
        print(f"       sha256     = {sha256}")
        print(f"       mtime_iso  = {mtime_iso}")
        print(f"       git_hash   = {git_hash}")

        found = False

        # 1) cas principal : entrée encore sur l'ancien path
        for entry in entries:
            if entry.get("path") == old_path:
                entry["path"] = new_path
                entry["size"] = size
                entry["size_bytes"] = size
                entry["mtime"] = mtime
                entry["mtime_iso"] = mtime_iso
                entry["sha256"] = sha256
                entry["git_hash"] = git_hash
                patched += 1
                found = True
                print(f"[INFO] Patché manifest : {old_path} -> {new_path}")
                break

        if found:
            continue

        # 2) fallback : entrée déjà sur le nouveau path, on ne fait que rafraîchir les champs
        for entry in entries:
            if entry.get("path") == new_path:
                entry["size"] = size
                entry["size_bytes"] = size
                entry["mtime"] = mtime
                entry["mtime_iso"] = mtime_iso
                entry["sha256"] = sha256
                entry["git_hash"] = git_hash
                patched += 1
                found = True
                print(f"[INFO] Rafraîchi manifest existant pour {new_path}")
                break

        if not found:
            print(f"[WARN] Aucune entrée trouvée dans le manifest pour {old_path} ni {new_path}", file=sys.stderr)

    backup_path = manifest_path.with_suffix(".json.bak_step75_attic")
    backup_path.write_text(raw, encoding="utf-8")
    print(f"[INFO] Backup manifest -> {backup_path}")

    manifest_path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[INFO] Manifest mis à jour : {manifest_path}")
    print(f"[INFO] Entrées patchées : {patched}")


if __name__ == "__main__":
    main()
