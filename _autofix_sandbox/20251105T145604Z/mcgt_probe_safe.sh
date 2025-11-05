#!/usr/bin/env bash
# mcgt_probe_safe.sh — Extraction d’informations MCGT (lecture seule)
# 20 sondes numérotées + garde-fou pour empêcher la fermeture de la fenêtre.

set -u
export LC_ALL=C

# ---------- Garde-fou : ne jamais fermer la fenêtre sans pause ----------
finish_trap() {
  echo
  echo "────────────────────────────────────────────────────────"
  echo "Rapports écrits dans: $OUTDIR"
  echo "Appuie sur ENTRÉE pour quitter."
  if [ -t 0 ]; then read -r _; else sleep 5; fi
}
trap finish_trap EXIT

# ---------- Préambule & environnement ----------
TS="$(date +%Y%m%dT%H%M%S)"
OUTDIR="/tmp/mcgt_probe_${TS}"
mkdir -p "$OUTDIR"

# 0) Activation conda (best effort) + Python
{
  echo ">>> 0) Environnement & Python"
  if command -v conda >/dev/null 2>&1; then
    # Ne PAS 'set -e' ici pour éviter l'arrêt si l'env n’existe pas.
    conda activate mcgt-dev 2>/dev/null || echo "(info) conda activate mcgt-dev a échoué — on continue."
  else
    echo "(info) conda non trouvé"
  fi
  echo "which python: $(command -v python || true)"
  python -V 2>&1 || true
} | tee "$OUTDIR/00_env.txt"

# 1) Positionnement dans le repo (~/MCGT par défaut)
{
  echo ">>> 1) Positionnement dans le repo"
  cd "$HOME/MCGT" 2>/dev/null || echo "(warn) ~/MCGT introuvable — essaie de lancer le script depuis la racine du repo."
  echo "pwd: $(pwd)"
  git rev-parse --show-toplevel 2>/dev/null || echo "(warn) pas un repo git ?"
} | tee "$OUTDIR/01_repo_root.txt"

# 2) Arborescence minimale (top-level)
{
  echo ">>> 2) Arborescence top-level"
  printf "Contenu racine (dossiers et quelques fichiers clés):\n"
  find . -maxdepth 1 -mindepth 1 -printf "%y %p\n" | sort
  echo
  printf "Dossiers pivots présents:\n"
  for d in zz-data zz-figures zz-scripts tools scripts zz-manifests chapters chapter09 chapter10 .github/workflows zz-schemas zz_tools src; do
    [ -e "$d" ] && echo "OK  - $d" || echo "NOK - $d"
  done
} | tee "$OUTDIR/02_tree_min.txt"

# 3) Statut Git (sans modifier)
{
  echo ">>> 3) Git status / branches"
  git status -sb 2>&1 || true
  echo
  echo "Branches locales (top 20 par date):"
  git for-each-ref --count=20 --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads 2>/dev/null || true
  echo
  echo "Branche courante:"
  git rev-parse --abbrev-ref HEAD 2>/dev/null || true
} | tee "$OUTDIR/03_git_status.txt"

# 4) Historique récent
{
  echo ">>> 4) Derniers commits (20)"
  git log --oneline --decorate --graph -n 20 2>/dev/null || true
} | tee "$OUTDIR/04_git_log.txt"

# 5) Workflows actifs / neutralisés
{
  echo ">>> 5) Workflows .github/workflows"
  if [ -d .github/workflows ]; then
    echo "-- Tous les fichiers:"
    ls -la .github/workflows || true
    echo
    echo "-- Actifs (.yml/.yaml sans .disabled):"
    find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) ! -name "*.disabled" -print | sort
    echo
    echo "-- Neutralisés (*.disabled):"
    find .github/workflows -maxdepth 1 -type f -name "*.disabled" -print | sort
  else
    echo "(warn) .github/workflows absent"
  fi
} | tee "$OUTDIR/05_workflows_list.txt"

# 6) Lint YAML (actionlint/yamllint si dispos)
{
  echo ">>> 6) Lint workflows (best effort)"
  if command -v actionlint >/dev/null 2>&1; then
    echo "-- actionlint:"
    actionlint -color never .github/workflows/*.y*ml 2>&1 || true
  else
    echo "(info) actionlint non trouvé"
  fi
  if command -v yamllint >/dev/null 2>&1; then
    echo
    echo "-- yamllint (workflows + configs/ si présent):"
    yamllint -f parsable .github/workflows 2>/dev/null || true
    [ -d configs ] && yamllint -f parsable configs 2>/dev/null || true
  else
    echo "(info) yamllint non trouvé"
  fi
} | tee "$OUTDIR/06_yaml_lint.txt"

# 7) gh CLI: workflows & runs (si disponible)
{
  echo ">>> 7) gh workflows & runs (facultatif)"
  if command -v gh >/dev/null 2>&1; then
    echo "-- gh workflow list:"
    gh workflow list 2>&1 || true
    CURBR=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "$CURBR" ]; then
      echo
      echo "-- gh run list (branche: $CURBR):"
      gh run list --limit 20 --branch "$CURBR" 2>&1 || true
    fi
  else
    echo "(info) gh non trouvé"
  fi
} | tee "$OUTDIR/07_gh_runs.txt"

# 8) Pré-commit: config & hooks
{
  echo ">>> 8) pre-commit configuration"
  if [ -f .pre-commit-config.yaml ]; then
    echo "-- .pre-commit-config.yaml (entête + hooks):"
    sed -n '1,120p' .pre-commit-config.yaml
    echo
    echo "-- Hooks installés (si pre-commit dispo):"
    if command -v pre-commit >/dev/null 2>&1; then
      pre-commit validate-config 2>&1 || true
      pre-commit list-hooks --all 2>/dev/null || true
    else
      echo "(info) pre-commit non installé"
    fi
    echo
    echo "-- Recherche 'assets-budgets' et script associé:"
    grep -n "assets-budgets" .pre-commit-config.yaml || true
    [ -e tools/scan_assets_budget.py ] && echo "OK: tools/scan_assets_budget.py présent" || echo "NOK: tools/scan_assets_budget.py manquant"
  else
    echo "(info) .pre-commit-config.yaml absent"
  fi
} | tee "$OUTDIR/08_precommit.txt"

# 9) pyproject.toml — sections clés
{
  echo ">>> 9) pyproject.toml — metadata clés"
  if [ -f pyproject.toml ]; then
    echo "[project] (extrait):"
    awk '/^\[project\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml
    echo
    echo "[build-system] (extrait):"
    awk '/^\[build-system\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml
    echo
    echo "[tool] (extrait: black, ruff, setuptools, etc.):"
    awk '/^\[tool\./,0{print}' pyproject.toml | sed -n '1,200p'
  else
    echo "(info) pyproject.toml absent"
  fi
} | tee "$OUTDIR/09_pyproject.txt"

# 10) Paquets Python détectés (zz_tools, src/, etc.)
{
  echo ">>> 10) Paquets Python détectés"
  for p in zz_tools src mcgt mcgt_core; do
    if [ -d "$p" ]; then
      echo "-- $p/ trouvé"
      find "$p" -maxdepth 2 -type f -name "__init__.py" -print
      grep -RsnE "__version__|version" "$p" 2>/dev/null | head -n 20 || true
    fi
  done
} | tee "$OUTDIR/10_packages.txt"

# 11) Manifeste(s) d’autorité & vérification JSON
{
  echo ">>> 11) Manifeste(s) d’autorité"
  for f in zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
    if [ -f "$f" ]; then
      echo "-- $f (taille: $(wc -c < "$f") bytes)"
      if command -v jq >/dev/null 2>&1; then
        echo "Clés top-level:"
        jq -r 'keys[]' "$f" 2>/dev/null | head -n 50 || true
        echo "Nombre d’entrées (si .entries existe):"
        jq -r '.entries | length' "$f" 2>/dev/null || echo "(info) .entries non trouvé"
      else
        echo "(info) jq non installé — pas d’inspection JSON avancée"
      fi
    else
      echo "NOK: $f absent"
    fi
  done
} | tee "$OUTDIR/11_manifests.txt"

# 12) Licences & CITATION & README
{
  echo ">>> 12) Licences & CITATION & README"
  for f in LICENSE LICENSE.txt LICENSE.md CITATION.cff README.md README-REPRO*; do
    [ -e "$f" ] && echo "OK  - $f" || echo "NOK - $f"
  done
  if [ -f CITATION.cff ]; then
    echo
    echo "-- CITATION.cff (entête):"
    sed -n '1,60p' CITATION.cff
  fi
} | tee "$OUTDIR/12_licenses_citation.txt"

# 13) Chapters & conventions de nommage
{
  echo ">>> 13) Chapters & conventions"
  echo "-- Dossiers chapter*/chapters/*/chapitre* :"
  find . -maxdepth 2 -type d \( -name "chapter*" -o -name "chapters" -o -name "chapitre*" \) -print | sort
  echo
  echo "-- Scripts par chapitre (zz-scripts/chapterNN/*.py) :"
  find zz-scripts -maxdepth 2 -type f -path "zz-scripts/chapter*/" -name "*.py" -printf "%p\n" 2>/dev/null | sort | head -n 200
} | tee "$OUTDIR/13_chapters_layout.txt"

# 14) Focal ch09/ch10 : scripts & temps estimés (nommage)
{
  echo ">>> 14) ch09/ch10 — scripts candidats au smoke"
  for n in 09 10; do
    d="zz-scripts/chapter${n}"
    if [ -d "$d" ]; then
      echo "-- $d:"
      ls -1 "$d"/*.py 2>/dev/null || echo "(info) aucun .py dans $d"
      echo
    fi
  done
} | tee "$OUTDIR/14_ch09_ch10.txt"

# 15) Inventaire figures & data (compte & tailles)
{
  echo ">>> 15) Inventaire figures & data (compte/tailles)"
  for d in zz-figures zz-data; do
    if [ -d "$d" ]; then
      echo "-- $d:"
      find "$d" -type f -printf "%s %p\n" 2>/dev/null | awk '{s+=$1} END{printf("Fichiers: %d, Taille totale: %.2f MB\n", NR, s/1024/1024)}'
      echo "Top 20 plus gros fichiers:"
      find "$d" -type f -printf "%s\t%p\n" | sort -nr | head -n 20
      echo
    fi
  done
} | tee "$OUTDIR/15_fig_data_sizes.txt"

# 16) Gros fichiers non versionnés / ignorés ?
{
  echo ">>> 16) Gros fichiers (>10MB) dans le working tree"
  find . -type f -size +10M -not -path "./.git/*" -printf "%s\t%p\n" 2>/dev/null | sort -nr | head -n 50
} | tee "$OUTDIR/16_large_worktree.txt"

# 17) Gros blobs dans l’historique Git (approx)
{
  echo ">>> 17) Gros blobs historiques (>10MB) — approximation"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git rev-list --objects --all 2>/dev/null \
      | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null \
      | awk '$1=="blob"{print $3 "\t" $4}' \
      | sort -nr \
      | awk 'BEGIN{c=0} {mb=$1/1024/1024; printf "%.2f MB\t%s\n", mb, $2; if(++c>=50) exit}' \
      || true
  else
    echo "(warn) pas un repo git"
  fi
} | tee "$OUTDIR/17_large_blobs_history.txt"

# 18) Dépendances: runtime vs dev (grep)
{
  echo ">>> 18) Dépendances: runtime/dev (grep indicatif)"
  if [ -f pyproject.toml ]; then
    echo "-- [project] dependencies:"
    awk '/^\[project\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml | grep -E "dependencies|requires" -n -A2 -B0 || true
    echo
    echo "-- [project.optional-dependencies] (si présents):"
    awk '/^\[project.optional-dependencies\]/, /^\[/{print} /^\[tool\]/{exit}' pyproject.toml || true
  fi
  for f in requirements.txt requirements-dev.txt requirements-*.txt; do
    [ -f "$f" ] && { echo "-- $f:"; sed -n '1,80p' "$f"; echo; }
  done
} | tee "$OUTDIR/18_deps_scan.txt"

# 19) Style & outils (ruff/black/mypy)
{
  echo ">>> 19) Outils de style/qualité"
  if [ -f pyproject.toml ]; then
    echo "-- [tool.black], [tool.ruff], [tool.mypy] extraits:"
    awk '/^\[tool\.black\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml
    awk '/^\[tool\.ruff\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml
    awk '/^\[tool\.mypy\]/,/^\[/{print} /^\[tool\]/{exit}' pyproject.toml
  fi
} | tee "$OUTDIR/19_style_tools.txt"

# 20) Sanity check publication (build-only en lecture)
{
  echo ">>> 20) Sanity build-only (dry-run) — inspection non intrusive"
  if command -v python >/dev/null 2>&1; then
    if python -c "import build" 2>/dev/null; then
      echo "(info) Module 'build' présent — listing théorique uniquement."
    else
      echo "(info) Module 'build' absent — skip."
    fi
    # On n’exécute PAS de build ici pour rester lecture seule vis-à-vis du repo.
    # On liste ce qu’on verrait typiquement dans une build:
    [ -f pyproject.toml ] && grep -E "name\s*=|version\s*=" -n pyproject.toml || true
    [ -d zz_tools ] && find zz_tools -maxdepth 2 -type f -name "*.py" | head -n 50
  else
    echo "(warn) python introuvable"
  fi
} | tee "$OUTDIR/20_build_sanity.txt"

# Résumé final
{
  echo ">>> Résumé rapide"
  echo "OUTDIR          : $OUTDIR"
  echo "Branche courante: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo "Workflows actifs: $(find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) ! -name "*.disabled" 2>/dev/null | wc -l | awk '{print $1}')"
  echo "Workflows .disabled: $(find .github/workflows -maxdepth 1 -type f -name "*.disabled" 2>/dev/null | wc -l | awk '{print $1}')"
  echo "Fichiers zz-figures: $( [ -d zz-figures ] && find zz-figures -type f 2>/dev/null | wc -l || echo 0 )"
  echo "Fichiers zz-data   : $( [ -d zz-data ] && find zz-data -type f 2>/dev/null | wc -l || echo 0 )"
} | tee "$OUTDIR/ZZ_summary.txt"
