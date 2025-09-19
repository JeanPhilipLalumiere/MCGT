# zz-scripts/chapter03/utils/convert_jalons.py
import argparse
import pandas as pd
from pathlib import Path

def main():
    p = argparse.ArgumentParser(description="Extraire le CSV brut des jalons enrichis")
    p.add_argument(
        "--src", required=True,
        help="Chemin vers 03_ricci_fR_jalons_enrichi.csv"
    )
    p.add_argument(
        "--dst",
        default="zz-data/chapter03/03_ricci_fR_jalons.csv",
        help="Chemin de sortie pour le CSV brut"
    )
    args = p.parse_args()

    src_path = Path(args.src)
    if not src_path.exists():
        print(f"Erreur : fichier source introuvable : {src_path}")
        return

    df = pd.read_csv(src_path)
    df[["R_over_R0", "f_R", "f_RR"]].to_csv(args.dst, index=False)
    print(f"Fichier raw généré : {args.dst}")

if __name__ == "__main__":
    main()
