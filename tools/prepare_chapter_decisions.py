#!/usr/bin/env python
"""
Prépare un fichier TSV de décisions pour un chapitre donné.

Entrées (dans _tmp/) :
- manifest_publication_missing_files.txt
- fs_not_in_manifest_publication.txt

Sortie :
- _tmp/chapterXX_decisions.tsv

Usage :
    python tools/prepare_chapter_decisions.py 01
"""

from __future__ import annotations

import sys
import re
from pathlib import Path
from typing import List, Optional, Tuple


def chapter_from_path(path_str: str) -> Optional[str]:
    """Extrait 'chapterXX' d'un chemin et renvoie 'XX' ou None."""
    m = re.search(r"chapter(\d{2})", path_str)
    if m:
        return m.group(1)
    # fallback : 'chapterX'
    m2 = re.search(r"chapter(\d)(?!\d)", path_str)
    if m2:
        return m2.group(1).zfill(2)
    return None


def load_paths(path: Path) -> List[str]:
    """Lit un fichier texte (une entrée par ligne) en ignorant les commentaires/lignes vides."""
    if not path.exists():
        return []
    out: List[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out.append(line)
    return out


def collect_for_chapter(tmp_dir: Path, chap_code: str) -> Tuple[List[str], List[str]]:
    """Retourne (missing_for_chapter, fs_extra_for_chapter)."""
    missing_path = tmp_dir / "manifest_publication_missing_files.txt"
    fs_extra_path = tmp_dir / "fs_not_in_manifest_publication.txt"

    missing_all = load_paths(missing_path)
    fs_extra_all = load_paths(fs_extra_path)

    missing_sel = [p for p in missing_all if chapter_from_path(p) == chap_code]
    fs_extra_sel = [p for p in fs_extra_all if chapter_from_path(p) == chap_code]

    return missing_sel, fs_extra_sel


def main(argv: list[str]) -> None:
    if len(argv) != 2:
        print("Usage : python tools/prepare_chapter_decisions.py XX", file=sys.stderr)
        sys.exit(1)

    raw_chap = argv[1]
    if not raw_chap.isdigit():
        print(f"[ERROR] Chapitre invalide : {raw_chap!r}", file=sys.stderr)
        sys.exit(1)

    chap_code = raw_chap.zfill(2)

    repo_root = Path(__file__).resolve().parents[1]
    tmp_dir = repo_root / "_tmp"
    out_path = tmp_dir / f"chapter{chap_code}_decisions.tsv"

    missing, fs_extra = collect_for_chapter(tmp_dir, chap_code)

    if not missing and not fs_extra:
        print(
            f"[WARN] Aucun élément trouvé pour chapter{chap_code} dans les fichiers de diag.",
            file=sys.stderr,
        )

    # Construction du TSV
    lines: List[str] = []
    header = ["path", "kind", "chapter", "decision", "comment"]
    lines.append("\t".join(header))

    for p in sorted(missing):
        lines.append("\t".join([p, "missing_manifest", chap_code, "", ""]))
    for p in sorted(fs_extra):
        lines.append("\t".join([p, "fs_extra", chap_code, "", ""]))

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[OK] Fichier de décisions créé : {out_path}")
    print(f"      Entrées missing_manifest : {len(missing)}")
    print(f"      Entrées fs_extra         : {len(fs_extra)}")
    print("")
    print("Prochaine étape :")
    print(f"  - ouvrir {out_path}")
    print("  - remplir la colonne 'decision' avec, par exemple :")
    print("      keep+manifest / attic / delete")
    print("  - optionnel : documenter la raison dans 'comment'")


if __name__ == "__main__":
    main(sys.argv)
