#!/usr/bin/env python
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAPS_PATH = ROOT / "_tmp" / "CHAPTER_MANIFEST_GAPS.md"

HEADER_REGEX = r"^## .*4.*chapter_manifest_04\.json[ \t]*$"

REPLACEMENT = """## Chapter 4 — chapter_manifest_04.json

Section résolue (2025-12-04) : les fichiers de données d’entrée, figures, metas,
scripts et le guide du chapitre 04 existent dans le filesystem et sont couverts
par les manifests globaux (`manifest_publication.json` et `manifest_master.json`).

Aucun gap restant spécifique au chapitre 04.
"""


def main() -> None:
    if not GAPS_PATH.is_file():
        print(f"[ERROR] Fichier introuvable : {GAPS_PATH}", file=sys.stderr)
        sys.exit(1)

    text = GAPS_PATH.read_text(encoding="utf-8")
    pattern = HEADER_REGEX + r"[\s\S]*?(?=^## |\Z)"

    if not re.search(pattern, text, flags=re.MULTILINE):
        print(
            "[ERROR] Bloc pour 'chapter_manifest_04.json' introuvable dans CHAPTER_MANIFEST_GAPS.md",
            file=sys.stderr,
        )
        sys.exit(1)

    backup = GAPS_PATH.with_suffix(GAPS_PATH.suffix + ".bak_before_ch04_cleanup")
    backup.write_text(text, encoding="utf-8")
    print(f"[BACKUP] Copie sauvegarde -> {backup}")

    new_text = re.sub(pattern, REPLACEMENT + "\n", text, flags=re.MULTILINE)
    GAPS_PATH.write_text(new_text, encoding="utf-8")
    print(f"[OK] Bloc 'Chapter 4' nettoyé dans {GAPS_PATH}")

    subprocess.run(["python", "tools/generate_chapter_todo.py"], check=True)
    print("[OK] TODO par chapitre généré dans docs/CHAPTER_TODO.md")


if __name__ == "__main__":
    main()
