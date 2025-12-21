#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before postparse v3 (style opt-in)" || true

mkdir -p scripts/_common

# 1) _common/style.py — thèmes 'paper', 'talk', 'mono'
cat > scripts/_common/style.py <<'PY'
"""
MCGT common figure styles (opt-in).
Usage:
    import scripts._common.style  # via postparse loader
    style.apply(theme="paper")       # or "talk", "mono"
"""
from __future__ import annotations
import matplotlib

_THEMES = {
    "paper": dict(
        figure_dpi=150,
        font_size=9,
        font_family="DejaVu Sans",
        axes_linewidth=0.8,
        grid=True,
    ),
    "talk": dict(
        figure_dpi=150,
        font_size=12,
        font_family="DejaVu Sans",
        axes_linewidth=1.0,
        grid=True,
    ),
    "mono": dict(
        figure_dpi=150,
        font_size=9,
        font_family="DejaVu Sans Mono",
        axes_linewidth=0.8,
        grid=True,
    ),
}

def apply(theme: str | None) -> None:
    if not theme or theme == "none":
        return
    t = _THEMES.get(theme, _THEMES["paper"])
    rc = matplotlib.rcParams
    # taille police
    rc["font.size"] = t["font_size"]
    rc["font.family"] = [t["font_family"]]
    # traits axes
    rc["axes.linewidth"] = t["axes_linewidth"]
    rc["xtick.major.width"] = t["axes_linewidth"]
    rc["ytick.major.width"] = t["axes_linewidth"]
    # DPI figure par défaut (ne force pas savefig.*)
    rc["figure.dpi"] = t["figure_dpi"]
    # grille légère
    rc["axes.grid"] = bool(t["grid"])
    rc["grid.linestyle"] = ":"
    rc["grid.linewidth"] = 0.6
PY

# 2) upgrade _common/postparse.py (v3): applique style si args.style
python3 - <<'PY'
from pathlib import Path
import re, textwrap, os, sys

p = Path("scripts/_common/postparse.py")
src = p.read_text(encoding="utf-8")

# Injecte une routine _maybe_apply_style(args) + appel dans apply(args)
if "_maybe_apply_style" not in src:
    insert = textwrap.dedent("""
    import importlib.util

    def _load_style_module():
        # charge style.py voisin sans dépendre d'un package
        here = os.path.dirname(__file__)
        f = os.path.join(here, "style.py")
        if not os.path.exists(f):
            return None
        spec = importlib.util.spec_from_file_location("_mcgt_style", f)
        mod = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(mod)
        return mod

    def _maybe_apply_style(args) -> None:
        try:
            theme = getattr(args, "style", None)
            if not theme:
                return
            mod = _load_style_module()
            if mod and hasattr(mod, "apply"):
                mod.apply(theme=str(theme))
        except Exception:
            pass
    """)
    # Insère avant la fonction apply(...) si trouvée
    m = re.search(r"def\s+apply\s*\(\s*args\s*\)\s*:", src)
    if m:
        src = src[:m.start()] + insert + src[m.start():]

# Ajoute un appel à _maybe_apply_style(args) au début de apply(args)
if "_maybe_apply_style(args)" not in src:
    src = re.sub(r"(def\s+apply\s*\(\s*args\s*\)\s*:\s*\n)",
                 r"\\1    _maybe_apply_style(args)\n", src, count=1)

Path("scripts/_common/postparse.py").write_text(src, encoding="utf-8")
print("postparse_v3_upgraded")
PY

# 3) ajoute --style aux plot_*.py si manquant
python3 - <<'PY'
from pathlib import Path, re, subprocess, json
files = subprocess.check_output(
    ["bash","-lc","git ls-files 'scripts/**/plot_*.py'"]).decode().splitlines()

re_parser   = re.compile(r'^\s*(\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
re_parse    = re.compile(r'\.parse_args\s*\(\s*\)', re.M)
re_has_style= re.compile(r'\.add_argument\(\s*["\']--style["\']', re.M)

changed = []
for fp in files:
    p = Path(fp)
    txt = p.read_text(encoding="utf-8")
    if "import argparse" not in txt:
        continue
    if re_has_style.search(txt):
        continue
    m = re_parser.search(txt)
    mpa= re_parse.search(txt)
    if not (m and mpa):
        continue
    var = m.group(1)
    block = f'{var}.add_argument("--style", choices=["paper","talk","mono","none"], default=None, help="Thème MCGT commun (opt-in)")\n'
    new = txt[:mpa.start()] + block + txt[mpa.start():]
    if new != txt:
        p.write_text(new, encoding="utf-8")
        changed.append(fp)

print({"style_added_to": len(changed), "files": changed[:5]})
PY

# 4) autopep8 light pour lisser l’insertion
python - <<'PY' || true
import sys, subprocess
subprocess.run([sys.executable, "-m", "pip", "install", "--user", "autopep8"], check=False)
PY
mapfile -t files < <(git ls-files 'scripts/**/plot_*.py' | sort)
python -m autopep8 --in-place \
  --select E122,E128,E131,E225,E231,E266,E301,E302,E305,E401,E501,W291,W391 \
  --aggressive --aggressive \
  "${files[@]}" || true

git add -A
git commit -m "feat(style): postparse v3 applies optional common style (--style={paper,talk,mono,none})" || true
git push || true

# 5) Smoke
if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
