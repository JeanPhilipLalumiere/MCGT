#!/usr/bin/env bash
set -euo pipefail

echo "[RESUME-PASS5] Cleanup, inventaire, autofix, re-synthèse"

# 0) nettoyer processus résiduels (bash stoppés / jobs orphelins / anciens scans)
pkill -f plot_fig06_comparison.py    2>/dev/null || true
pkill -f homog_pass5_relocate_shim   2>/dev/null || true
pkill -f homog_pass4_cli_inventory   2>/dev/null || true
pkill -f homog_pass5_autofix         2>/dev/null || true

# 1) (sécurité) vérifier que le stub fig06 existe et est exécutable
python3 zz-scripts/chapter07/plot_fig06_comparison.py --help >/dev/null

# 2) ré-exécuter l’inventaire pass4 pour rafraîchir la fail list
tools/homog_pass4_cli_inventory.sh

echo
echo "=== Résumé inventaire (avant Pass5) ==="
tail -n +1 zz-out/homog_cli_inventory_pass4.txt | tail -n 20 || true
echo

# 3) relancer l’autofix sur la nouvelle fail list
tools/homog_pass5_autofix.sh || true

# 4) re-inventaire pour mesurer l’effet
tools/homog_pass4_cli_inventory.sh

echo
echo "=== Résumé inventaire (après Pass5) ==="
tail -n +1 zz-out/homog_cli_inventory_pass4.txt | tail -n 20 || true

echo
echo "[INFO] Rapports mis à jour :"
echo " - zz-out/homog_cli_inventory_pass4.txt"
echo " - zz-out/homog_cli_inventory_pass4.csv"
echo " - zz-out/homog_cli_fail_list.txt"
