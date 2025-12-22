#!/usr/bin/env python
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAPS_PATH = ROOT / "_tmp" / "CHAPTER_MANIFEST_GAPS.md"

# On ne fige pas le mot "Chapter" / "Chapter", on matche juste "3" et "chapter_manifest_03.json"
HEADER_REGEX = r"^## .*3.*chapter_manifest_03\.json[ \t]*$"

REPLACEMENT = """## Chapter 3 — chapter_manifest_03.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 03 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 03.
"""


def main() -> None:
    if not GAPS_PATH.is_file():
        print(f"[ERROR] Fichier introuvable : {GAPS_PATH}", file=sys.stderr)
        sys.exit(1)

    text = GAPS_PATH.read_text(encoding="utf-8")

    # On remplace depuis la ligne d'en-tête jusqu'au prochain "## ..." ou fin de fichier.
    pattern = HEADER_REGEX + r"[\s\S]*?(?=^## |\Z)"

    if not re.search(pattern, text, flags=re.MULTILINE):
        print(
            "[ERROR] Bloc pour 'chapter_manifest_03.json' introuvable dans CHAPTER_MANIFEST_GAPS.md",
            file=sys.stderr,
        )
        sys.exit(1)

    backup = GAPS_PATH.with_suffix(GAPS_PATH.suffix + ".bak_before_ch03_cleanup")
    backup.write_text(text, encoding="utf-8")
    print(f"[BACKUP] Copie sauvegarde -> {backup}")

    new_text = re.sub(pattern, REPLACEMENT + "\n", text, flags=re.MULTILINE)
    GAPS_PATH.write_text(new_text, encoding="utf-8")
    print(f"[OK] Bloc 'Chapter 3' nettoyé dans {GAPS_PATH}")

    # On régénère le TODO pour propager la résolution.
    subprocess.run(["python", "tools/generate_chapter_todo.py"], check=True)
    print("[OK] TODO par chapitre généré dans docs/CHAPTER_TODO.md")


if __name__ == "__main__":
    main()
