#!/usr/bin/env python
from __future__ import annotations

import datetime as dt
from pathlib import Path
import shutil
import sys
import subprocess


ROOT = Path(__file__).resolve().parents[1]
GAPS_PATH = ROOT / "_tmp" / "CHAPTER_MANIFEST_GAPS.md"


def main() -> None:
    if not GAPS_PATH.is_file():
        print(f"[ERROR] Fichier introuvable : {GAPS_PATH}", file=sys.stderr)
        sys.exit(1)

    # Backup de sécurité
    backup_path = GAPS_PATH.with_suffix(".md.bak_before_ch02_cleanup")
    shutil.copy2(GAPS_PATH, backup_path)
    print(f"[BACKUP] Copie sauvegarde -> {backup_path}")

    text = GAPS_PATH.read_text(encoding="utf-8")

    start_marker = "## Chapter 2 — chapter_manifest_02.json"
    end_marker = "## Chapter 3 — chapter_manifest_03.json"

    start_idx = text.find(start_marker)
    if start_idx == -1:
        print(
            "[ERROR] Marqueur de début pour 'Chapter 2' introuvable dans CHAPTER_MANIFEST_GAPS.md",
            file=sys.stderr,
        )
        sys.exit(1)

    end_idx = text.find(end_marker, start_idx)
    if end_idx == -1:
        print(
            "[ERROR] Marqueur de fin 'Chapter 3' introuvable après le bloc 'Chapter 2'.",
            file=sys.stderr,
        )
        sys.exit(1)

    today = dt.date.today().isoformat()

    new_block = f"""## Chapter 2 — chapter_manifest_02.json

Section résolue ({today}) : les fichiers de données d’entrée, figures, metas, scripts
et le guide du chapitre 02 existent dans le filesystem et sont couverts par les
manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 02.

"""

    # On remplace le bloc complet entre les deux chapitres
    new_text = text[:start_idx] + new_block + text[end_idx:]

    GAPS_PATH.write_text(new_text, encoding="utf-8")
    print(f"[OK] Bloc 'Chapter 2' nettoyé dans {GAPS_PATH}")

    # Régénère CHAPTER_TODO.md à partir des gaps
    try:
        subprocess.run(
            ["python", "tools/generate_chapter_todo.py"],
            cwd=ROOT,
            check=True,
        )
        print(f"[OK] TODO par chapitre généré dans {ROOT / 'docs/CHAPTER_TODO.md'}")
    except subprocess.CalledProcessError as exc:
        print(
            f"[ERROR] Échec lors de l'exécution de tools/generate_chapter_todo.py (code {exc.returncode})",
            file=sys.stderr,
        )
        sys.exit(exc.returncode)


if __name__ == "__main__":
    main()
