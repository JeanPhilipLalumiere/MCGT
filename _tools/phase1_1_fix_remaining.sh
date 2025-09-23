#!/usr/bin/env bash
# Pas de -e (on ne casse pas le shell en cas de fail partiel)
set -u
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"
mkdir -p "${REPORTS}"

log(){ printf "%s\n" "$*" | tee -a "${REPORTS}/phase1_1_fix_remaining.log" ; }

log "==[A] F841: tuple-assign -> préfixe _y0_user =="
python - <<'PY'
from pathlib import Path, re

def fix_tuple_var(path: Path):
    if not path.exists(): return False
    s = path.read_text(encoding="utf-8")
    # y0_user, y1_user = ...  ->  _y0_user, y1_user = ...
    s2 = re.sub(r'^(\s*)y0_user(\s*,\s*y1_user\s*=)',
                r'\1_y0_user\2', s, flags=re.MULTILINE)
    if s2 != s:
        path.write_text(s2, encoding="utf-8"); return True
    return False

changed = []
for f in [
    "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py",
    "zz-scripts/chapter10/regen_fig05_using_circp95.py",
]:
    if fix_tuple_var(Path(f)): changed.append(f)
print("changed:", changed)
PY

log "==[B] F821: restore cohérence candidates->paths dans find_top_residuals() =="
python - <<'PY'
from pathlib import Path

p = Path("zz-scripts/chapter10/bootstrap_topk_p95.py")
if p.exists():
    lines = p.read_text(encoding="utf-8").splitlines()
    out = []
    in_def = False
    for i, L in enumerate(lines):
        if L.lstrip().startswith("def find_top_residuals("):
            in_def = True
        elif in_def and L.lstrip().startswith("def "):
            in_def = False
        if in_def:
            # Harmonise le nom local pour éviter F821 (casse insensible aux précédents patchs)
            L = L.replace("candidates =", "paths =")
            L = L.replace("for p in candidates:", "for p in paths:")
        out.append(L)
    p.write_text("\n".join(out) + "\n", encoding="utf-8")
print("patched:", p.exists())
PY

log "==[C] E402+F841 dans mcgt/__init__.py =="
python - <<'PY'
from pathlib import Path
p = Path("mcgt/__init__.py")
if p.exists():
    lines = p.read_text(encoding="utf-8").splitlines()
    wanted = [
        "from pathlib import Path",
        "import configparser",
        "import importlib",
        "import pkgutil",
        "from typing import Optional, List",
    ]
    for i, L in enumerate(lines):
        for w in wanted:
            if L.strip().startswith(w) and "# noqa: E402" not in L:
                lines[i] = L + "  # noqa: E402"
        if "cfg = get_config()" in L and "print_summary" in "".join(lines[max(0,i-5):i+5]):
            lines[i] = L.replace("cfg = ", "_cfg = ")
    p.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("patched:", p.exists())
PY

log "==[D] F524: braces LaTeX -> double accolades avec .format() =="
python - <<'PY'
from pathlib import Path
p = Path("zz-scripts/chapter08/plot_fig03_mu_vs_z.py")
if p.exists():
    s = p.read_text(encoding="utf-8")
    # Sécurise les accolades LaTeX vis-à-vis de str.format
    s2 = s.replace("{\\rm th}", "{{\\rm th}}").replace("{\rm th}", "{{\\rm th}}")
    if s2 != s:
        p.write_text(s2, encoding="utf-8")
print("patched:", p.exists())
PY

log "==[E] Ruff ciblé (E402,E731,E741,F841,F821,F524) =="
ruff check zz-manifests zz-scripts mcgt --select E402,E731,E741,F841,F821,F524 | tee "${REPORTS}/ruff_after_1_1.txt" || true

log "==[F] Format + Lint pre-commit =="
pre-commit run ruff-format --all-files | tee -a "${REPORTS}/precommit_ruff_format.txt" || true
pre-commit run ruff --all-files | tee -a "${REPORTS}/precommit_ruff.txt" || true

log "==[G] Commit & push =="
git add -A
git commit -m "chore(lint): fix residual E402/F841/F524/F821; keep executor safe" || true
git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true

log ">>> Phase 1.1 done — rapports: ${REPORTS}"
