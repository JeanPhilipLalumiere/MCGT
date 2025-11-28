#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python - << 'PY'
from pathlib import Path
import re

ROOT = Path(".").resolve()
scripts_root = ROOT / "zz-scripts"
fig_root = ROOT / "zz-figures"

entries = []

# Même logique de référence que le script de couverture :
for chap_dir in sorted(scripts_root.glob("chapter??")):
    chap_id = chap_dir.name          # ex: chapter03
    chap_num = chap_id[-2:]          # ex: 03
    for script in sorted(chap_dir.glob("plot_fig*_*.py")):
        name = script.name
        m = re.match(r"plot_fig(\d+)_([^.]+)\.py$", name)
        if not m:
            continue
        fig_num = f"{int(m.group(1)):02d}"
        slug = m.group(2).lower()
        png_rel = Path("zz-figures") / chap_id / f"{chap_num}_fig_{fig_num}_{slug}.png"
        entries.append((chap_id, chap_num, fig_num, slug, png_rel))

missing_entries = []
for chap_id, chap_num, fig_num, slug, png_rel in entries:
    if not (ROOT / png_rel).exists():
        missing_entries.append((chap_id, chap_num, fig_num, slug, png_rel))

print("########## PUBLIC+SCRIPT PNG MISSING – CANDIDATES (auto scan) ##########")
print(f"Nombre total de figures PUBLIC+script manquantes : {len(missing_entries)}")

# Heuristique de recherche de candidats :
#  - même chapitre
#  - nom contenant 'fig_<num>' (avec ou sans zéro devant)
#  - et partage d’au moins un token du slug (en minuscules)
for chap_id, chap_num, fig_num, slug, png_rel in sorted(
    missing_entries,
    key=lambda e: (e[1], int(e[2]))
):
    expected_rel = png_rel.as_posix()
    slug_display = slug
    print()
    print(f"- {chap_id} / fig_{fig_num}_{slug_display}")
    print(f"    attendu : {expected_rel}")

    chap_fig_dir = fig_root / chap_id
    candidates = []
    if chap_fig_dir.is_dir():
        slug_tokens = [t for t in slug.lower().split("_") if t]
        for png in sorted(chap_fig_dir.glob("*.png")):
            base = png.name                       # ex: fig_02_fR_fRR_vs_R.png
            if base == png_rel.name:
                continue
            base_lower = base.lower()
            # match sur le numéro de figure
            if not re.search(rf"fig_0*{int(fig_num)}_", base_lower):
                continue
            # match grossier sur le slug (au moins un token partagé)
            if slug_tokens and not any(tok in base_lower for tok in slug_tokens):
                continue
            candidates.append(base)

    if candidates:
        print("    candidats trouvés :")
        for c in candidates:
            print(f"      - {c}")
    else:
        print("    candidats trouvés : (aucun PNG correspondant dans ce chapitre)")
PY
