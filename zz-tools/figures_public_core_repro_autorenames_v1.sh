#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MCGT_ROOT="$ROOT"

python - << 'PY'
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(os.environ["MCGT_ROOT"]).resolve()

# Synonymes acceptés pour certains slugs (canonical -> ensemble de slugs candidats)
SLUG_SYNONYMS = {
    "delta_cls_relative": {"delta_cls_relative", "delta_cls_rel"},
    # on pourra en ajouter plus tard si besoin
}

def accepted_candidate_slug(canonical: str, candidate: str) -> bool:
    canonical = canonical.lower()
    candidate = candidate.lower()
    allowed = SLUG_SYNONYMS.get(canonical, {canonical})
    return candidate in allowed

# 1) Collecte des figures à partir des scripts
scripts = sorted(ROOT.glob("zz-scripts/chapter??/plot_fig*.py"))
figs = []
for script in scripts:
    chapter_dir = script.parent.name  # ex: chapter03
    if not chapter_dir.startswith("chapter"):
        continue
    chapter_num = chapter_dir.replace("chapter", "")  # "03"

    stem = script.stem  # ex: plot_fig07_ricci_fR_vs_z
    m = re.search(r"fig_?(\d\d)_(.+)", stem)
    if not m:
        continue
    num, slug_raw = m.groups()
    slug = slug_raw.lower()

    expected = ROOT / "zz-figures" / chapter_dir / f"{chapter_num}_fig_{num}_{slug}.png"
    figs.append((chapter_dir, chapter_num, num, slug, expected))

# 2) Filtrer ceux dont le PNG canonique est réellement manquant
missing = [(cdir, cnum, num, slug, expected)
           for (cdir, cnum, num, slug, expected) in figs
           if not expected.exists()]

rename_pairs = []

for chapter_dir, chapter_num, num, slug, expected in missing:
    chapter_fig_dir = expected.parent
    if not chapter_fig_dir.is_dir():
        continue

    # On cherche des candidats dans ce répertoire
    for png in sorted(chapter_fig_dir.glob("*.png")):
        name = png.name
        # éviter de re-proposer le nom déjà canonique au cas où
        if png == expected:
            continue

        # pattern: [NN_]fig_XX_slug2.png
        m = re.match(r"(?:\d{2}_)?fig_(\d\d)_(.+)\.png$", name, flags=re.IGNORECASE)
        if not m:
            continue
        c_num, c_slug_raw = m.groups()
        if c_num != num:
            continue

        c_slug = c_slug_raw.lower()
        if accepted_candidate_slug(slug, c_slug):
            rename_pairs.append((png, expected))
            break  # on prend le premier match raisonnable

if not rename_pairs:
    print("[INFO] Aucun renommage automatique trouvé.")
else:
    print("########## RENOMMAGES AUTOMATIQUES PROPOSÉS ##########")
    for src, dst in rename_pairs:
        try:
            rel_src = src.relative_to(ROOT)
        except ValueError:
            rel_src = src
        try:
            rel_dst = dst.relative_to(ROOT)
        except ValueError:
            rel_dst = dst
        print(f"  - {rel_src}  ->  {rel_dst}")

    print()
    print(f"[INFO] Application des git mv pour {len(rename_pairs)} fichiers...")
    for src, dst in rename_pairs:
        dst.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "mv", "-v", str(src), str(dst)], check=True)

    print("[INFO] Renommages terminés.")
PY
