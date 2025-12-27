#!/usr/bin/env python
from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAPS_PATH = ROOT / "_tmp" / "CHAPTER_MANIFEST_GAPS.md"

START_HEADER = "## Chapter 1 — chapter_manifest_01.json"
NEXT_HEADER_PREFIX = "## Chapter 2 —"


def main() -> None:
    if not GAPS_PATH.is_file():
        raise SystemExit(f"[ERROR] Fichier introuvable : {GAPS_PATH}")

    text = GAPS_PATH.read_text(encoding="utf-8").splitlines()

    out_lines: list[str] = []
    i = 0
    while i < len(text):
        line = text[i]

        # Quand on tombe sur le bloc "Chapter 1", on le remplace par une version résumée
        if line.strip() == START_HEADER:
            out_lines.append(START_HEADER)
            out_lines.append("")  # ligne vide
            out_lines.append(
                "Section résolue (2025-12-03) : les metas et le guide existent "
                "dans le filesystem et sont couverts par les manifests globaux."
            )
            out_lines.append("")
            out_lines.append("- `assets/zz-data/01_invariants_stability/01_P_vs_T.meta.json`")
            out_lines.append("- `assets/zz-data/01_invariants_stability/01_optimized_data.meta.json`")
            out_lines.append("- `01-introduction-applications/CHAPTER1_GUIDE.txt`")
            out_lines.append("")
            out_lines.append("Aucun gap restant spécifique au chapitre 01.")
            out_lines.append("")

            # On saute tout l'ancien bloc jusqu'au début du chapitre 2 (ou EOF)
            i += 1
            while i < len(text) and not text[i].startswith(NEXT_HEADER_PREFIX):
                i += 1
            continue

        # Sinon, on recopie la ligne telle quelle
        out_lines.append(line)
        i += 1

    GAPS_PATH.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
    print(f"[OK] Bloc 'Chapter 1' nettoyé dans {GAPS_PATH}")


if __name__ == "__main__":
    main()
