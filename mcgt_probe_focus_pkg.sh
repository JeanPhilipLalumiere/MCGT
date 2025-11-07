#!/usr/bin/env bash
# mcgt_probe_focus_pkg.sh — Packaging, données, chapitres, CLI, tests (lecture seule)
set -u
export LC_ALL=C

pause_guard() {
  echo
  echo "────────────────────────────────────────────────────────"
  echo "Rapports écrits dans: $OUTDIR"
  echo "Appuie sur ENTRÉE pour quitter."
  if [ -t 0 ]; then read -r _; else sleep 5; fi
}
trap pause_guard EXIT

TS="$(date +%Y%m%dT%H%M%S)"
OUTDIR="/tmp/mcgt_pkg_probe_${TS}"
mkdir -p "$OUTDIR"

cd "${MCGT_ROOT:-$HOME/MCGT}" 2>/dev/null || cd . || true
ROOT="$(pwd)"

# 0) Environnement Python & chemins
{
  echo ">>> 0) Environnement Python"
  echo "pwd: $ROOT"
  echo "which python: $(command -v python || true)"
  python -V 2>&1 || true
  echo
  echo "PYTHONPATH: ${PYTHONPATH:-<unset>}"
  echo "VIRTUAL_ENV: ${VIRTUAL_ENV:-<unset>}"
} | tee "$OUTDIR/00_env.txt"

# 1) Arborescence minimale (dossiers pivots) + comptes
{
  echo ">>> 1) Arborescence (niveaux: racine -> pivots)"
  for d in \
    zz-data zz-figures zz-scripts zz-manifests zz-schemas \
    tools scripts tests zz-tests mcgt zz_tools .github/workflows \
    01-introduction-applications 02-validation-chronologique \
    09-phase-ondes-gravitationnelles 10-monte-carlo-global-8d \
    zz-config zz-configuration zz-out _attic_untracked attic _tmp _logs \
    ; do
    [ -d "$d" ] && echo "OK  - $d" || echo "NOK - $d"
  done

  echo
  echo ">>> 1a) Top-level (dossiers) :"
  find . -maxdepth 1 -type d -printf "d %p\n" | sort | sed 's#^\./##' | sed '1,120p'
  echo
  echo ">>> 1b) Comptes rapides:"
  [ -d zz-scripts ] && printf "scripts (*.py sous zz-scripts): %s\n" "$(find zz-scripts -type f -name '*.py' | wc -l)"
  [ -d zz-figures ] && printf "figures (zz-figures/*): %s ; taille: %s\n" \
      "$(find zz-figures -type f | wc -l)" "$(du -sh zz-figures 2>/dev/null | awk '{print $1}')"
  [ -d zz-data ] && printf "données (zz-data/*): %s ; taille: %s\n" \
      "$(find zz-data -type f | wc -l)" "$(du -sh zz-data 2>/dev/null | awk '{print $1}')"
} | tee "$OUTDIR/01_tree_counts.txt"

# 2) Packaging: pyproject.toml / setup.* / modules importables / entry points
{
  echo ">>> 2) Packaging — pyproject / setup"
  [ -f pyproject.toml ] && sed -n '1,240p' pyproject.toml | sed -n '1,120p'
  echo
  echo "-- project name/version/requires-python:"
  [ -f pyproject.toml ] && grep -nE '^\s*name\s*=|^\s*version\s*=|^\s*requires-python\s*=' pyproject.toml || true
  echo
  echo "-- [project.scripts] (s'il existe):"
  [ -f pyproject.toml ] && awk '/^\[project\.scripts\]/,/^\[/{print}' pyproject.toml || echo "(info) pas de [project.scripts]"
  echo
  echo "-- setup.cfg présent ? $( [ -f setup.cfg ] && echo yes || echo no )"
  echo "-- setup.py présent ? $( [ -f setup.py ] && echo yes || echo no )"
  [ -f setup.cfg ] && sed -n '1,120p' setup.cfg
} | tee "$OUTDIR/02_packaging.txt"

{
  echo ">>> 2b) Modules Python détectés (racine)"
  for pkg in mcgt zz_tools; do
    if [ -d "$pkg" ]; then
      echo "-- $pkg/:"
      find "$pkg" -maxdepth 2 -type f -name '__init__.py' -print
      grep -RsnE '__version__\s*=\s*' "$pkg" 2>/dev/null || true
      echo
    fi
  done
} | tee "$OUTDIR/02b_modules.txt"

# 3) Dépendances: requirements* + détection divergences pin (runtime vs dev)
{
  echo ">>> 3) Dépendances — fichiers connus"
  for f in requirements.txt requirements-dev.txt requirements-prepub.txt requirements-lock.txt requirements-dev.lock.txt; do
    if [ -f "$f" ]; then
      echo "-- $f (entête 60 lignes):"
      sed -n '1,60p' "$f"
      echo
    fi
  done

  echo ">>> 3a) Résumé des pins (top 40 uniques)"
  grep -hRsnE '^[a-zA-Z0-9_.-]+(\[.*\])?([<>=!~]=| @ |==)' requirements*.txt 2>/dev/null \
    | sed 's/ \+#.*$//' | sed 's/#.*$//' \
    | awk -F: '{print $NF}' | sed 's/^[ \t]*//' | sed '/^$/d' \
    | sort -f | uniq | sed -n '1,40p'
} | tee "$OUTDIR/03_dependencies.txt"

# 4) Manifeste(s) d’autorité (compte & tailles)
{
  echo ">>> 4) Manifestes d'autorité"
  for f in zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
    if [ -f "$f" ]; then
      echo "-- $f: $(wc -c < "$f") bytes"
      if command -v jq >/dev/null 2>&1; then
        echo "   entries: $(jq -r '.entries | length' "$f" 2>/dev/null || echo '?')"
        echo "   total_size_bytes: $(jq -r '.total_size_bytes' "$f" 2>/dev/null || echo '?')"
      fi
    fi
  done
} | tee "$OUTDIR/04_manifests.txt"

# 5) Chapitres: inventaire scripts & patterns de nommage fig
{
  echo ">>> 5) Chapitres — scripts et patrons de figures"
  if [ -d zz-scripts ]; then
    for nn in $(seq -w 01 10); do
      d="zz-scripts/chapter${nn}"
      [ -d "$d" ] || continue
      echo "-- $d :"
      find "$d" -maxdepth 1 -type f -name '*.py' -printf "%f\n" | sort | sed -n '1,200p'
    done
  fi

  echo
  echo ">>> 5a) Figures existantes (zz-figures) — échantillon & motifs"
  if [ -d zz-figures ]; then
    find zz-figures -maxdepth 2 -type f -printf "%P\n" | sort | sed -n '1,80p'
    echo
    echo "-- Motifs courants:"
    find zz-figures -type f -printf "%f\n" \
      | sed 's/[0-9]\{2\}/NN/g; s/[0-9]\{2\}/XX/g' \
      | sed 's/[0-9]\+/N+/g' \
      | sed 's/[._-]\+/_/g' \
      | awk '{cnt[$0]++} END{for(k in cnt) printf "%5d %s\n", cnt[k], k}' \
      | sort -nr | sed -n '1,20p'
  fi
} | tee "$OUTDIR/05_chapters_figs.txt"

# 6) CLI: inventaire des options fréquentes dans les scripts de figures
{
  echo ">>> 6) CLI — options fréquentes (--format/--dpi/--outdir/--transparent/--style/--verbose)"
  if [ -d zz-scripts ]; then
    grep -RsnE -- '--format|--dpi|--outdir|--transparent|--style|--verbose' zz-scripts 2>/dev/null \
      | sed -n '1,200p'
  else
    echo "(info) zz-scripts absent"
  fi

  echo
  echo ">>> 6a) Fonctions argparse (add_argument) — échantillon:"
  if [ -d zz-scripts ]; then
    grep -RsnE 'add_argument\(' zz-scripts 2>/dev/null | sed -n '1,200p'
  fi
} | tee "$OUTDIR/06_cli_options.txt"

# 7) Données: tailles & top fichiers, gz présents, “micro-corpus” indicatif
{
  echo ">>> 7) Données — tailles & top fichiers"
  if [ -d zz-data ]; then
    du -sh zz-data 2>/dev/null || true
    echo
    echo "-- Top 30 plus gros fichiers (taille octets + chemin relatif):"
    find zz-data -type f -printf "%s %P\n" | sort -nr | sed -n '1,30p'
    echo
    echo "-- Présence de .gz (pour micro-corpus):"
    find zz-data -type f -name '*.gz' -printf "%P\n" | sort | sed -n '1,60p'
  else
    echo "(info) zz-data absent"
  fi
} | tee "$OUTDIR/07_data_sizes.txt"

# 8) Tests: pytest, config, couverture indicative
{
  echo ">>> 8) Tests — présence & configs"
  [ -d tests ] && echo "OK tests/" || echo "NOK tests/"
  [ -d zz-tests ] && echo "OK zz-tests/" || echo "NOK zz-tests/"
  ls -1 pyproject-local-pytest.toml 2>/dev/null || true
  grep -RsnE 'pytest|pytest-cov|addopts|filterwarnings' . 2>/dev/null | sed -n '1,120p'
  echo
  echo "-- Fichiers test_* sous zz-scripts/chapter09 & chapter10 (échantillon):"
  find zz-scripts -path '*/chapter0[9-9]*' -type f -name 'test_*.py' -printf "%P\n" 2>/dev/null | sed -n '1,60p'
} | tee "$OUTDIR/08_tests.txt"

# 9) Reproductibilité images (heuristique: recherche SSIM / tolérances)
{
  echo ">>> 9) Reproductibilité — recherche SSIM/tolérances"
  grep -RsnE 'SSIM|structural similarity|tolerance|rtol|atol|dpi' zz-scripts zz-tests tests 2>/dev/null | sed -n '1,120p' || true
} | tee "$OUTDIR/09_repro_heuristics.txt"

# 10) Sanity import (sans exécuter pipelines) + versions internes
{
  echo ">>> 10) Sanity import (zz_tools, mcgt)"
  python - <<'PY' 2>&1 || true
try:
    import zz_tools as z
    v = getattr(z, "__version__", "<no __version__>")
    print(f"zz_tools imported OK — __version__={v}")
except Exception as e:
    print("zz_tools import FAILED:", e)

try:
    import mcgt as m
    v = getattr(m, "__version__", "<no __version__>")
    print(f"mcgt imported OK — __version__={v}")
except Exception as e:
    print("mcgt import FAILED:", e)
PY
} | tee "$OUTDIR/10_sanity_import.txt"

# 11) Gros blobs historiques (rappel court)
{
  echo ">>> 11) Gros blobs historiques (top 20, approx)"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git rev-list --objects --all 2>/dev/null \
      | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null \
      | awk '$1=="blob"{print $3 "\t" $4}' \
      | sort -nr \
      | awk 'BEGIN{c=0} {mb=$1/1024/1024; printf "%.2f MB\t%s\n", mb, $2; if(++c>=20) exit}'
  else
    echo "(warn) pas un repo git"
  fi
} | tee "$OUTDIR/11_large_blobs.txt"

# 12) Résumé final
{
  echo ">>> 12) Résumé"
  echo "OUTDIR: $OUTDIR"
  [ -d zz-scripts ] && echo "Total scripts: $(find zz-scripts -type f -name '*.py' | wc -l | awk '{print $1}')" || true
  [ -d zz-figures ] && echo "Total figures: $(find zz-figures -type f | wc -l | awk '{print $1}')" || true
  [ -d zz-data ] && echo "Total data files: $(find zz-data -type f | wc -l | awk '{print $1}')" || true
} | tee "$OUTDIR/12_summary.txt"
