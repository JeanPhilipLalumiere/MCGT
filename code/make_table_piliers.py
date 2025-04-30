#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
make_table_piliers.py  ––  Génère tables/piliers.tex
----------------------------------------------------
Tableau récapitulatif (Booktabs) des contraintes 2024-25 sur β
provenant des quatre « piliers » observationnels :

    • Horloges atomiques
    • Variabilité des quasars
    • Chronomètres + BAO
    • BBN & CMB

Usage :
    python make_table_piliers.py
Le fichier LaTeX est enregistré dans  tables/piliers.tex  et peut être
inclus dans le manuscrit via  \input{tables/piliers} .
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
from pathlib import Path
import csv

# ----------------------------------------------------------------------
# 2. Lecture (CSV) ou valeurs par défaut
# ----------------------------------------------------------------------
csv_path = Path("../data/beta_pillars.csv")

default_rows = [
    # pillar,                 z_range,    beta,   sigma,   reference(s)
    ("Horloges atomiques",    "z≈0",      -0.30,  0.10, "Delva 2019; Grotti 2018"),
    ("Variabilité quasars",   "1<z<4",    -0.33,  0.14, "Cao 2023; Zheng 2023"),
    ("Chronomètres + BAO",    "0.1<z<2",  -0.26,  0.07, "Moresco 2022; DES 2022"),
    ("BBN \\& CMB",           "$z>10^{4}$",-0.24, 0.08, "Planck 2020"),
]

rows = []
if csv_path.is_file():
    with csv_path.open(newline="", encoding="utf-8") as f:
        rdr = csv.DictReader(f)
        for r in rdr:
            rows.append((
                r["pillar"],
                r["z_range"],
                float(r["beta"]),
                float(r["sigma"]),
                r["reference"]
            ))
else:
    rows = default_rows

# ----------------------------------------------------------------------
# 3. Génération du LaTeX
# ----------------------------------------------------------------------
tex_lines = [
    r"\begin{table}[ht]",
    r"  \centering",
    r"  \caption{Contraintes 2024--25 sur le paramètre $\beta$ issues de quatre familles d'observables.}",
    r"  \label{tab:piliers}",
    r"  \begin{tabular}{lccp{4cm}}",
    r"    \toprule",
    r"    Pilier empirique & Intervalle de $z$ & $\beta\,(1\sigma)$ & Références \\",
    r"    \midrule"
]

for pillar, z_rng, beta, sigma, ref in rows:
    tex_lines.append(
        f"    {pillar} & {z_rng} & ${beta:+.2f}\\pm{sigma:.2f}$ & {ref} \\\\"
    )

tex_lines += [
    r"    \bottomrule",
    r"  \end{tabular}",
    r"\end{table}",
    ""
]

# ----------------------------------------------------------------------
# 4. Écriture du fichier
# ----------------------------------------------------------------------
tables_dir = Path("../tables")
tables_dir.mkdir(exist_ok=True)
out_path = tables_dir / "piliers.tex"
out_path.write_text("\n".join(tex_lines), encoding="utf-8")

print(f"[OK] Tableau LaTeX écrit : {out_path.relative_to(Path.cwd())}")
