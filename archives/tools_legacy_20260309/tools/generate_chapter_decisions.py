#!/usr/bin/env python
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "_tmp"
GLOBAL_DECISIONS_TSV = TMP_DIR / "CHAPTER_MANIFEST_DECISIONS.tsv"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Générer un fichier _tmp/chapterXX_decisions.tsv "
            "en filtrant _tmp/CHAPTER_MANIFEST_DECISIONS.tsv pour un chapitre donné."
        )
    )
    parser.add_argument(
        "--chapter",
        "-c",
        type=int,
        required=True,
        help="Numéro de chapitre (ex: 1 pour chapter01)",
    )
    parser.add_argument(
        "--input-tsv",
        "-i",
        type=str,
        default=None,
        help="TSV global en entrée (par défaut: _tmp/CHAPTER_MANIFEST_DECISIONS.tsv)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=None,
        help="TSV de décisions en sortie (par défaut: _tmp/chapterXX_decisions.tsv)",
    )
    return parser.parse_args()


def load_global_rows(path: Path) -> list[dict]:
    if not path.is_file():
        print(f"[ERROR] Fichier global introuvable : {path}", file=sys.stderr)
        sys.exit(1)

    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)
    return rows


def row_matches_chapter(row: dict, chapter: int) -> bool:
    """
    On essaie d'abord la colonne 'chapter' si elle existe,
    sinon on déduit à partir du chemin (presence de 'chapterXX').
    """
    chapter_str = f"{chapter:02d}"

    # 1) Colonne 'chapter' explicite
    raw_ch = (row.get("chapter") or "").strip()
    if raw_ch:
        # Accepte "01" ou "1"
        if raw_ch == chapter_str or raw_ch == str(chapter):
            return True

    # 2) Fallback : heuristique sur le chemin
    path = (row.get("path") or "").strip()
    if not path:
        return False

    marker = f"chapter{chapter_str}"
    return marker in path


def main() -> None:
    args = parse_args()
    chapter = args.chapter

    global_path = Path(args.input_tsv) if args.input_tsv else GLOBAL_DECISIONS_TSV
    rows = load_global_rows(global_path)

    out_path = (
        Path(args.output)
        if args.output
        else TMP_DIR / f"chapter{chapter:02d}_decisions.tsv"
    )

    # Colonnes cibles
    fieldnames = ["path", "kind", "chapter", "decision", "comment"]

    selected: list[dict] = []
    missing_manifest_count = 0
    fs_extra_count = 0

    for row in rows:
        if not row_matches_chapter(row, chapter):
            continue

        path = (row.get("path") or "").strip()
        kind = (row.get("kind") or "").strip()
        raw_ch = (row.get("chapter") or "").strip()
        decision = (row.get("decision") or "").strip()
        comment = (row.get("comment") or "").strip()

        # Normalisation du chapitre écrit dans le TSV de sortie
        if raw_ch:
            ch_out = raw_ch
        else:
            ch_out = f"{chapter:02d}"

        if kind == "missing_manifest":
            missing_manifest_count += 1
        elif kind == "fs_extra":
            fs_extra_count += 1

        selected.append(
            {
                "path": path,
                "kind": kind,
                "chapter": ch_out,
                # on garde la décision/comment éventuels, sinon vide
                "decision": decision,
                "comment": comment,
            }
        )

    if not selected:
        print(
            f"[WARN] Aucun enregistrement trouvé pour le chapitre {chapter:02d} "
            f"dans {global_path}."
        )
        # On ne considère pas ça comme un hard error : juste informatif
        return

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        for row in selected:
            writer.writerow(row)

    print(f"[OK] Fichier de décisions créé : {out_path}")
    print(f"      Entrées missing_manifest : {missing_manifest_count}")
    print(f"      Entrées fs_extra         : {fs_extra_count}")


if __name__ == "__main__":
    main()
