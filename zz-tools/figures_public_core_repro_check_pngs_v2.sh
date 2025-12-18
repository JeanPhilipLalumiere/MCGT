#!/usr/bin/env bash
set -Eeuo pipefail

# Racine du dépôt = parent de ce script
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MCGT_ROOT="$ROOT"

python - << 'PY'
import os
import re
from pathlib import Path

ROOT = Path(os.environ["MCGT_ROOT"]).resolve()

# On balaie tous les scripts de figures "plot_fig*.py" dans chapter??
scripts = sorted(ROOT.glob("zz-scripts/chapter??/plot_fig*.py"))

figs = []
for script in scripts:
    chapter_dir = script.parent.name  # ex: "chapter03"
    if not chapter_dir.startswith("chapter"):
        continue
    chapter_num = chapter_dir.replace("chapter", "")  # "03"

    stem = script.stem  # ex: "plot_fig05_I1_vs_T"
    m = re.search(r"fig_?(\d\d)_(.+)", stem)
    if not m:
        # on ignore les noms exotiques qui ne suivent pas figXX_slug
        continue
    num, slug_raw = m.groups()  # "05", "I1_vs_T"
    slug = slug_raw.lower()     # normalisation homogène du slug

    expected = ROOT / "zz-figures" / chapter_dir / f"{chapter_num}_fig_{num}_{slug}.png"
    figs.append((chapter_dir, chapter_num, num, slug, script, expected, expected.exists()))

print("########## PUBLIC+SCRIPT PNG COVERAGE (auto scan) ##########")
total = len(figs)
present = sum(1 for f in figs if f[6])
missing = total - present
print(f"Total figures PUBLIC+script : {total}")
print(f"PNG présents                : {present}")
print(f"PNG manquants               : {missing}")
print()

# Agrégat par chapitre
by_chapter = {}
for chapter_dir, chapter_num, num, slug, script, expected, exists in figs:
    d = by_chapter.setdefault(chapter_dir, {"present": 0, "missing": 0})
    if exists:
        d["present"] += 1
    else:
        d["missing"] += 1

print("Par chapitre :")
for chapter_dir in sorted(by_chapter):
    d = by_chapter[chapter_dir]
    print(f"  - {chapter_dir}: present={d['present']}, missing={d['missing']}")

PY
