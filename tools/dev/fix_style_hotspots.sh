#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before style-hotspots fix" || true

# --- A) ch06: rename variable 'l' -> 'ell' en sécurité (tokenize) ---
python3 - <<'PY'
import io, tokenize
from pathlib import Path

p = Path("zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py")
if not p.exists():
    raise SystemExit(0)

src = p.read_text(encoding="utf-8")
tokens = list(tokenize.generate_tokens(io.StringIO(src).readline))
out = []
for t in tokens:
    if t.type == tokenize.NAME and t.string == "l":
        # Nom pur 'l' => remplace par 'ell'
        out.append(tokenize.TokenInfo(t.type, "ell", t.start, t.end, t.line))
    else:
        out.append(t)
new_src = tokenize.untokenize(out)

if new_src != src:
    p.write_text(new_src, encoding="utf-8")
    print({"ch06_l_to_ell": True})
else:
    print({"ch06_l_to_ell": False})
PY

# --- B) ch06 & ch07: corriger E202 (espace avant ')') ---
python3 - <<'PY'
import re
from pathlib import Path

files = [
    "zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py",
    "zz-scripts/chapter07/plot_fig01_cs2_heatmap.py",
]
for f in files:
    p = Path(f)
    if not p.exists():
        continue
    s = p.read_text(encoding="utf-8")
    s2 = re.sub(r"[ ]+\)", ")", s)
    if s2 != s:
        p.write_text(s2, encoding="utf-8")
        print({"fixed_E202_in": f})
PY

# --- C) Politique pycodestyle: longueur 100 ---
# (pycodestyle lira 'setup.cfg' automatiquement)
if [ ! -f setup.cfg ]; then
  cat > setup.cfg <<'CFG'
[pycodestyle]
max-line-length = 100
# on laisse E741 visible si d'autres cas réapparaissent, on l'a corrigé pour ch06
CFG
fi

# --- D) Format ciblé + lint + smoke ---
python - <<'PY' || true
import sys, subprocess
subprocess.run([sys.executable, "-m", "pip", "install", "--user", "autopep8"], check=False)
PY

python -m autopep8 --in-place \
  --select E122,E128,E131,E225,E231,E266,E301,E302,E305,E401,E501,W291,W391 \
  --aggressive --aggressive \
  zz-scripts/chapter07/plot_fig01_cs2_heatmap.py \
  zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py || true

python -m pycodestyle zz-scripts/chapter07/plot_fig01_cs2_heatmap.py || true
python -m pycodestyle zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py || true

git add -A
git commit -m "style: ch06 l->ell tokenize rename; fix E202; pycodestyle max-line-length=100; reformat" || true
git push || true

if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
