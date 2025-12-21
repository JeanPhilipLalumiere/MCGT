#!/usr/bin/env python
from __future__ import annotations

import csv
from pathlib import Path
import sys
import textwrap

ROOT = Path(__file__).resolve().parents[1]
TMP_DIR = ROOT / "_tmp"

# Chapitres à traiter : 2 à 10 (01 est déjà structuré)
CHAPTERS = list(range(2, 11))


def load_decisions_for_chapter(chapter: int) -> list[dict]:
    path = TMP_DIR / f"chapter{chapter:02d}_decisions.tsv"
    if not path.is_file():
        print(
            f"[WARN] TSV décisions introuvable pour chapter{chapter:02d}: {path}",
            file=sys.stderr,
        )
        return []

    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)
    return rows


def make_guide_content(chapter: int, rel_path: str) -> str:
    """
    Contenu minimal standard pour CHAPTERX_GUIDE.txt.
    On reste volontairement sobre : titre + TODO, en laissant
    la liberté de détailler plus tard.
    """
    title = f"CHAPTER{chapter:02d}_GUIDE"
    body = textwrap.dedent(
        f"""
        {title}
        =====================

        Ce fichier sert de guide pour le chapitre {chapter:02d}.

        TODO :
          - résumer en quelques phrases les objectifs du chapitre ;
          - lister les figures et tables “publiques” clés ;
          - préciser les scripts principaux (scripts/chapter{chapter:02d}/...),
            et comment reproduire les résultats essentiels.

        Chemin du guide :
          - {rel_path}

        Ce contenu est un gabarit initial et peut (doit) être édité librement.
        """
    ).lstrip("\n")
    return body


def main() -> None:
    total_created = 0
    total_skipped_existing = 0

    for chapter in CHAPTERS:
        rows = load_decisions_for_chapter(chapter)
        if not rows:
            continue

        for row in rows:
            decision = (row.get("decision") or "").strip()
            rel_path = (row.get("path") or "").strip()

            if decision != "CREATE_PLACEHOLDER_GUIDE":
                continue
            if not rel_path:
                continue

            guide_path = ROOT / rel_path
            guide_dir = guide_path.parent

            if guide_path.exists():
                print(
                    f"[SKIP] Guide déjà présent pour chapter{chapter:02d}: {rel_path}"
                )
                total_skipped_existing += 1
                continue

            guide_dir.mkdir(parents=True, exist_ok=True)
            content = make_guide_content(chapter, rel_path)
            with guide_path.open("w", encoding="utf-8") as f:
                f.write(content)

            print(
                f"[CREATE] Guide placeholder créé pour chapter{chapter:02d}: {rel_path}"
            )
            total_created += 1

    print()
    print(f"[SUMMARY] Guides créés     : {total_created}")
    print(f"[SUMMARY] Guides existants : {total_skipped_existing}")


if __name__ == "__main__":
    main()
