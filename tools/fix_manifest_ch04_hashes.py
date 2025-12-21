#!/usr/bin/env python
import json
import os
import subprocess
import sys
from pathlib import Path
import datetime as dt

ROOT = Path(__file__).resolve().parents[1]

MANIFEST_PATHS = [
    ROOT / "assets/zz-manifests" / "manifest_publication.json",
    ROOT / "assets/zz-manifests" / "manifest_master.json",
]

CH04_PATHS = [
    "assets/zz-data/chapter04/04_P_vs_T.dat",
    "assets/zz-data/chapter04/04_dimensionless_invariants.csv",
    "assets/zz-figures/chapter04/04_fig_01_invariants_schematic.png",
    "assets/zz-figures/chapter04/04_fig_03_invariants_vs_t.png",
]


def get_blob_hash_for_path(rel_path: str) -> str:
    """Hash blob du fichier, comme `git hash-object`."""
    result = subprocess.run(
        ["git", "hash-object", rel_path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def load_manifest(path: Path):
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, list):
        return data, None
    if isinstance(data, dict):
        if isinstance(data.get("entries"), list):
            return data["entries"], "entries"
        if isinstance(data.get("files"), list):
            return data["files"], "files"

    print(f"[ERROR] Manifest inattendu: {path}", file=sys.stderr)
    return None, None


def save_manifest(path: Path, entries, key):
    if key is None:
        data = entries
    else:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        data[key] = entries

    backup = path.with_suffix(path.suffix + ".bak_before_ch04_fixhashes")
    path.rename(backup)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
    print(f"[BACKUP] Copie sauvegarde -> {backup}")
    print("[UPDATE]", path.name, ":")
    print("         - entrées mises à jour : (voir logs ci-dessus)")


def main():
    for manifest in MANIFEST_PATHS:
        entries, key = load_manifest(manifest)
        if entries is None:
            continue

        updated = 0
        for e in entries:
            rel_path = e.get("path")
            if rel_path not in CH04_PATHS:
                continue

            fs_path = ROOT / rel_path
            if not fs_path.exists():
                print(f"[WARN] Fichier introuvable, ignoré : {rel_path}")
                continue

            st = os.stat(fs_path)
            mtime = int(st.st_mtime)
            mtime_iso = dt.datetime.fromtimestamp(st.st_mtime, dt.UTC).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            )

            blob_hash = get_blob_hash_for_path(rel_path)

            e["mtime"] = mtime
            e["mtime_iso"] = mtime_iso
            e["git_hash"] = blob_hash

            print(
                f"[FIX] {manifest.name}: {rel_path} -> "
                f"git_hash={blob_hash}, mtime_iso={mtime_iso}"
            )
            updated += 1

        if updated:
            save_manifest(manifest, entries, key)
            print(
                f"[SUMMARY] {manifest.name} : {updated} entrées chapter04 mises à jour."
            )
        else:
            print(f"[WARN] Aucune entrée chapter04 mise à jour dans {manifest}")

    print("[DONE] fix_manifest_ch04_hashes terminé.")


if __name__ == "__main__":
    main()
