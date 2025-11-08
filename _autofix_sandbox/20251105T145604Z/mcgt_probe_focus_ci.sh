#!/usr/bin/env bash
# mcgt_probe_focus_ci.sh — Sondes CI/Workflows/Pre-commit (lecture seule, avec pause)
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
OUTDIR="/tmp/mcgt_ci_probe_${TS}"
mkdir -p "$OUTDIR"

# 0) Contexte & Python
{
  echo ">>> 0) Environnement & Python"
  echo "which python: $(command -v python || true)"
  python -V 2>&1 || true
} | tee "$OUTDIR/00_env.txt"

# 1) Repo & branche
{
  echo ">>> 1) Repo & branche"
  cd "$HOME/MCGT" 2>/dev/null || true
  echo "pwd: $(pwd)"
  git rev-parse --show-toplevel 2>/dev/null || echo "(warn) pas un repo git ?"
  echo "Branche: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
} | tee "$OUTDIR/01_repo.txt"

# 2) Workflows: actifs vs .disabled, avec déclencheurs (grep fallback)
{
  echo ">>> 2) Workflows — inventaire"
  if [ -d .github/workflows ]; then
    echo "-- Actifs:"
    find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) ! -name "*.disabled" -print | sort
    echo
    echo "-- Neutralisés:"
    find .github/workflows -maxdepth 1 -type f -name "*.disabled" -print | sort

    echo
    echo ">>> 2a) Déclencheurs (grep fallback):"
    for f in $(find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) ! -name "*.disabled"); do
      echo "--- $f"
      grep -nE '^[[:space:]]*on:|workflow_dispatch|push:|pull_request:|schedule:|paths:|paths-ignore:' "$f" || true
    done
  else
    echo "(warn) .github/workflows absent"
  fi
} | tee "$OUTDIR/02_workflows_triggers.txt"

# 3) actionlint (forme sûre) + yamllint si dispo
{
  echo ">>> 3) Lint YAML workflows"
  if command -v actionlint >/dev/null 2>&1; then
    echo "-- actionlint (no color):"
    actionlint -color=never .github/workflows/*.y*ml 2>&1 || true
  else
    echo "(info) actionlint non trouvé"
  fi
  if command -v yamllint >/dev/null 2>&1; then
    echo
    echo "-- yamllint (parsable):"
    yamllint -f parsable .github/workflows 2>/dev/null || true
  else
    echo "(info) yamllint non trouvé"
  fi
} | tee "$OUTDIR/03_yaml_lint.txt"

# 4) gh CLI: liste workflows & runs sur la branche courante
{
  echo ">>> 4) gh workflows & runs"
  if command -v gh >/dev/null 2>&1; then
    echo "-- gh workflow list:"
    gh workflow list 2>&1 || true
    BR=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "$BR" ]; then
      echo
      echo "-- gh run list (branche: $BR):"
      gh run list --limit 30 --branch "$BR" 2>&1 || true
    fi
  else
    echo "(info) gh non trouvé"
  fi
} | tee "$OUTDIR/04_gh.txt"

# 5) Pré-commit: hook budgets + existence du script
{
  echo ">>> 5) pre-commit / assets-budgets"
  if [ -f .pre-commit-config.yaml ]; then
    echo "-- .pre-commit-config.yaml (hooks 'assets-budgets' & gitleaks):"
    awk '/repos:/,0{print}' .pre-commit-config.yaml | sed -n '1,160p'
    echo
    echo "-- Présence tools/scan_assets_budget.py :"
    if [ -e tools/scan_assets_budget.py ]; then
      echo "OK: tools/scan_assets_budget.py présent"
    else
      echo "NOK: tools/scan_assets_budget.py manquant"
      echo "Recherche de variantes proches:"
      grep -Rsn "scan_assets_budget" tools _attic_untracked 2>/dev/null || true
      find tools -maxdepth 2 -type f -name "*budget*.py" 2>/dev/null | sed 's/^/cand: /'
    fi
  else
    echo "(info) .pre-commit-config.yaml absent"
  fi
} | tee "$OUTDIR/05_precommit_budgets.txt"

# 6) Budgets CI: inspection de budgets.yml s’il est actif
{
  echo ">>> 6) budgets.yml — inspection rapide"
  if [ -f .github/workflows/budgets.yml ]; then
    echo "-- En-tête & jobs:"
    sed -n '1,80p' .github/workflows/budgets.yml
    echo
    echo "-- Déclencheurs (grep):"
    grep -nE '^[[:space:]]*on:|workflow_dispatch|push:|pull_request|schedule' .github/workflows/budgets.yml || true
  else
    echo "(info) budgets.yml absent"
  fi
} | tee "$OUTDIR/06_budgets_workflow.txt"

# 7) Paquets: zz_tools & mcgt (versions & points d’entrée)
{
  echo ">>> 7) Packaging"
  if [ -f pyproject.toml ]; then
    echo "-- project name/version:"
    grep -nE '^\s*name\s*=|^\s*version\s*=' pyproject.toml || true
  fi
  echo
  echo "-- __init__ versions:"
  grep -RsnE '__version__\s*=\s*' zz_tools mcgt 2>/dev/null || true
  echo
  echo "-- entry points (scripts) si présents:"
  awk '/^\[project.scripts\]/,/^\[/{print}' pyproject.toml 2>/dev/null || echo "(info) pas de [project.scripts]"
} | tee "$OUTDIR/07_packaging.txt"

# 8) Manifeste d’autorité (taille & compte)
{
  echo ">>> 8) Manifestes"
  for f in zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
    if [ -f "$f" ]; then
      echo "-- $f: $(wc -c < "$f") bytes"
      if command -v jq >/dev/null 2>&1; then
        echo "entries: $(jq -r '.entries | length' "$f" 2>/dev/null || echo '?')"
      fi
    fi
  done
} | tee "$OUTDIR/08_manifests.txt"

# 9) GROS blobs historiques (top 40)
{
  echo ">>> 9) Blobs historiques (>10MB approx — top 40)"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git rev-list --objects --all 2>/dev/null \
      | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null \
      | awk '$1=="blob"{print $3 "\t" $4}' \
      | sort -nr \
      | awk 'BEGIN{c=0} {mb=$1/1024/1024; printf "%.2f MB\t%s\n", mb, $2; if(++c>=40) exit}'
  else
    echo "(warn) pas un repo git"
  fi
} | tee "$OUTDIR/09_large_blobs.txt"

# 10) Résumé
{
  echo ">>> 10) Résumé"
  echo "OUTDIR: $OUTDIR"
  echo "Workflows actifs: $(find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) ! -name "*.disabled" 2>/dev/null | wc -l | awk '{print $1}')"
  echo "Workflows .disabled: $(find .github/workflows -maxdepth 1 -type f -name "*.disabled" 2>/dev/null | wc -l | awk '{print $1}')"
} | tee "$OUTDIR/10_summary.txt"
