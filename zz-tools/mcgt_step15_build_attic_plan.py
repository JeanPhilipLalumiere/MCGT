#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from datetime import datetime, timezone
import sys


def main() -> None:
    # Racine = répertoire courant (tu exécutes depuis /home/jplal/MCGT)
    root = Path.cwd()
    triage_dir = root / "zz-logs"

    triage_files = sorted(triage_dir.glob("step13_backstage_triage_*.txt"))
    if not triage_files:
        print(
            "[ERROR] Aucun fichier step13_backstage_triage_*.txt trouvé dans zz-logs/",
            file=sys.stderr,
        )
        raise SystemExit(1)

    triage_path = triage_files[-1]

    now = datetime.now(timezone.utc)
    timestamp = now.strftime("%Y%m%dT%H%M%SZ")
    out_path = triage_dir / f"step15_backstage_attic_plan_{timestamp}.txt"

    n_attic = 0

    with triage_path.open("r", encoding="utf-8") as f_in, out_path.open(
        "w", encoding="utf-8"
    ) as f_out:
        f_out.write("=== MCGT Step15 : plan attic pour BACKSTAGE ===\n")
        f_out.write(f"# Source : {triage_path}\n")
        f_out.write(f"# Généré le (UTC) : {timestamp}\n\n")
        f_out.write("# Format :\n")
        f_out.write("#   ATTIC  <chemin>\n")
        f_out.write("# (Les entrées KEEP ne sont pas reprises ici.)\n")
        f_out.write("# Tu peux éditer ce fichier à la main avant d'appliquer le ménage.\n\n")

        for raw in f_in:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) < 3:
                continue

            action = parts[0].upper()
            # chap = parts[1]  # CH01, CH02, etc. (non utilisé pour le moment)
            path = " ".join(parts[2:])

            if action == "ATTIC":
                f_out.write(f"ATTIC  {path}\n")
                n_attic += 1

    print(f"[INFO] Fichier triage utilisé : {triage_path}")
    print(f"[INFO] Entrées ATTIC détectées : {n_attic}")
    print(f"[INFO] Plan attic Step15 écrit -> {out_path}")


if __name__ == "__main__":
    main()
