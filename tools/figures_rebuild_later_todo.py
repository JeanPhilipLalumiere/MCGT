#!/usr/bin/env python
from __future__ import annotations

from pathlib import Path
import csv
from collections import defaultdict
from datetime import datetime


def main() -> None:
    # Racine du repo (on part de ./tools/ → on remonte d'un niveau)
    root = Path(__file__).resolve().parents[1]

    csv_path = root / "zz-manifests" / "figures_todo_decisions.csv"
    out_dir = root / "_tmp"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "FIGURES_REBUILD_LATER_TODO.md"

    if not csv_path.exists():
        raise SystemExit(f"Fichier introuvable: {csv_path}")

    by_chapter: dict[str, list[dict[str, str]]] = defaultdict(list)

    with csv_path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            decision = (row.get("decision") or "").strip()
            if decision != "REBUILD_LATER":
                continue
            chap = (row.get("chapter") or "").strip() or "<NO_CHAPTER>"
            by_chapter[chap].append(row)

    if not by_chapter:
        out_path.write_text(
            "# Figures REBUILD_LATER\n\nAucune figure marquée REBUILD_LATER.\n",
            encoding="utf-8",
        )
        print(f"Aucune figure REBUILD_LATER. Fichier créé : {out_path}")
        return

    with out_path.open("w", encoding="utf-8", newline="\n") as out:
        out.write("# Figures REBUILD_LATER – snapshot\n\n")
        out.write(
            f"_Généré le {datetime.utcnow().isoformat(timespec='seconds')}Z_\n\n"
        )

        for chap in sorted(by_chapter):
            out.write(f"## {chap}\n\n")
            rows = sorted(
                by_chapter[chap],
                key=lambda r: (r.get("figure_stem") or "").strip(),
            )
            for row in rows:
                fig = (row.get("figure_stem") or "").strip()
                issue = (row.get("issue") or "").strip()
                path_hint = (row.get("path_hint") or "").strip()
                comment = (row.get("comment") or "").strip()

                out.write(f"- **{fig}**  — decision=`REBUILD_LATER`\n")
                if issue:
                    out.write(f"  - issue      : `{issue}`\n")
                if path_hint:
                    out.write(f"  - path_hint  : `{path_hint}`\n")

                # Répertoire de scripts correspondant au chapitre
                scripts_dir = root / "zz-scripts" / chap
                if scripts_dir.is_dir():
                    out.write(f"  - scripts_dir: `./zz-scripts/{chap}/`\n")
                else:
                    out.write(
                        "  - scripts_dir: <à préciser> "
                        "(répertoire ./zz-scripts/… introuvable)\n"
                    )

                if comment:
                    out.write(f"  - comment    : {comment}\n")

                out.write("\n")

    print(f"TODO écrit dans : {out_path}")


if __name__ == "__main__":
    main()
