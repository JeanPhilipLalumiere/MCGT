#!/usr/bin/env python
from __future__ import annotations

import json
import hashlib
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timezone


def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    manifest_path = root / "zz-manifests" / "manifest_master.json"
    target_rel = ".gitignore"
    target_path = root / target_rel

    print("=== STEP24 : fix manifest entry for .gitignore (recursive, blob hash) ===")
    print(f"[INFO] Repo root      : {root}")
    print(f"[INFO] Manifest path  : {manifest_path}")
    print(f"[INFO] Target relpath : {target_rel}")

    if not target_path.is_file():
        print(f"[ERROR] Fichier introuvable : {target_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with manifest_path.open("r", encoding="utf-8") as f:
            manifest = json.load(f)
    except Exception as e:  # noqa: BLE001
        print(f"[ERROR] Impossible de lire le manifest : {e}", file=sys.stderr)
        sys.exit(1)

    # Infos réelles du FS
    st = target_path.stat()
    size_bytes = st.st_size
    sha256 = compute_sha256(target_path)
    mtime_iso = (
        datetime.fromtimestamp(st.st_mtime, tz=timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )

    # Hash Git attendu par diag_consistency : hash du blob (git hash-object)
    try:
        git_hash = subprocess.check_output(
            ["git", "hash-object", "--", target_rel],
            cwd=root,
            text=True,
        ).strip()
    except subprocess.CalledProcessError as e:  # noqa: BLE001
        print(
            f"[ERROR] Impossible de récupérer git_hash pour {target_rel} : {e}",
            file=sys.stderr,
        )
        sys.exit(1)

    print("[INFO] Valeurs FS/Git pour .gitignore :")
    print(f"       size_bytes = {size_bytes}")
    print(f"       sha256     = {sha256}")
    print(f"       mtime_iso  = {mtime_iso}")
    print(f"       git_hash   = {git_hash}")

    # Parcours récursif du manifest pour trouver les blocs correspondant à .gitignore
    def patch_obj(obj) -> int:
        patched = 0
        if isinstance(obj, dict):
            path_val = (
                obj.get("path")
                or obj.get("relpath")
                or obj.get("name")
                or obj.get("filename")
            )
            if path_val == target_rel:
                obj["size_bytes"] = size_bytes
                obj["sha256"] = sha256
                obj["mtime_iso"] = mtime_iso
                obj["git_hash"] = git_hash
                patched += 1
            for v in obj.values():
                patched += patch_obj(v)
        elif isinstance(obj, list):
            for item in obj:
                patched += patch_obj(item)
        return patched

    patched_count = patch_obj(manifest)
    if patched_count == 0:
        print(
            "[WARN] Aucun bloc correspondant à .gitignore n'a été trouvé dans le manifest. "
            "Rien n'a été modifié."
        )
        sys.exit(1)

    print(f"[INFO] Blocs .gitignore patchés dans le manifest : {patched_count}")

    try:
        with manifest_path.open("w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, sort_keys=True)
            f.write("\n")
    except Exception as e:  # noqa: BLE001
        print(
            f"[ERROR] Impossible d'écrire le manifest mis à jour : {e}", file=sys.stderr
        )
        sys.exit(1)

    print(f"[INFO] Manifest mis à jour : {manifest_path}")


if __name__ == "__main__":
    main()
