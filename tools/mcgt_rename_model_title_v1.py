#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path
from datetime import datetime, timezone
import shutil


ROOT = Path(__file__).resolve().parent.parent

OLD = "Modèle de la Courbure Gravitationnelle du Temps"
NEW = "Modèle de la Courbure Gravitationnelle du Temps"

SKIP_DIRS = {
    ".git",
    "attic",
    ".ci-logs",
    ".ci-archive",
    ".mypy_cache",
    ".pytest_cache",
    "__pycache__",
}


def should_skip(path: Path) -> bool:
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        return True
    parts = rel.parts
    return any(part in SKIP_DIRS for part in parts)


def main() -> None:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    total_files = 0
    total_repl = 0

    print(f"[INFO] Racine du dépôt: {ROOT}")
    print(f"[INFO] Chaîne ancienne: {OLD!r}")
    print(f"[INFO] Chaîne nouvelle: {NEW!r}")
    print("[INFO] Répertoires ignorés:", ", ".join(sorted(SKIP_DIRS)))
    print()

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if should_skip(path):
            continue

        rel = path.relative_to(ROOT)

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            # Probablement binaire ou encodage exotique : on ne touche pas
            # (on logge juste une ligne pour information)
            # print(f"[SKIP(binary?)] {rel}")
            continue

        if OLD not in text:
            continue

        count = text.count(OLD)
        new_text = text.replace(OLD, NEW)

        backup = path.with_name(path.name + f".bak_rename_title_{stamp}")
        shutil.copy2(path, backup)

        path.write_text(new_text, encoding="utf-8")

        total_files += 1
        total_repl += count
        print(f"[OK] {rel}: {count} occurrence(s) remplacée(s); backup -> {backup.name}")

    print()
    print(f"[INFO] Fichiers modifiés : {total_files}")
    print(f"[INFO] Occurrences remplacées au total : {total_repl}")

    if total_files == 0:
        print("[INFO] Aucune occurrence trouvée dans les surfaces actives.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[INTERRUPT] Arrêt par l'utilisateur.", file=sys.stderr)
        sys.exit(130)
