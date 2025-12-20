#!/usr/bin/env python
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import sys


ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "_tmp"
MANIFESTS = [
    ROOT / "zz-manifests" / "manifest_publication.json",
    ROOT / "zz-manifests" / "manifest_master.json",
]


def load_entries(chapter: int):
    chapter_str = f"{chapter:02d}"
    json_path = TMP_DIR / f"chapter{chapter_str}_manifest_entries.json"
    if not json_path.is_file():
        print(f"[ERROR] JSON d'entrées introuvable : {json_path}", file=sys.stderr)
        sys.exit(1)
    with json_path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        print(
            f"[ERROR] Format inattendu dans {json_path} (attendu: liste)",
            file=sys.stderr,
        )
        sys.exit(1)
    return data


def find_target_list(doc, manifest_path: Path, chapter_str: str):
    """
    Retourne (files_list, key) où:
      - files_list est la liste à modifier
      - key est None si le manifest est une liste au top-level,
        ou le nom de la clé dans le dict si la liste est sous doc[key].
    Critères :
      1. Si doc est une liste -> on la prend telle quelle.
      2. Si doc est un dict -> on cherche une clé dont la valeur est une liste de dicts
         avec 'path', en privilégiant celles qui contiennent déjà des chemins de ce chapitre.
    """
    # Cas simple : manifest = [ {...}, {...}, ... ]
    if isinstance(doc, list):
        return doc, None

    if not isinstance(doc, dict):
        print(
            f"[ERROR] Manifest inattendu (ni dict ni liste): {manifest_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    chapter_prefixes = (
        f"zz-data/chapter{chapter_str}/",
        f"zz-figures/chapter{chapter_str}/",
        f"zz-scripts/chapter{chapter_str}/",
    )

    candidates = []

    for key, val in doc.items():
        if not isinstance(val, list) or not val:
            continue
        # Vérifier que c'est bien une liste d'entrées avec 'path'
        if not any(isinstance(e, dict) and "path" in e for e in val):
            continue

        # Score: combien d'entrées de ce chapitre déjà présentes ?
        score = 0
        for e in val:
            if not isinstance(e, dict):
                continue
            p = e.get("path", "")
            if any(p.startswith(pref) for pref in chapter_prefixes):
                score += 1

        candidates.append((score, key, val))

    if not candidates:
        # Dernier recours : prendre la première liste d'objets avec 'path'
        for key, val in doc.items():
            if (
                isinstance(val, list)
                and val
                and isinstance(val[0], dict)
                and "path" in val[0]
            ):
                print(
                    f"[WARN] Aucun bloc spécifique au chapitre {chapter_str} détecté dans {manifest_path}, "
                    f"utilisation de la clé '{key}' par défaut.",
                    file=sys.stderr,
                )
                return val, key

        print(
            f"[ERROR] Impossible de trouver une liste d'entrées 'files' exploitable dans {manifest_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    # Prendre le candidat avec le score max (chapitre le plus représenté)
    candidates.sort(key=lambda t: t[0], reverse=True)
    score, key, lst = candidates[0]
    if score == 0:
        print(
            f"[WARN] Aucune entrée existante pour le chapitre {chapter_str} dans {manifest_path}, "
            f"utilisation de la clé '{key}' (score=0).",
            file=sys.stderr,
        )
    return lst, key


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ajoute les entrées chapterXX_manifest_entries.json aux manifests globaux."
    )
    parser.add_argument(
        "--chapter",
        "-c",
        type=int,
        required=True,
        help="Numéro de chapitre (ex: 3 pour chapter03)",
    )
    args = parser.parse_args()
    chapter = args.chapter
    chapter_str = f"{chapter:02d}"

    new_entries = load_entries(chapter)
    new_paths = {e["path"] for e in new_entries}

    for manifest_path in MANIFESTS:
        if not manifest_path.is_file():
            print(f"[ERROR] Manifest introuvable: {manifest_path}", file=sys.stderr)
            sys.exit(1)

        backup = manifest_path.with_suffix(
            manifest_path.suffix + f".bak_before_ch{chapter_str}_merge"
        )
        shutil.copy2(manifest_path, backup)
        print(f"[BACKUP] Copie sauvegarde -> {backup}")

        with manifest_path.open("r", encoding="utf-8") as f:
            doc = json.load(f)

        files_list, key = find_target_list(doc, manifest_path, chapter_str)
        before = len(files_list)

        existing_paths = {e.get("path") for e in files_list if isinstance(e, dict)}
        added = 0
        for e in new_entries:
            if e["path"] in existing_paths:
                continue
            files_list.append(e)
            existing_paths.add(e["path"])
            added += 1

        after = len(files_list)

        # Réinjecter la liste modifiée dans le document
        if key is not None and isinstance(doc, dict):
            doc[key] = files_list
        else:
            # cas où doc est la liste elle-même
            doc = files_list

        with manifest_path.open("w", encoding="utf-8") as f:
            json.dump(doc, f, indent=2, sort_keys=True)

        print(
            f"[UPDATE] {manifest_path.name} :\n"
            f"         - entrées avant      : {before}\n"
            f"         - entrées ajoutées   : {added}\n"
            f"         - total après        : {after}"
        )

    print(
        f"[DONE] Ajout des fichiers de chapter{chapter_str} aux manifests (publication + master)."
    )


if __name__ == "__main__":
    main()
