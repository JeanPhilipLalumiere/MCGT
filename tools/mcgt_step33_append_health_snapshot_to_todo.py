#!/usr/bin/env python
from __future__ import annotations

from pathlib import Path


def main() -> None:
    # Repo root = parent de tools/
    root = Path(__file__).resolve().parents[1]
    logs_dir = root / "zz-logs"
    todo_path = root / "TODO_CLEANUP.md"

    if not logs_dir.is_dir():
        raise SystemExit(f"[ERROR] Répertoire de logs introuvable : {logs_dir}")

    # On prend le dernier log de Step22
    health_logs = sorted(logs_dir.glob("step22_health_*.log"))
    if not health_logs:
        raise SystemExit(
            "[ERROR] Aucun fichier step22_health_*.log trouvé dans zz-logs/."
        )

    latest = health_logs[-1]
    log_text = latest.read_text(encoding="utf-8").rstrip("\n")

    print(f"[INFO] Log Step22 utilisé : {latest}")

    # On fabrique la section à ajouter à TODO_CLEANUP.md
    section = []
    section.append("\n---\n")
    section.append("## Step22 – HEALTH_CHECK_COMPLET (snapshot)\n\n")
    section.append(
        f"_Dernière exécution Step22 (health-check complet) – log : `{latest.name}`._\n\n"
    )
    section.append("```text\n")
    section.append(log_text)
    section.append("\n```\n")

    with todo_path.open("a", encoding="utf-8") as f:
        f.write("".join(section))

    print("[INFO] Section Step22 (health-check) ajoutée à TODO_CLEANUP.md")
    print(f"[INFO] Fichier TODO mis à jour : {todo_path}")


if __name__ == "__main__":
    main()
