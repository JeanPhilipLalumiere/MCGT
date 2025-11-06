#!/usr/bin/env python3
# SAFE PLACEHOLDER (compilable) — generate_data_chapter08
# Conserve la CLI, neutralise l'exécution pour éviter toute fermeture de session.

import argparse, logging, sys
from pathlib import Path

def parse_args():
    p = argparse.ArgumentParser(description="Génère les données du Chapitre 8 (placeholder compilable).")
    p.add_argument("-i", "--ini", help="INI de config")
    p.add_argument("--export-raw", help="CSV brut unifié (sortie)")
    p.add_argument("--export-2d", action="store_true", help="Exporter matrices 2D")
    p.add_argument("--n-k", type=int, metavar="NK", help="Override # points k")
    p.add_argument("--n-a", type=int, metavar="NA", help="Override # points a")
    p.add_argument("--dry-run", action="store_true", help="Valide config et grille (aucun calcul)")
    p.add_argument("--log-level", default="INFO", choices=["DEBUG","INFO","WARNING","ERROR","CRITICAL"])
    p.add_argument("--log-file", metavar="FILE", help="Fichier log")
    return p.parse_args()

def main():
    args = parse_args()
    logging.basicConfig(level=getattr(logging, args.log_level, logging.INFO),
                        format="[%(levelname)s] %(message)s")
    if args.log_file:
        try:
            Path(args.log_file).parent.mkdir(parents=True, exist_ok=True)
            fh = logging.FileHandler(args.log_file)
            fh.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
            logging.getLogger().addHandler(fh)
        except Exception:
            pass
    logging.info("OK (placeholder). Aucun calcul effectué.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
