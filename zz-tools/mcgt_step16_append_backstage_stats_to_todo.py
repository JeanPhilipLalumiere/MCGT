#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys


def main() -> None:
    root = Path.cwd()
    todo_path = root / "TODO_CLEANUP.md"

    if not todo_path.exists():
        print(f"[ERROR] Fichier TODO_CLEANUP.md introuvable à {todo_path}", file=sys.stderr)
        raise SystemExit(1)

    logs_dir = root / "zz-logs"
    stats_files = sorted(logs_dir.glob("step14_backstage_stats_*.txt"))
    if not stats_files:
        print(
            "[ERROR] Aucun fichier step14_backstage_stats_*.txt trouvé dans zz-logs/",
            file=sys.stderr,
        )
        raise SystemExit(1)

    stats_path = stats_files[-1]

    # Sécurité : ne pas dupliquer la section si elle existe déjà
    existing = todo_path.read_text(encoding="utf-8")
    marker = "## Step14 – FRONT/BACKSTAGE (snapshot)"
    if marker in existing:
        print("[INFO] Section Step14 existe déjà dans TODO_CLEANUP.md, aucune modification.")
        print(f"[INFO] Stats utilisées : {stats_path}")
        return

    stats_content = stats_path.read_text(encoding="utf-8")

    section = []
    section.append("\n---\n")
    section.append("## Step14 – FRONT/BACKSTAGE (snapshot)\n\n")
    section.append("_Dernière génération via Step14 (stats FRONT / BACKSTAGE par chapitre)._")
    section.append("\n\n```text\n")
    section.append(stats_content.rstrip("\n"))
    section.append("\n```\n")

    new_content = existing.rstrip("\n") + "".join(section) + "\n"

    todo_path.write_text(new_content, encoding="utf-8")

    print(f"[INFO] Section Step14 ajoutée à TODO_CLEANUP.md")
    print(f"[INFO] Stats Step14 utilisées : {stats_path}")


if __name__ == "__main__":
    main()
