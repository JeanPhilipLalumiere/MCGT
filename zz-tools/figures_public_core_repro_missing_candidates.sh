#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MCGT_ROOT="$ROOT"

python - << 'PY'
import os
import re
from pathlib import Path

ROOT = Path(os.environ["MCGT_ROOT"]).resolve()
scripts = sorted(ROOT.glob("zz-scripts/chapter??/plot_fig*.py"))

figs = []
for script in scripts:
    chapter_dir = script.parent.name
    if not chapter_dir.startswith("chapter"):
        continue
    chapter_num = chapter_dir.replace("chapter", "")

    stem = script.stem
    m = re.search(r"fig_?(\d\d)_(.+)", stem)
    if not m:
        continue
    num, slug_raw = m.groups()
    slug = slug_raw.lower()
    expected = ROOT / "zz-figures" / chapter_dir / f"{chapter_num}_fig_{num}_{slug}.png"
    figs.append((chapter_dir, chapter_num, num, slug, script, expected))

missing = [f for f in figs if not f[5].exists()]

print("########## PUBLIC+SCRIPT PNG MISSING – CANDIDATES (auto scan) ##########")
print(f"Nombre total de figures PUBLIC+script manquantes : {len(missing)}")
print()

for chapter_dir, chapter_num, num, slug, script, expected in missing:
    print(f"- {chapter_dir} / fig_{num}_{slug}")
    try:
        rel_expected = expected.relative_to(ROOT)
    except ValueError:
        rel_expected = expected
    print(f"    attendu : {rel_expected}")

    chapter_fig_dir = expected.parent
    candidates = []
    if chapter_fig_dir.is_dir():
        # on cherche des PNG contenant le même numéro de figure "fig_XX"
        for png in sorted(chapter_fig_dir.glob("*.png")):
            name = png.name
            if f"fig_{num}" in name:
                candidates.append(name)

    if candidates:
        print("    candidats trouvés :")
        for name in candidates:
            print(f"      - {name}")
    else:
        print("    candidats trouvés : (aucun PNG correspondant dans ce chapitre)")
    print()

PY
