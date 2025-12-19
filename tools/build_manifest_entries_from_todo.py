#!/usr/bin/env python
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import datetime as dt


ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "_tmp"


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def detect_kind_role(rel: str) -> tuple[str, str]:
    if rel.startswith("zz-data/"):
        if rel.endswith(".meta.json"):
            return "data_meta", "chapter_meta"
        else:
            return "data", "chapter_data"
    if rel.startswith("zz-figures/"):
        return "figure", "chapter_figure"
    if rel.startswith("zz-scripts/"):
        return "script", "chapter_script"
    # guides / autres
    return "other", "chapter_other"


def git_last_hash(rel: str) -> str | None:
    try:
        out = subprocess.check_output(
            ["git", "log", "-1", "--format=%H", "--", rel],
            cwd=ROOT,
        )
        return out.decode("utf-8").strip() or None
    except subprocess.CalledProcessError:
        return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Génère _tmp/chapterXX_manifest_entries.{tsv,json} à partir du TODO chapterXX."
    )
    parser.add_argument(
        "--chapter",
        "-c",
        type=int,
        required=True,
        help="Numéro de chapitre (ex: 3 pour chapter03)",
    )
    args = parser.parse_args()
    chapter_str = f"{args.chapter:02d}"

    todo_path = TMP_DIR / f"chapter{chapter_str}_manifest_todo.txt"
    if not todo_path.is_file():
        print(f"[ERROR] TODO introuvable : {todo_path}", file=sys.stderr)
        sys.exit(1)

    entries = []
    lines = todo_path.read_text(encoding="utf-8").splitlines()
    for line in lines:
        rel = line.strip()
        if not rel:
            continue

        fs_path = ROOT / rel
        if not fs_path.is_file():
            print(
                f"[WARN] Fichier introuvable sur le FS, ignoré : {rel}", file=sys.stderr
            )
            continue

        st = fs_path.stat()
        size_bytes = st.st_size
        sha256 = sha256_of(fs_path)
        git_hash = git_last_hash(rel)

        mtime = int(st.st_mtime)
        mtime_iso = dt.datetime.fromtimestamp(st.st_mtime, dt.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        )

        kind, role = detect_kind_role(rel)

        entry = {
            "path": rel,
            "chapter": chapter_str,
            "kind": kind,
            "role": role,
            "size_bytes": size_bytes,
            "size": size_bytes,
            "sha256": sha256,
            "label": f"chapter{chapter_str}_{fs_path.name}",
            "description": "",
            "git_hash": git_hash,
            "mtime": mtime,
            "mtime_iso": mtime_iso,
        }
        entries.append(entry)

    if not entries:
        print(f"[WARN] Aucune entrée générée à partir de {todo_path}", file=sys.stderr)

    tsv_path = TMP_DIR / f"chapter{chapter_str}_manifest_entries.tsv"
    json_path = TMP_DIR / f"chapter{chapter_str}_manifest_entries.json"

    # TSV minimal (path, size_bytes, sha256)
    with tsv_path.open("w", encoding="utf-8") as f:
        for e in entries:
            f.write(f"{e['path']}\t{e['size_bytes']}\t{e['sha256']}\n")
    print(f"[OK] Métadonnées écrites dans {tsv_path}")

    with json_path.open("w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, sort_keys=True)
    print(f"[OK] Entrées JSON écrites dans {json_path}")


if __name__ == "__main__":
    main()
