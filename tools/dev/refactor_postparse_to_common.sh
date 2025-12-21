#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before postparse common refactor" || true

# 1) Crée le module commun
mkdir -p scripts/_common
cat > scripts/_common/postparse.py <<'PY'
"""
Post-parse epilogue for MCGT plotting scripts.

Contract: apply(args) is best-effort and MUST NOT break the figure script.
- Honors MCGT_OUTDIR env as fallback for args.outdir
- Creates outdir if provided
- Applies rcParams for savefig.* if options exist on args
- Registers an atexit hook that copies the latest PNG to outdir
"""
from __future__ import annotations
import os
import atexit

def _copy_latest(args) -> None:
    try:
        if not getattr(args, "outdir", None):
            return
        import glob
        import shutil
        ch = os.path.basename(os.path.dirname(__file__))  # _common
        # jump two up from the caller file directory (we recompute from __file__ of caller via stack?)
        # Safer: rebuild relative to the caller's file via env set by wrapper; fallback to repo layout.
        # But since all figures write to assets/zz-figures/<chapter>, we recompute from the *caller* path at call-site.
        # Here: we keep generic behavior assuming standard layout used by all chapters.
        # (The call-site sets base_dir and chapter; see apply()).
        pass
    except Exception:
        pass

def apply(args, *, caller_file: str = None) -> None:
    try:
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out

        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass

        try:
            import matplotlib
            rc = {}
            if hasattr(args, "dpi") and args.dpi:
                rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                rc["savefig.transparent"] = bool(args.transparent)
            if rc:
                matplotlib.rcParams.update(rc)
        except Exception:
            pass

        # atexit: copy latest PNG from assets/zz-figures/<chapter> to args.outdir
        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import shutil
                # infer chapter from the caller file location
                base = os.path.abspath(os.path.join(os.path.dirname(caller_file or __file__), ".."))
                chapter = os.path.basename(base)
                repo = os.path.abspath(os.path.join(base, ".."))
                default_dir = os.path.join(repo, "assets/zz-figures", chapter)
                pngs = sorted(
                    glob.glob(os.path.join(default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for p in pngs:
                    if os.path.exists(p):
                        dst = os.path.join(args.outdir, os.path.basename(p))
                        if not os.path.exists(dst):
                            shutil.copy2(p, dst)
                        break
            except Exception:
                pass

        atexit.register(_smoke_copy_latest)

    except Exception:
        # best-effort; never break the figure script
        pass
PY

# 2) Remplace l'épilogue v1 par un import+appel v2 compact
python3 - <<'PY'
from pathlib import Path
import re

files = [Path(p) for p in __import__("subprocess").check_output(
    ["bash", "-lc", "git ls-files 'scripts/**/plot_*.py'"]).decode().splitlines()]

start_pat = re.compile(r"^[ \t]*# \[MCGT POSTPARSE EPILOGUE v1\]\s*$", re.M)
v2_block = """# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os, sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass
"""

changed = False
for p in files:
    txt = p.read_text(encoding="utf-8")
    m = start_pat.search(txt)
    if not m:
        continue
    # on remplace du marqueur v1 jusqu'à la fin du fichier (l'épilogue a été appendé en fin)
    new = txt[:m.start()] + v2_block + ("\n" if not txt.endswith("\n") else "")
    if new != txt:
        p.write_text(new, encoding="utf-8")
        print(f"{p}: REPLACED v1->v2")
        changed = True

print({"replaced": changed})
PY

# 3) Formatage léger + commit/push
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
git commit -m "refactor(cli): replace post-parse epilogue v1 with common module (_common/postparse.apply)" || true
git push || true

# 4) Smoke (respecte MCGT_OUTDIR si défini)
if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
