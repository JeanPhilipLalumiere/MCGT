#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
cd "$ROOT"
mkdir -p zz-out
OUT="zz-out/diag_info.txt"

# Double sortie: écran + fichier
exec > >(tee "$OUT") 2>&1

echo "===== MCGT DIAG BEGIN ====="
date -u +"UTC %Y-%m-%d %H:%M:%S"
echo "Repo root: $ROOT"
echo

# 1) Arborescence (dossiers pivots, profondeur 2)
echo "### 1) Hiérarchie (pivots) ###"
pivots=( "." "zz-scripts" "zz-data" "zz-figures" "zz-out" "zz-baselines" "tools" ".github" "policies" "schemas" )
for d in "${pivots[@]}"; do
  [ -d "$d" ] || continue
  echo "--- $d ---"
  if command -v tree >/dev/null 2>&1; then
    tree -a -L 2 "$d" | sed 's/^/  /'
  else
    find "$d" -maxdepth 2 -type d | sort | sed 's/^/  /'
  fi
  echo
done

# 2) Scripts prioritaires (8) : contenu brut
echo "### 2) Scripts prioritaires (contenu brut) ###"
scripts=(
  "zz-scripts/chapter06/plot_fig01_cmb_dataflow_diagram.py"
  "zz-scripts/chapter06/plot_fig05_delta_chi2_heatmap.py"
  "zz-scripts/chapter08/plot_fig03_mu_vs_z.py"
  "zz-scripts/chapter08/plot_fig04_chi2_heatmap.py"
  "zz-scripts/chapter09/generate_mcgt_raw_phase.py"
  "zz-scripts/chapter09/plot_fig01_phase_overlay.py"
  "zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py"
  "zz-scripts/chapter10/recompute_p95_circular.py"
)
for f in "${scripts[@]}"; do
  echo "----- $f -----"
  if [ -f "$f" ]; then
    # Copier-coller brut (entier)
    sed -n '1,99999p' "$f"
  else
    echo "[ABSENT] $f"
  fi
  echo
done

# 3) Configs & données : extraits JSON/CSV cités (entêtes + quelques lignes)
echo "### 3) Extraits JSON/CSV ###"
json_guess=(
  "zz-data/chapter08/08_coupling_params.json"
  "zz-data/chapter06/06_cmb_params.json"
  "zz-data/shared/json_params.json"
)
csv_guess=(
  "zz-data/chapter04/04_dimensionless_invariants.csv"
  "zz-data/chapter08/08_mu_theory_z.csv"
)

echo "-- JSON connus (si présents) --"
for j in "${json_guess[@]}"; do
  if [ -f "$j" ]; then
    echo ">>> $j"
    python3 - <<PY
import json,sys,io
p="$j"
with open(p,'r',encoding='utf-8',errors='replace') as f:
    try:
        obj=json.load(f)
    except Exception as e:
        print("(!) JSON invalide:",e)
        sys.exit(0)
def preview(o,depth=0,max_items=10):
    if isinstance(o,dict):
        keys=list(o.keys())[:max_items]
        print("{"," ,".join(keys),"}")
        for k in keys:
            v=o[k]
            t=type(v).__name__
            if isinstance(v,(dict,list)):
                print(f"  [{k}] -> {t} (aperçu)")
            else:
                print(f"  [{k}] -> {t} =",repr(v)[:200])
    elif isinstance(o,list):
        print(f"list(len={len(o)}) aperçus={min(len(o),max_items)}")
        for i,x in enumerate(o[:max_items]):
            print(f"  [{i}] type={type(x).__name__}")
    else:
        print(type(o).__name__,o)
preview(obj)
PY
    echo
  fi
done

echo "-- JSON auto-détectés (référencés par scripts) --"
# cherche dans les scripts les chemins *.json, samples réduits
grep -R --no-color -Eo 'zz-data[^" ]+\.json' zz-scripts 2>/dev/null | sort -u | while read -r pj; do
  [ -f "$pj" ] || continue
  echo ">>> $pj"
  python3 - <<PY
import json,sys
p=sys.argv[1]
try:
  obj=json.load(open(p,'r',encoding='utf-8',errors='replace'))
  if isinstance(obj,dict): print("keys:",list(obj.keys())[:12])
  elif isinstance(obj,list): print("list_len:",len(obj),"first_item_type:",type(obj[0]).__name__ if obj else None)
except Exception as e:
  print("(!) JSON invalide:",e)
PY
"$pj"
done
echo

echo "-- CSV connus (si présents) --"
for c in "${csv_guess[@]}"; do
  if [ -f "$c" ]; then
    echo ">>> $c"
    # entête + 5 lignes
    head -n 6 "$c"
    echo
  fi
done

echo "-- CSV auto-détectés (référencés par scripts) --"
grep -R --no-color -Eo 'zz-data[^" ]+\.csv' zz-scripts 2>/dev/null | sort -u | while read -r pc; do
  [ -f "$pc" ] || continue
  echo ">>> $pc"
  head -n 6 "$pc" || true
  echo
done

# 4) Locks : existent-ils ?
echo "### 4) Lockfiles présents ###"
find zz-data -type f -name '*.lock.json' 2>/dev/null | sort || true
echo

# 5) CI/Make
echo "### 5) Makefile & CI ###"
if [ -f Makefile ]; then
  echo "----- Makefile (entête 200 lignes) -----"
  sed -n '1,200p' Makefile
else
  echo "[ABSENT] Makefile"
fi
echo
if [ -d .github/workflows ]; then
  echo "-- Workflows (.github/workflows) --"
  ls -1 .github/workflows
  echo
  for y in .github/workflows/*; do
    [ -f "$y" ] || continue
    echo "----- $y (entête 80 lignes) -----"
    sed -n '1,80p' "$y"
    echo
    echo "    [résumé: nom & jobs]"
    # name:
    grep -E '^[[:space:]]*name:' "$y" || true
    # ids de jobs (heuristique grep)
    awk '/^jobs:/{p=1;next} p && /^[[:space:]]*[a-zA-Z0-9_-]+:/{print "job:", $1}' "$y" || true
    echo
  done
else
  echo "[ABSENT] .github/workflows/"
fi
echo

# 6) Policies / Schemas déjà en repo ?
echo "### 6) Policies / Schemas présents ###"
for d in policies schemas; do
  if [ -d "$d" ]; then
    echo "--- $d ---"
    find "$d" -maxdepth 2 -type f | sort
    echo
  else
    echo "[$d ABSENT]"
  fi
done

# 7) Baselines pHash
echo "### 7) Baselines pHash ###"
if [ -d zz-baselines ]; then
  echo "zz-baselines/ existe"
  find zz-baselines -maxdepth 2 -type f | wc -l | awk '{print "  fichiers:",$1}'
else
  echo "[ABSENT] zz-baselines/"
fi
echo

# 8) ENV & BLAS : stack numérique
echo "### 8) ENV & BLAS ###"
python3 - <<'PY'
import sys,platform,importlib,io,contextlib
print("Python:", sys.version.replace("\n"," "))
print("Platform:", platform.platform())
mods = ['numpy','scipy','matplotlib','pandas','h5py']
for m in mods:
    try:
        mod=importlib.import_module(m); ver=getattr(mod,'__version__','n/a')
        print(f"{m}: {ver}")
    except Exception as e:
        print(f"{m}: MISSING ({e})")
try:
    import numpy as np
    buf=io.StringIO()
    with contextlib.redirect_stdout(buf):
        np.__config__.show()
    print("\nNumPy __config__:\n" + buf.getvalue())
except Exception as e:
    print("NumPy __config__ unavailable:",e)
PY
echo

# 9) Protection git (optionnel via gh)
echo "### 9) Protection Git (main) ###"
if command -v gh >/dev/null 2>&1; then
  set +e
  url="$(git config --get remote.origin.url 2>/dev/null)"
  echo "remote.origin.url=$url"
  if echo "$url" | grep -qi 'github.com'; then
    owner_repo="$(echo "$url" | sed -E 's#.*github\.com[:/](.+/.+?)(\.git)?$#\1#')"
    echo "repo=$owner_repo"
    gh api "repos/$owner_repo/branches/main/protection" --jq '.required_status_checks.contexts,.enforce_admins,.restrictions' 2>/dev/null || echo "[non accessible]"
  else
    echo "[Non-GitHub ou URL non reconnue]"
  fi
  set -e
else
  echo "[gh non installé] — ignorer si non GitHub"
fi
echo

# 10) Datasets locaux (détection heuristique)
echo "### 10) Datasets locaux (présence) ###"
patterns=('gwtc' 'pantheon' 'planck' 'bao')
for pat in "${patterns[@]}"; do
  echo "pattern: $pat"
  find zz-data -iname "*$pat*" -maxdepth 4 -type f -o -type d 2>/dev/null | sed 's/^/  /' || true
done
echo

# 11) Espace disque
echo "### 11) Espace disque ###"
df -h .
[ -d zz-figures ] && du -sh zz-figures || true
[ -d zz-out ] && du -sh zz-out || true
echo

# 12) OS d'exécution
echo "### 12) OS d'exécution ###"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "OS: $PRETTY_NAME"
fi
uname -a
echo

echo "===== MCGT DIAG END ====="
