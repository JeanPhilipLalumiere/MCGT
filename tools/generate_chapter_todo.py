#!/usr/bin/env python
"""Génère un fichier TODO par chapitre à partir des artefacts de _tmp.

Sources principales :
- _tmp/manifest_publication_missing_files.txt
- _tmp/fs_not_in_manifest_publication.txt
- _tmp/CHAPTER_MANIFEST_GAPS.md
- _tmp/FIGURES_REBUILD_LATER_TODO.md

Sortie :
- docs/CHAPTER_TODO.md

Le script est tolérant :
- s'il manque un fichier, la section correspondante est simplement omise ;
- s'il ne trouve pas de chapitre dans un chemin, l'entrée va dans "Global".
"""

from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional


def chapter_from_path(path_str: str) -> Optional[str]:
    """Essaye d'extraire 'chapterXX' d'un chemin, retourne 'XX' ou None."""
    m = re.search(r"chapter(\d{2})", path_str)
    if m:
        return m.group(1)
    # fallback : chapterX (un seul chiffre)
    m2 = re.search(r"chapter(\d)(?!\d)", path_str)
    if m2:
        return m2.group(1).zfill(2)
    return None


def load_paths_list(path: Path) -> List[str]:
    """Charge un fichier texte simple (une entrée par ligne)."""
    if not path.exists():
        return []
    items: List[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        items.append(line)
    return items


def load_optional_text(path: Path) -> Optional[str]:
    """Charge un fichier texte brut, ou None s'il n'existe pas."""
    if not path.exists():
        return None
    return path.read_text(encoding="utf-8").strip() or None


def build_todo_structure(
    repo_root: Path,
) -> Dict[str, Dict[str, List[str]]]:
    """Construit la structure TODO par chapitre.

    Retourne :
    {
      "GLOBAL": {
        "missing_manifest": [...],
        "fs_extra": [...],
      },
      "01": {
        "missing_manifest": [...],
        "fs_extra": [...],
      },
      ...
    }
    """
    tmp_dir = repo_root / "_tmp"

    missing_path = tmp_dir / "manifest_publication_missing_files.txt"
    fs_extra_path = tmp_dir / "fs_not_in_manifest_publication.txt"

    missing = load_paths_list(missing_path)
    fs_extra = load_paths_list(fs_extra_path)

    todo: Dict[str, Dict[str, List[str]]] = defaultdict(
        lambda: {
            "missing_manifest": [],
            "fs_extra": [],
        }
    )

    # Fichiers manquants dans manifest_publication
    for entry in missing:
        chap = chapter_from_path(entry)
        key = chap if chap is not None else "GLOBAL"
        todo[key]["missing_manifest"].append(entry)

    # Fichiers présents dans FS mais pas dans manifest_publication
    for entry in fs_extra:
        chap = chapter_from_path(entry)
        key = chap if chap is not None else "GLOBAL"
        todo[key]["fs_extra"].append(entry)

    return todo


def render_markdown(
    repo_root: Path,
    todo: Dict[str, Dict[str, List[str]]],
    gaps_text: Optional[str],
    figures_todo_text: Optional[str],
) -> str:
    """Construit le contenu Markdown de CHAPTER_TODO.md."""
    lines: List[str] = []
    lines.append("# MCGT – TODO par chapitre (manifests & artefacts)")
    lines.append("")
    lines.append(
        "> NOTE : document auto-généré à partir de `_tmp/`. Ne pas éditer à la main."
    )
    lines.append("")
    lines.append(
        "Ce fichier liste, par chapitre, les fichiers à trier avant la publication : "
        "soit à intégrer au `manifest_publication.json`, soit à déplacer dans `attic/`, "
        "soit à supprimer."
    )
    lines.append("")

    # Section globale (GAPS + FIGURES_REBUILD + entrées GLOBAL)
    lines.append("## Vue globale")
    lines.append("")

    if gaps_text:
        lines.append("### Gaps de manifest (CHAPTER_MANIFEST_GAPS.md)")
        lines.append("")
        lines.append("```text")
        lines.append(gaps_text)
        lines.append("```")
        lines.append("")

    if figures_todo_text:
        lines.append("### Figures à reconstruire (FIGURES_REBUILD_LATER_TODO.md)")
        lines.append("")
        lines.append("```text")
        lines.append(figures_todo_text)
        lines.append("```")
        lines.append("")

    global_block = todo.get("GLOBAL")
    if global_block and (global_block["missing_manifest"] or global_block["fs_extra"]):
        lines.append("### Entrées non assignées à un chapitre précis")
        lines.append("")
        if global_block["missing_manifest"]:
            lines.append("- Fichiers manquants dans `manifest_publication.json` :")
            lines.append("")
            for entry in sorted(global_block["missing_manifest"]):
                lines.append(f"  - `{entry}`")
            lines.append("")
        if global_block["fs_extra"]:
            lines.append(
                "- Fichiers présents dans le FS mais absents de `manifest_publication.json` :"
            )
            lines.append("")
            for entry in sorted(global_block["fs_extra"]):
                lines.append(f"  - `{entry}`")
            lines.append("")
        lines.append("")

    lines.append("---")
    lines.append("")

    # Chapitres (01–10 typiquement)
    chapter_keys = [k for k in todo.keys() if k != "GLOBAL"]
    for chap in sorted(chapter_keys):
        block = todo[chap]
        lines.append(f"## Chapitre {chap}")
        lines.append("")
        lines.append(
            f"Pour le contexte quantitatif, voir aussi `docs/CHAPTER_OVERVIEW.md` (section Chapitre {chap})."
        )
        lines.append("")

        if not block["missing_manifest"] and not block["fs_extra"]:
            lines.append(
                "_Aucune entrée détectée dans les fichiers de diagnostic actuels._"
            )
            lines.append("")
            lines.append("---")
            lines.append("")
            continue

        if block["missing_manifest"]:
            lines.append("### Fichiers manquants dans `manifest_publication.json`")
            lines.append("")
            lines.append(
                "Décider pour chacun : (a) ajouter au manifest (si requis pour la repro/paper), "
                "(b) déplacer dans `attic/` (artefact interne), ou (c) supprimer."
            )
            lines.append("")
            for entry in sorted(block["missing_manifest"]):
                lines.append(f"- [ ] `{entry}`")
            lines.append("")

        if block["fs_extra"]:
            lines.append(
                "### Fichiers présents dans le FS mais absents de `manifest_publication.json`"
            )
            lines.append("")
            lines.append(
                "Décider pour chacun : (a) ajouter au manifest, (b) déplacer dans `attic/`, "
                "ou (c) supprimer si redondant."
            )
            lines.append("")
            for entry in sorted(block["fs_extra"]):
                lines.append(f"- [ ] `{entry}`")
            lines.append("")

        lines.append("---")
        lines.append("")

    return "\n".join(lines)


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    tmp_dir = repo_root / "_tmp"
    out_md = repo_root / "docs" / "CHAPTER_TODO.md"

    # Structure TODO par chapitre
    todo = build_todo_structure(repo_root)

    # Texte global (gaps + figures à reconstruire)
    gaps_text = load_optional_text(tmp_dir / "CHAPTER_MANIFEST_GAPS.md")
    figures_todo_text = load_optional_text(tmp_dir / "FIGURES_REBUILD_LATER_TODO.md")

    md = render_markdown(repo_root, todo, gaps_text, figures_todo_text)

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text(md, encoding="utf-8")
    print(f"[OK] TODO par chapitre généré dans {out_md}")


if __name__ == "__main__":
    main()
