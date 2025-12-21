#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: maintenance checkpoint" || true

# --- Split des imports multiples (E401) ---
sed -i 's/^import \([A-Za-z0-9_]\+\), \([A-Za-z0-9_]\+\)/import \1\nimport \2/' \
  scripts/chapter07/plot_fig01_cs2_heatmap.py \
  scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py || true

# --- ch07: normaliser le bloc pngs = sorted(...) et son indentation ---
python3 - <<'PY'
from pathlib import Path, re
p = Path("scripts/chapter07/plot_fig01_cs2_heatmap.py")
if not p.exists(): raise SystemExit(0)
s = p.read_text(encoding="utf-8").replace("\t","    ")
lines = s.splitlines(True)
i = 0; changed = False
while i < len(lines):
    if re.match(r'^[ \t]*pngs\s*=\s*sorted\(\s*$', lines[i]):
        base = re.match(r'^[ ]*', lines[i]).group(0)
        new = [
            f"{base}pngs = sorted(\n",
            f"{base}        glob.glob(os.path.join(_default_dir, \"*.png\")),\n",
            f"{base}        key=os.path.getmtime,\n",
            f"{base}        reverse=True,\n",
            f"{base})\n",
        ]
        j = i + 1; depth = 1
        while j < len(lines) and depth > 0:
            for ch in lines[j]:
                if ch == "(": depth += 1
                elif ch == ")": depth -= 1
            j += 1
        lines[i:j] = new; changed = True; i += len(new)
    else:
        i += 1
if changed:
    p.write_text("".join(lines), encoding="utf-8")
print({"ch07_pngs_sorted_fixed": changed})
PY

# --- ch06: E202 (espace avant ')') + soft wrap E501 + réindent safe ---
python3 - <<'PY'
from pathlib import Path, re
p = Path("scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py")
if not p.exists(): raise SystemExit(0)
s = p.read_text(encoding="utf-8").replace("\t", "    ")
s = re.sub(r'[ ]+\)', ')', s)

def wrap_long_calls(text, cutoff=100, cont_indent=8):
    out = []
    for line in text.splitlines(True):
        if len(line.rstrip("\n")) <= cutoff:
            out.append(line); continue
        if "(" in line and ")" in line and line.count("(") == 1 and ", " in line:
            prefix, rest = line.split("(", 1)
            items = [x.strip() for x in rest.rstrip().rstrip("\n").rstrip(")").split(",")]
            if len(items) > 1:
                ws = re.match(r'^[ ]*', prefix).group(0)
                out.append(prefix + "(\n")
                for k, it in enumerate(items):
                    if it == "": continue
                    sep = "," if k < len(items)-1 else ""
                    out.append(ws + " " * cont_indent + it + sep + "\n")
                out.append(ws + ")\n")
                continue
        out.append(line)
    return "".join(out)

s2 = wrap_long_calls(s, cutoff=100, cont_indent=8)
if s2 != s:
    p.write_text(s2, encoding="utf-8")
print({"ch06_softwrap_applied": s2 != s})
PY

# --- autopep8 ciblé ---
python - <<'PY' || true
import sys, subprocess
subprocess.run([sys.executable, "-m", "pip", "install", "--user", "autopep8"], check=False)
PY

python -m autopep8 --in-place \
  --select E122,E128,E131,E225,E231,E266,E301,E302,E305,E401,E501,W291,W391 \
  --aggressive --aggressive \
  scripts/chapter07/plot_fig01_cs2_heatmap.py \
  scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py || true

# --- pycodestyle (non bloquant) ---
python -m pycodestyle scripts/chapter07/plot_fig01_cs2_heatmap.py || true
python -m pycodestyle scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py || true

# --- Commit & push ---
git add -A
git commit -m "style/maint: normalize ch07 sorted-block; ch06 E202/E501 soft-wrap; split imports; autopep8" || true
git push || true

# --- Re-smoke (honore MCGT_OUTDIR si défini) ---
if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
