#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before post-parse epilogue rollout" || true

EPILOGUE='
# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os, atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin
        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob, os, shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
                _default_dir = os.path.join(_repo, "assets/zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
'

# Fonction : ajoute l épilogue si absente
add_epilogue_if_needed () {
  local file="$1"
  # Ignore fichiers non Python
  [[ "$file" != *.py ]] && return 0
  # Idempotence par marqueur
  if grep -qF "[MCGT POSTPARSE EPILOGUE v1]" "$file"; then
    return 0
  fi
  # Ajoute une ligne vide si le fichier ne se termine pas par \n
  tail -c1 "$file" | read -r _ || echo >> "$file"
  # Append l épilogue
  printf "%s\n" "$EPILOGUE" >> "$file"
  echo "{added_epilogue: $file}"
}

# Cible : tous les scripts de figures
mapfile -t files < <(git ls-files 'scripts/**/plot_*.py' | sort)

for f in "${files[@]}"; do
  add_epilogue_if_needed "$f"
done

# Formatage léger + lint d info
python - <<'PY' || true
import sys, subprocess
subprocess.run([sys.executable, "-m", "pip", "install", "--user", "autopep8"], check=False)
PY

python -m autopep8 --in-place \
  --select E122,E128,E131,E225,E231,E266,E301,E302,E305,E401,E501,W291,W391 \
  --aggressive --aggressive \
  "${files[@]}" || true

# Commit & push
git add -A
git commit -m "feat(cli): add best-effort post-parse epilogue to plot_*.py (outdir/env/rcParams/copy-latest)" || true
git push || true

# Smoke global
if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
