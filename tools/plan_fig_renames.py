#!/usr/bin/env python3
import re, unicodedata, sys
from pathlib import Path

ROOT = Path("zz-figures")
OUT_DIR = Path(".ci-out")
OUT_DIR.mkdir(parents=True, exist_ok=True)
MAP_TSV = OUT_DIR / "figures_rename_plan.tsv"
SCRIPT_SH = OUT_DIR / "apply_fig_renames.sh"

def slugify(s: str) -> str:
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")
    s = s.lower()
    s = re.sub(r"[^a-z0-9._-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s

def propose_target(chap: str, fname: str) -> str:
    # chap like 'chapter07'
    m = re.match(r"^chapter(\d{2})$", chap)
    if not m:
        return ""
    nn = m.group(1)

    stem, ext = Path(fname).stem, Path(fname).suffix.lower()

    # cases:
    #  - fig_01_xyz.png          ->  NN_fig_01_xyz.png
    #  - fig03_xyz.png           ->  NN_fig_03_xyz.png
    #  - fig_03b_xyz.png         ->  NN_fig_03b_xyz.png  (on tolère la lettre)
    #  - anything_else.png       ->  NN_fig_<slug>.png   (met tout le nom en slug)
    cand = None
    if stem.startswith("fig_"):
        rest = stem[4:]  # after 'fig_'
        cand = f"{nn}_fig_{rest}"
    else:
        m2 = re.match(r"^fig(\d+[a-z]?)_(.+)$", stem)  # fig03_xyz, fig03b_xyz
        if m2:
            cand = f"{nn}_fig_{m2.group(1)}_{m2.group(2)}"
        else:
            cand = f"{nn}_fig_{stem}"

    cand = slugify(cand) + ext
    return cand

rows = []
for p in sorted(ROOT.rglob("*")):
    if not p.is_file():
        continue
    if p.suffix.lower() not in [".png", ".pdf"]:
        continue
    parts = p.relative_to(ROOT).parts
    if len(parts) < 2:
        continue
    chap = parts[0]
    fname = parts[-1]
    # skip already canonical names
    if re.fullmatch(rf"{chap}/\d{{2}}_fig_[a-z0-9_]+\.(png|pdf)", f"{chap}/{fname}"):
        continue
    target_name = propose_target(chap, fname)
    if not target_name:
        continue
    target_path = ROOT / chap / target_name
    if target_path == p:
        continue
    rows.append((str(p), str(target_path)))

# Write TSV plan
with MAP_TSV.open("w", encoding="utf-8") as f:
    f.write("source\tproposed_target\n")
    for s, t in rows:
        f.write(f"{s}\t{t}\n")

# Write apply script (dry by default)
with SCRIPT_SH.open("w", encoding="utf-8") as f:
    f.write("#!/usr/bin/env bash\nset -Eeuo pipefail\nAPPLY=${APPLY:-0}\n")
    f.write("PLAN='.ci-out/figures_rename_plan.tsv'\n")
    f.write("test -f \"$PLAN\" || { echo \"Plan introuvable: $PLAN\"; exit 1; }\n")
    f.write("tail -n +2 \"$PLAN\" | while IFS=$'\\t' read -r SRC DST; do\n")
    f.write("  echo \"mv -- \"$SRC\" \"$DST\"\";\n")
    f.write("  if [ \"$APPLY\" = \"1\" ]; then mkdir -p \"$(dirname \"$DST\")\"; mv -- \"$SRC\" \"$DST\"; fi\n")
    f.write("done\n")
print(f"[fig-rename] {len(rows)} propositions → {MAP_TSV} ; script: {SCRIPT_SH}")
