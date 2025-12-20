#!/usr/bin/env bash
set -Eeuo pipefail

# STEP101 – Scan structure Chapitre 05 (scripts, data, figures)
# Usage:
#   bash step101_scan_ch05_structure.sh /chemin/vers/MCGT
#   ou depuis la racine du dépôt:
#   bash step101_scan_ch05_structure.sh

ROOT="${1:-$PWD}"

cd "$ROOT"

if [ ! -f "pyproject.toml" ] || [ ! -d "zz-scripts" ]; then
  echo "[ERROR] Ceci ne ressemble pas à la racine du dépôt MCGT: $ROOT" >&2
  exit 1
fi

LOGDIR="zz-logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/101_ch05_structure_scan.txt"

{
  echo "# STEP101 – Scan structure Chapitre 05 (scripts, data, figures)"
  echo "# Timestamp: $(date -u +%Y%m%dT%H%M%SZ)"
  echo "# Root: $ROOT"
  echo

  echo "## 1) Scripts Python dans zz-scripts/chapter05/"
  if [ -d "zz-scripts/chapter05" ]; then
    find "zz-scripts/chapter05" -maxdepth 1 -type f -name "*.py" | sort
  else
    echo "[WARN] Répertoire zz-scripts/chapter05 inexistant"
  fi
  echo

  echo "## 2) Outils/smoke liés à CH05 dans zz-tools/"
  if [ -d "zz-tools" ]; then
    ls zz-tools | grep -Ei 'ch05|chapter05|bbn' || echo "(aucun fichier correspondant trouvé)"
  else
    echo "[WARN] Répertoire zz-tools inexistant"
  fi
  echo

  echo "## 3) Données dans zz-data/chapter05/"
  if [ -d "zz-data/chapter05" ]; then
    ls -1 "zz-data/chapter05"
  else
    echo "(zz-data/chapter05 absent)"
  fi
  echo

  echo "## 4) Figures dans zz-figures/chapter05/"
  if [ -d "zz-figures/chapter05" ]; then
    ls -1 "zz-figures/chapter05"
  else
    echo "(zz-figures/chapter05 absent)"
  fi
  echo

  echo "## 5) Configs associées (grep chapter05/BBN dans zz-configuration/)"
  if [ -d "zz-configuration" ]; then
    grep -nEi 'chapter05|ch05|bbn' zz-configuration/* || echo "(aucune occurrence trouvée)"
  else
    echo "(zz-configuration absent)"
  fi
  echo

  echo "## 6) Occurrences chapter05 dans manifest_master.json"
  if [ -f "zz-manifests/manifest_master.json" ]; then
    grep -n '"chapter05"' zz-manifests/manifest_master.json || echo "(aucune occurrence 'chapter05')"
  else
    echo "(zz-manifests/manifest_master.json absent)"
  fi
  echo

} | tee "$LOGFILE"
