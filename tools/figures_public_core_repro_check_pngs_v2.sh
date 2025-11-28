#!/usr/bin/env bash
set -Eeuo pipefail

# Se placer à la racine du dépôt
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python - << 'PY'
from pathlib import Path
from collections import defaultdict
import re

ROOT = Path(".").resolve()
scripts_root = ROOT / "zz-scripts"

entries = []

# On considère tous les scripts plot_figNN_*.py dans zz-scripts/chapter??
for chap_dir in sorted(scripts_root.glob("chapter??")):
    chap_id = chap_dir.name           # ex: chapter03
    chap_num = chap_id[-2:]           # ex: 03
    for script in sorted(chap_dir.glob("plot_fig*_*.py")):
        name = script.name
        m = re.match(r"plot_fig(\d+)_([^.]+)\.py$", name)
        if not m:
            continue
        fig_num = f"{int(m.group(1)):02d}"   # normalisation 2 chiffres
        slug = m.group(2).lower()            # slug canonique en minuscules
        png_rel = Path("zz-figures") / chap_id / f"{chap_num}_fig_{fig_num}_{slug}.png"
        entries.append((chap_id, chap_num, fig_num, slug, png_rel))

if not entries:
    print("Aucune figure PUBLIC+script détectée (aucun plot_fig*_*.py trouvé).")
    raise SystemExit(0)

stats = defaultdict(lambda: [0, 0])  # chapitre -> [present, missing]
present = 0
missing = 0

for chap_id, chap_num, fig_num, slug, png_rel in entries:
    png_path = ROOT / png_rel
    if png_path.exists():
        stats[chap_id][0] += 1
        present += 1
    else:
        stats[chap_id][1] += 1
        missing += 1

total = len(entries)

print("########## PUBLIC+SCRIPT PNG COVERAGE (auto scan) ##########")
print(f"Total figures PUBLIC+script : {total}")
print(f"PNG présents                : {present}")
print(f"PNG manquants               : {missing}")
print()
print("Par chapitre :")
for chap_id in sorted(stats.keys()):
    p, m = stats[chap_id]
    print(f"  - {chap_id}: present={p}, missing={m}")
PY
