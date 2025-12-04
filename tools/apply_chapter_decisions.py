#!/usr/bin/env python
from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "_tmp"
ATTIC_DIR = ROOT / "attic"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Appliquer les décisions de _tmp/chapterXX_decisions.tsv"
    )
    parser.add_argument(
        "--chapter",
        "-c",
        type=int,
        required=True,
        help="Numéro de chapitre (ex: 1 pour chapter01)",
    )
    parser.add_argument(
        "--decisions-file",
        "-f",
        type=str,
        default=None,
        help="Chemin explicite du TSV de décisions (par défaut: _tmp/chapterXX_decisions.tsv)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Ne fait qu'afficher les actions prévues, sans modifier le FS",
    )
    return parser.parse_args()


def load_decisions(chapter: int, decisions_file: str | None) -> list[dict]:
    if decisions_file is not None:
        path = Path(decisions_file)
    else:
        path = TMP_DIR / f"chapter{chapter:02d}_decisions.tsv"

    if not path.is_file():
        print(f"[ERROR] Fichier de décisions introuvable : {path}", file=sys.stderr)
        sys.exit(1)

    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)

    return rows


def main() -> None:
    args = parse_args()
    chapter = args.chapter

    decisions_rows = load_decisions(chapter, args.decisions_file)

    to_attic: list[str] = []
    to_delete: list[str] = []
    keep_manifest: list[str] = []

    for row in decisions_rows:
        rel_path = (row.get("path") or "").strip()
        raw_decision = (row.get("decision") or "").strip()

        if not rel_path:
            # Ligne vide ou cassée
            continue

        if not raw_decision:
            # Pas encore décidé → ignoré pour l’instant
            continue

        # Décisions automatiques issues de generate_chapter_decisions.py
        # qui ne doivent PAS déclencher d’actions sur le FS.
        upper_decision = raw_decision.upper()
        if upper_decision in {"KEEP_EXPECTED", "CREATE_PLACEHOLDER_GUIDE"}:
            continue

        decision = raw_decision.lower()

        if decision == "attic":
            to_attic.append(rel_path)
        elif decision.startswith("delete"):
            to_delete.append(rel_path)
        elif decision.startswith("keep"):
            keep_manifest.append(rel_path)
        else:
            print(
                f"[WARN] Décision inconnue pour {rel_path!r}: {raw_decision!r} (ignoré)",
                file=sys.stderr,
            )

    print(f"[INFO] Chapitre {chapter:02d}")
    print(f"  -> {len(to_attic)} fichiers -> attic/")
    print(f"  -> {len(to_delete)} fichiers à supprimer")
    print(f"  -> {len(keep_manifest)} fichiers à garder + ajouter au manifest")

    manifest_todo_path = TMP_DIR / f"chapter{chapter:02d}_manifest_todo.txt"

    if args.dry_run:
        print("\n[DRY-RUN] Aucune modification n'est effectuée.")
        if to_attic:
            print("\n[DRY-RUN] Déplacements prévus vers attic/:")
            for rel in to_attic:
                print(f"  mv {rel} attic/{rel}")
        if to_delete:
            print("\n[DRY-RUN] Suppressions prévues :")
            for rel in to_delete:
                print(f"  rm {rel}")
        if keep_manifest:
            print(
                f"\n[DRY-RUN] Fichiers à ajouter au manifest "
                f"(sera écrit dans {manifest_todo_path}):"
            )
            for rel in keep_manifest:
                print(f"  manifest: {rel}")
        return

    # Mode effectif
    # 1) Déplacements vers attic/
    for rel in to_attic:
        src = ROOT / rel
        dst = ATTIC_DIR / rel
        if not src.exists():
            print(f"[WARN] Source manquante (attic): {src}", file=sys.stderr)
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        print(f"[MOVE] {src} -> {dst}")
        shutil.move(str(src), str(dst))

    # 2) Suppressions
    for rel in to_delete:
        path = ROOT / rel
        if not path.exists():
            print(f"[WARN] Fichier manquant (delete): {path}", file=sys.stderr)
            continue
        print(f"[DELETE] {path}")
        try:
            os.remove(path)
        except IsADirectoryError:
            print(
                f"[ERROR] {path} est un répertoire, suppression non gérée.",
                file=sys.stderr,
            )

    # 3) TODO manifest
    if keep_manifest:
        manifest_todo_path.parent.mkdir(parents=True, exist_ok=True)
        with manifest_todo_path.open("w", encoding="utf-8") as f:
            for rel in keep_manifest:
                f.write(rel + "\n")
        print(f"[OK] TODO manifest écrit dans {manifest_todo_path}")
    else:
        if manifest_todo_path.exists():
            print(
                "[INFO] Aucun keep+manifest, TODO manifest non mis à jour "
                "(un ancien fichier peut exister)."
            )

    print("\n[DONE] apply_chapter_decisions terminé.")


if __name__ == "__main__":
    main()
