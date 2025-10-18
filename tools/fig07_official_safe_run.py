#!/usr/bin/env python3
import csv, math, subprocess, shutil, os
from pathlib import Path

CSV = Path("zz-figures/chapter10/10_fig_07_synthesis.table.csv")
PNG = Path("zz-figures/chapter10/10_fig_07_synthesis.png")
PLOT = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")

def count_numeric_rows(p: Path) -> int:
    if not p.exists():
        return 0
    rows = list(csv.DictReader(p.open(encoding="utf-8")))
    def num(x):
        try: return math.isfinite(float(x))
        except: return False
    n = 0
    for r in rows:
        if num(r.get("N")) and (num(r.get("coverage")) or num(r.get("width_mean"))):
            n += 1
    return n

def main():
    # 1) Sauvegarde
    bak = CSV.with_suffix(".csv.bak_safe")
    if CSV.exists():
        shutil.copy2(CSV, bak)

    # 2) Exécute la version "officielle"
    cmd = [
        "python3", str(PLOT),
        "--manifest-a", "zz-manifests/figure_manifest.json",
        "--label-a", "Chapter 10",
        "--ymin-coverage", "0", "--ymax-coverage", "1",
        "--dpi", "300", "--out", str(PNG),
    ]
    print("[RUN]", " ".join(cmd))
    subprocess.run(cmd, check=False)

    # 3) Valide le CSV ; si vide, restaure la sauvegarde
    n = count_numeric_rows(CSV)
    if n == 0:
        print("[WARN] CSV Fig07 généré vide. Restauration de la sauvegarde…")
        if bak.exists():
            shutil.copy2(bak, CSV)
        else:
            print("[ERR] Aucune sauvegarde disponible. Je regénère depuis Fig03b.")
            # Recompose la table depuis la source de vérité
            subprocess.run(["python3", "tools/fig07_fill_table_from_03b_v2.py"], check=True)

    # 4) (Re)génère une figure sûre depuis le CSV (voie minimale)
    subprocess.run(["python3", "tools/plot_fig07_from_table_min.py"], check=True)
    print("[OK] Fig.07 verrouillée et à jour.")

if __name__ == "__main__":
    main()
