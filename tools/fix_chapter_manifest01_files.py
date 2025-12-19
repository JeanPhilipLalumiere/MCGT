#!/usr/bin/env python
from __future__ import annotations

import hashlib
import json
import subprocess
import datetime as dt
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PUB = ROOT / "zz-manifests" / "manifest_publication.json"
MANIFEST_MASTER = ROOT / "zz-manifests" / "manifest_master.json"

# Fichiers à ajouter pour le chapitre 01
TARGETS = [
    "zz-data/chapter01/01_P_vs_T.meta.json",
    "zz-data/chapter01/01_optimized_data.meta.json",
    "01-introduction-applications/CHAPTER1_GUIDE.txt",
]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def git_hash_for(path: Path) -> str:
    try:
        out = subprocess.check_output(
            ["git", "log", "-n1", "--pretty=%H", "--", str(path)],
            cwd=str(ROOT),
            stderr=subprocess.DEVNULL,
        )
        return out.decode().strip() or "GIT_HASH_MISSING"
    except Exception:
        return "GIT_HASH_MISSING"


def build_entry(rel_path: str) -> dict:
    p = ROOT / rel_path
    if not p.is_file():
        print(f"[ERROR] Fichier introuvable sur le FS: {rel_path}", file=sys.stderr)
        return {}

    st = p.stat()
    mtime = int(st.st_mtime)
    mtime_iso = dt.datetime.fromtimestamp(st.st_mtime, dt.timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )
    sha = sha256_file(p)
    git_hash = git_hash_for(p)

    # rôle simple mais suffisant pour diag_consistency
    if rel_path.endswith(".meta.json"):
        role = "meta"
    elif rel_path.endswith(".txt"):
        role = "other"
    else:
        role = "data"

    return {
        "path": rel_path,
        "role": role,
        "sha256": sha,
        "size": st.st_size,
        "size_bytes": st.st_size,
        "mtime": mtime,
        "mtime_iso": mtime_iso,
        "git_hash": git_hash,
    }


def load_manifest(path: Path) -> list[dict]:
    if not path.is_file():
        print(f"[ERROR] Manifest introuvable: {path}", file=sys.stderr)
        sys.exit(1)
    raw = path.read_text(encoding="utf-8")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"[ERROR] JSON invalide dans {path}: {e}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, list):
        print(
            f"[ERROR] Manifest inattendu (on attend une liste): {path}", file=sys.stderr
        )
        sys.exit(1)
    return data


def save_manifest(path: Path, data: list[dict], backup_suffix: str) -> None:
    backup = path.with_suffix(path.suffix + backup_suffix)
    backup.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
    print(f"[BACKUP] Copie sauvegarde -> {backup}")
    path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")


def ensure_entries(manifest: list[dict], label: str) -> int:
    existing_paths = {e.get("path") for e in manifest if isinstance(e, dict)}
    added = 0
    for rel in TARGETS:
        if rel in existing_paths:
            continue
        entry = build_entry(rel)
        if not entry:
            continue
        manifest.append(entry)
        added += 1
        print(f"[ADD-{label}] {rel}")
    return added


def main() -> None:
    pub = load_manifest(MANIFEST_PUB)
    master = load_manifest(MANIFEST_MASTER)

    added_pub = ensure_entries(pub, "PUB")
    added_master = ensure_entries(master, "MASTER")

    if added_pub:
        save_manifest(MANIFEST_PUB, pub, ".bak_before_ch01_files_fix_pub")
        print(f"[UPDATE] manifest_publication.json : +{added_pub} entrées")
    else:
        print("[UPDATE] manifest_publication.json : aucune entrée ajoutée")

    if added_master:
        save_manifest(MANIFEST_MASTER, master, ".bak_before_ch01_files_fix_master")
        print(f"[UPDATE] manifest_master.json : +{added_master} entrées")
    else:
        print("[UPDATE] manifest_master.json : aucune entrée ajoutée")

    print("[DONE] fix_chapter_manifest01_files terminé.")


if __name__ == "__main__":
    main()
