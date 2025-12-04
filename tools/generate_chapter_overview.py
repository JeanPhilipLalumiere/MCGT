#!/usr/bin/env python
"""Génère un résumé Markdown par chapitre à partir des TSV dans _tmp.

Sortie : docs/CHAPTER_OVERVIEW.md

Le script est volontairement tolérant :
- si un TSV manque, il est ignoré proprement ;
- s'il manque des colonnes attendues, on fait un best-effort ;
- les chapitres sont détectés soit par colonne (chapter, chapter_id, ...)
  soit par regex sur les chemins (chapterXX).
"""

from __future__ import annotations

import csv
import datetime as dt
import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, Any, Iterable, Optional


# --- Helpers génériques ----------------------------------------------------


CHAPTER_KEYS = ["chapter", "chapter_id", "chapter_num", "chapter_index"]
PATH_KEYS = ["relpath", "path", "file", "filepath", "filename"]


def load_tsv(path: Path) -> Iterable[dict]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        if reader.fieldnames is None:
            return []
        for row in reader:
            yield row


def extract_chapter_from_row(row: dict) -> Optional[str]:
    # 1) colonnes explicites
    for key in CHAPTER_KEYS:
        if key in row and row[key]:
            return str(row[key]).zfill(2)

    # 2) chemins
    for key in PATH_KEYS:
        if key in row and row[key]:
            m = re.search(r"chapter(\d{2})", row[key])
            if m:
                return m.group(1)

    # 3) tentative générale
    for value in row.values():
        if not value:
            continue
        m = re.search(r"chapter(\d{2})", str(value))
        if m:
            return m.group(1)

    return None


def ensure_chapter(chapters: Dict[str, Dict[str, Any]], chapter: str) -> Dict[str, Any]:
    if chapter not in chapters:
        chapters[chapter] = {
            "assets_total": 0,
            "assets_by_kind": defaultdict(int),
            "scripts_total": 0,
            "data_files": None,
            "data_size_bytes": None,
            "fig_files": None,
            "fig_size_bytes": None,
            "out_files": 0,
            "manifest_decisions": defaultdict(int),
        }
    return chapters[chapter]


# --- Agrégations spécifiques -----------------------------------------------


def summarize_chapter_assets_full(tmp_dir: Path, chapters: Dict[str, Dict[str, Any]]) -> None:
    tsv = tmp_dir / "CHAPTER_ASSETS_FULL.tsv"
    for row in load_tsv(tsv):
        chapter = extract_chapter_from_row(row)
        if not chapter:
            continue
        slot = ensure_chapter(chapters, chapter)
        slot["assets_total"] += 1

        kind = None
        for key in ("asset_kind", "kind", "role", "asset_type", "type"):
            if key in row and row[key]:
                kind = str(row[key])
                break
        if kind is None:
            kind = "unknown"
        slot["assets_by_kind"][kind] += 1


def summarize_scripts_by_chapter(tmp_dir: Path, chapters: Dict[str, Dict[str, Any]]) -> None:
    tsv = tmp_dir / "scripts_by_chapter.tsv"
    for row in load_tsv(tsv):
        chapter = extract_chapter_from_row(row)
        if not chapter:
            continue
        slot = ensure_chapter(chapters, chapter)
        slot["scripts_total"] += 1


def summarize_sizes_by_chapter(
    tmp_dir: Path,
    chapters: Dict[str, Dict[str, Any]],
    filename: str,
    files_key: str,
    size_key: str,
) -> None:
    tsv = tmp_dir / filename
    for row in load_tsv(tsv):
        # On suppose qu'une ligne = un chapitre
        chapter = None
        for key in CHAPTER_KEYS:
            if key in row and row[key]:
                chapter = str(row[key]).zfill(2)
                break
        if not chapter:
            # tentative via valeur quelconque
            for value in row.values():
                if not value:
                    continue
                m = re.search(r"(\d{1,2})", str(value))
                if m:
                    chapter = m.group(1).zfill(2)
                    break
        if not chapter:
            continue
        slot = ensure_chapter(chapters, chapter)

        # nb de fichiers
        n_files = None
        for key in ("n_files", "count", "n", "num_files"):
            if key in row and row[key]:
                try:
                    n_files = int(row[key])
                    break
                except ValueError:
                    pass

        # taille
        size = None
        for key in ("total_size_bytes", "size_bytes", "bytes", "total_bytes"):
            if key in row and row[key]:
                try:
                    size = int(float(row[key]))
                    break
                except ValueError:
                    pass

        if n_files is not None:
            slot[files_key] = n_files
        if size is not None:
            slot[size_key] = size


def summarize_manifest_decisions(tmp_dir: Path, chapters: Dict[str, Dict[str, Any]]) -> None:
    tsv = tmp_dir / "CHAPTER_MANIFEST_DECISIONS.tsv"
    for row in load_tsv(tsv):
        chapter = extract_chapter_from_row(row)
        if not chapter:
            continue
        slot = ensure_chapter(chapters, chapter)

        decision = None
        for key in ("decision", "action", "status", "choice"):
            if key in row and row[key]:
                decision = str(row[key])
                break
        if decision is None:
            decision = "unspecified"
        slot["manifest_decisions"][decision] += 1


def summarize_zz_out_inventory(tmp_dir: Path, chapters: Dict[str, Dict[str, Any]]) -> None:
    tsv = tmp_dir / "zz_out_inventory.tsv"
    for row in load_tsv(tsv):
        chapter = extract_chapter_from_row(row)
        if not chapter:
            continue
        slot = ensure_chapter(chapters, chapter)
        slot["out_files"] += 1


# --- Rendu Markdown --------------------------------------------------------


def fmt_size(size: Optional[int]) -> str:
    if size is None:
        return "n/a"
    units = ["B", "KiB", "MiB", "GiB"]
    value = float(size)
    for u in units:
        if value < 1024.0 or u == units[-1]:
            return f"{value:,.1f} {u}".replace(",", " ")
        value /= 1024.0
    return f"{size} B"


def render_markdown(chapters: Dict[str, Dict[str, Any]], output: Path) -> None:
    now = dt.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    lines = []
    lines.append("# MCGT – Vue d’ensemble par chapitre")
    lines.append("")
    lines.append(f"_Généré automatiquement par `tools/generate_chapter_overview.py` le {now}._")
    lines.append("")
    lines.append("> NOTE : ce document est auto-généré. Ne pas éditer à la main.")
    lines.append("")

    for chapter in sorted(chapters.keys()):
        info = chapters[chapter]
        lines.append(f"## Chapitre {chapter}")
        lines.append("")

        # résumé chiffré
        lines.append("| Indicateur | Valeur |")
        lines.append("|-----------|--------|")

        lines.append(f"| Assets (tous types) | {info['assets_total']} |")

        # data
        data_files = info.get("data_files")
        data_size = info.get("data_size_bytes")
        lines.append(f"| Fichiers de données (`zz-data`) | {data_files if data_files is not None else 'n/a'} |")
        lines.append(f"| Volume de données | {fmt_size(data_size)} |")

        # figures
        fig_files = info.get("fig_files")
        fig_size = info.get("fig_size_bytes")
        lines.append(f"| Figures (`zz-figures` / `zz-out`) | {fig_files if fig_files is not None else 'n/a'} |")
        lines.append(f"| Volume des figures | {fmt_size(fig_size)} |")

        # scripts / out
        lines.append(f"| Scripts par chapitre | {info['scripts_total']} |")
        lines.append(f"| Fichiers de sortie dans `zz-out` | {info['out_files']} |")
        lines.append("")

        # détail par type d’asset
        if info["assets_by_kind"]:
            lines.append("**Répartition des assets (CHAPTER_ASSETS_FULL.tsv) :**")
            lines.append("")
            lines.append("| Type d’asset | Nombre |")
            lines.append("|-------------|--------|")
            for kind, count in sorted(info["assets_by_kind"].items()):
                lines.append(f"| `{kind}` | {count} |")
            lines.append("")

        # décisions de manifest
        if info["manifest_decisions"]:
            lines.append("**Décisions de manifest (CHAPTER_MANIFEST_DECISIONS.tsv) :**")
            lines.append("")
            lines.append("| Décision | Nombre d’entrées |")
            lines.append("|----------|-------------------|")
            for decision, count in sorted(info["manifest_decisions"].items()):
                lines.append(f"| `{decision}` | {count} |")
            lines.append("")

        lines.append("---")
        lines.append("")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")


# --- Main ------------------------------------------------------------------


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    tmp_dir = repo_root / "_tmp"
    out_md = repo_root / "docs" / "CHAPTER_OVERVIEW.md"

    chapters: Dict[str, Dict[str, Any]] = {}

    summarize_chapter_assets_full(tmp_dir, chapters)
    summarize_scripts_by_chapter(tmp_dir, chapters)
    summarize_sizes_by_chapter(
        tmp_dir, chapters,
        filename="zz_data_sizes_by_chapter.tsv",
        files_key="data_files",
        size_key="data_size_bytes",
    )
    summarize_sizes_by_chapter(
        tmp_dir, chapters,
        filename="zz_figures_sizes_by_chapter.tsv",
        files_key="fig_files",
        size_key="fig_size_bytes",
    )
    summarize_manifest_decisions(tmp_dir, chapters)
    summarize_zz_out_inventory(tmp_dir, chapters)

    if not chapters:
        raise SystemExit("Aucun chapitre détecté dans les TSV de _tmp (chapters dict vide).")

    render_markdown(chapters, out_md)
    print(f"[OK] Résumé par chapitre généré dans {out_md}")


if __name__ == "__main__":
    main()
