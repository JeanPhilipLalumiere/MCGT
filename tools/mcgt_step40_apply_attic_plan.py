#!/usr/bin/env python
from __future__ import annotations

from pathlib import Path
import argparse
import subprocess
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Appliquer un plan ATTIC (Step15) en déplaçant les fichiers vers attic/ via git mv."
    )
    parser.add_argument(
        "--plan",
        type=str,
        help="Chemin du fichier step15_backstage_attic_plan_*.txt (par défaut : dernier dans zz-logs/).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Afficher les actions sans exécuter git mv.",
    )
    return parser.parse_args()


def main() -> None:
    # On suppose que le script est dans tools/, repo root = parent du parent
    root = Path(__file__).resolve().parents[1]
    args = parse_args()

    # Localisation du plan Step15
    if args.plan:
        plan_path = Path(args.plan)
        if not plan_path.is_absolute():
            plan_path = root / plan_path
    else:
        candidates = sorted(
            (root / "zz-logs").glob("step15_backstage_attic_plan_*.txt")
        )
        if not candidates:
            print(
                "[ERROR] Aucun fichier step15_backstage_attic_plan_*.txt trouvé dans zz-logs/",
                file=sys.stderr,
            )
            raise SystemExit(1)
        plan_path = candidates[-1]

    print(f"[INFO] Repo root : {root}")
    print(f"[INFO] Plan ATTIC : {plan_path}")

    if not plan_path.is_file():
        print(f"[ERROR] Plan introuvable : {plan_path}", file=sys.stderr)
        raise SystemExit(1)

    attic_root = root / "attic"
    actions: list[tuple[Path, Path, Path]] = []

    # Lecture du plan : lignes de la forme
    #   ATTIC  zz-data/chapter01/...
    #   ATTIC  CH01  zz-data/chapter01/...   (on tolère un token de chapitre au milieu)
    with plan_path.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or line.startswith("="):
                continue

            parts = line.split()
            if not parts or parts[0] != "ATTIC":
                continue

            if len(parts) == 2:
                rel_str = parts[1]
            elif len(parts) >= 3:
                rel_str = parts[-1]
            else:
                continue

            rel_path = Path(rel_str)
            src = root / rel_path
            dst = attic_root / rel_path
            actions.append((rel_path, src, dst))

    if not actions:
        print("[INFO] Aucun chemin ATTIC trouvé dans le plan. Rien à faire.")
        return

    print(f"[INFO] Nombre de chemins ATTIC à traiter : {len(actions)}")
    for rel_path, src, dst in actions:
        rel_dst = dst.relative_to(root)
        print(f"[PLAN] ATTIC {rel_path} -> {rel_dst}")

    if args.dry_run:
        print("[INFO] Dry-run activé : aucune modification appliquée.")
        return

    # Application effective : git mv vers attic/
    for rel_path, src, dst in actions:
        if not src.exists():
            print(
                f"[WARN] Fichier source introuvable, on saute : {rel_path}",
                file=sys.stderr,
            )
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        rel_src = src.relative_to(root)
        rel_dst = dst.relative_to(root)

        print(f"[APPLY] git mv {rel_src} {rel_dst}")
        subprocess.run(
            ["git", "mv", "--", str(rel_src), str(rel_dst)],
            check=True,
        )

    print("[INFO] Application du plan ATTIC terminée.")


if __name__ == "__main__":
    main()
