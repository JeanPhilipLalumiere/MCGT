#!/usr/bin/env bash
set -Eeuo pipefail

# STEP101 – Scan structure Chapitre 05 (scripts, data, figures)
# Usage:
#   bash step101_scan_ch05_structure.sh /chemin/vers/MCGT
#   ou depuis la racine du dépôt:
#   bash step101_scan_ch05_structure.sh

ROOT="${1:-$PWD}"

cd "$ROOT"

if [ ! -f "pyproject.toml" ] || [ ! -d "scripts" ]; then
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

  echo "## 1) Scripts Python dans scripts/chapter05/"
  if [ -d "scripts/chapter05" ]; then
    find "scripts/chapter05" -maxdepth 1 -type f -name "*.py" | sort
  else
    echo "[WARN] Répertoire scripts/chapter05 inexistant"
  fi
  echo

  echo "## 2) Outils/smoke liés à CH05 dans tools/"
  if [ -d "tools" ]; then
    ls tools | grep -Ei 'ch05|chapter05|bbn' || echo "(aucun fichier correspondant trouvé)"
  else
    echo "[WARN] Répertoire tools inexistant"
  fi
  echo

  echo "## 3) Données dans assets/zz-data/chapter05/"
  if [ -d "assets/zz-data/chapter05" ]; then
    ls -1 "assets/zz-data/chapter05"
  else
    echo "(assets/zz-data/chapter05 absent)"
  fi
  echo

  echo "## 4) Figures dans assets/zz-figures/chapter05/"
  if [ -d "assets/zz-figures/chapter05" ]; then
    ls -1 "assets/zz-figures/chapter05"
  else
    echo "(assets/zz-figures/chapter05 absent)"
  fi
  echo

  echo "## 5) Configs associées (grep chapter05/BBN dans config/)"
  if [ -d "configuration" ]; then
    grep -nEi 'chapter05|ch05|bbn' config/* || echo "(aucune occurrence trouvée)"
  else
    echo "(configuration absent)"
  fi
  echo

  echo "## 6) Occurrences chapter05 dans manifest_master.json"
  if [ -f "assets/zz-manifests/manifest_master.json" ]; then
    grep -n '"chapter05"' assets/zz-manifests/manifest_master.json || echo "(aucune occurrence 'chapter05')"
  else
    echo "(assets/zz-manifests/manifest_master.json absent)"
  fi
  echo

} | tee "$LOGFILE"
