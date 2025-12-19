#!/usr/bin/env python3
"""
MCGT Step13 : backstage triage initial

- Lit le dernier fichier zz-logs/step12_backstage_candidates_*.txt
- Extrait tous les fichiers BACKSTAGE par chapitre
- Produit zz-logs/step13_backstage_triage_YYYYMMDDTHHMMSSZ.txt
  avec une action par ligne : {KEEP, ATTIC}.

Usage (depuis la racine du dépôt) :
    python tools/mcgt_step13_backstage_triage.py
"""

from __future__ import annotations

from pathlib import Path
from datetime import datetime, timezone


def find_repo_root() -> Path:
    """
    Essaie d'inférer la racine du dépôt :
    - d'abord en remontant depuis ce fichier (__file__)
    - fallback sur le cwd si zz-logs/ n'est pas trouvé.
    """
    here = Path(__file__).resolve()
    # On remonte de quelques niveaux au cas où le script est dans tools/ ou zz-tools/
    for parent in [here.parent, *here.parents]:
        candidate = parent / "zz-logs"
        if candidate.is_dir():
            return parent
    # Fallback : cwd
    return Path.cwd()


def load_backstage_entries(step12_path: Path):
    """
    Parse le fichier Step12 pour récupérer les couples (chapitre, chemin).
    """
    entries = []
    current_ch = None

    with step12_path.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")

            # Détection d'un nouveau bloc [CHxx] BACKSTAGE candidates
            if line.startswith("[CH") and "BACKSTAGE candidates" in line:
                # Exemple de ligne : "[CH01] BACKSTAGE candidates"
                tag = line.split("]", 1)[0]  # "[CH01"
                current_ch = tag.strip("[]")  # "CH01"
                continue

            # Lignes de fichiers (indentées, chemins relatifs)
            if current_ch and line.strip().startswith("zz-"):
                path = line.strip()
                entries.append((current_ch, path))

    return entries


def classify_action(path: str) -> str:
    """
    Heuristique ultra-conservatrice pour proposer une action par défaut.

    - ATTIC : placeholders structurels
    - KEEP  : tout le reste (backstage conservé, juste annoté)
    """
    low = path.lower()

    if "placeholder" in low:
        return "ATTIC"

    # Par défaut : on garde en backstage
    return "KEEP"


def main() -> None:
    repo_root = find_repo_root()
    logs_dir = repo_root / "zz-logs"

    if not logs_dir.is_dir():
        raise SystemExit(
            f"[ERROR] Répertoire zz-logs/ introuvable à partir de {repo_root}"
        )

    # On prend le dernier fichier step12_backstage_candidates_*.txt
    step12_files = sorted(logs_dir.glob("step12_backstage_candidates_*.txt"))
    if not step12_files:
        raise SystemExit(
            "[ERROR] Aucun fichier step12_backstage_candidates_*.txt trouvé dans zz-logs/."
        )

    step12_path = step12_files[-1]

    entries = load_backstage_entries(step12_path)
    if not entries:
        raise SystemExit(f"[ERROR] Aucun candidat BACKSTAGE détecté dans {step12_path}")

    now = datetime.now(timezone.utc)
    timestamp = now.strftime("%Y%m%dT%H%M%SZ")
    out_path = logs_dir / f"step13_backstage_triage_{timestamp}.txt"

    with out_path.open("w", encoding="utf-8") as out:
        out.write("=== MCGT Step13 : backstage triage initial ===\n")
        out.write(f"[INFO] Source Step12 : {step12_path}\n")
        out.write(f"[INFO] Généré le (UTC) : {timestamp}\n\n")

        out.write("# Format :\n")
        out.write("#   ACTION  CHxx  <chemin_relatif>\n")
        out.write("# où ACTION ∈ {KEEP, ATTIC}\n")
        out.write("#   - KEEP  : fichier conservé en backstage (niveau 2)\n")
        out.write("#   - ATTIC : candidat à attic/ ou testdata à moyen terme\n")
        out.write("#\n")
        out.write(
            "# Tu peux (et dois) éditer ACTION à la main avant d'appliquer un Step14.\n\n"
        )

        current_ch = None
        for ch, path in entries:
            # Ligne de séparation par chapitre
            if ch != current_ch:
                if current_ch is not None:
                    out.write("\n")
                out.write(f"# {ch} – BACKSTAGE\n")
                current_ch = ch

            # On normalise un peu le chemin (on enlève un éventuel './')
            norm_path = path.lstrip("./")

            action = classify_action(norm_path)
            out.write(f"{action:<6} {ch}  {norm_path}\n")

    print(f"[INFO] Repo root : {repo_root}")
    print(f"[INFO] Fichier Step12 utilisé : {step12_path}")
    print(f"[INFO] Candidats BACKSTAGE analysés : {len(entries)}")
    print(f"[INFO] Écrit → {out_path}")


if __name__ == "__main__":
    main()
