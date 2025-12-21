#!/usr/bin/env bash
# mcgt_step1_cleanup_probe.sh — Lecture seule, inventaires de nettoyage.
# Garde-fou anti-fermeture + logs. AUCUNE suppression.
set -u  # pas de -e pour éviter de quitter à la première erreur
IFS=$'\n\t'

REPO_ROOT="$(pwd)"
LOG_DIR="_tmp"
mkdir -p "$LOG_DIR"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${LOG_DIR}/cleanup_probe_${RUN_ID}.log"
SUMMARY_MD="TODO_CLEANUP.md"

# Garde-fou : piège les erreurs, ne ferme pas le terminal, et logue tout.
trap 'echo "[WARN] Une commande a échoué (code=$?) — voir ${LOG_FILE}" | tee -a "$LOG_FILE"' ERR

echo "# MCGT — Inventaire de nettoyage (lecture seule)"            | tee    "$SUMMARY_MD"
echo "*Run:* ${RUN_ID}"                                            | tee -a "$SUMMARY_MD"
echo "*Racine détectée:* ${REPO_ROOT}"                             | tee -a "$SUMMARY_MD"
echo                                                             | tee -a "$SUMMARY_MD"

{
  echo "== Environnement =="
  command -v git  && git rev-parse --short HEAD || true
  command -v python3 && python3 --version || true
  echo

  echo "== Dossiers pivots présents =="
  ls -1d */ 2>/dev/null | sed 's:/$::' | sort || true
  echo

  echo "== Inventaires lecture-seule =="

  mkdir -p "${LOG_DIR}/inventaires"

  echo "-- Logs & traces candidates --"
  find . -type f \( -name "*.log" -o -name "*.err" -o -name "*.out" -o -name "*.trace" -o -name "nohup.out" -o -name ".diag_last_failed.json" -o -name ".last_run_id" \) \
    -not -path "./.git/*" | sort | tee "${LOG_DIR}/inventaires/logs_${RUN_ID}.txt"

  echo "-- Caches & artefacts de build --"
  find . -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ipynb_checkpoints" -o -name "build" -o -name "dist" -o -name "*.egg-info" -o -name ".benchmarks" \) \
    -not -path "./.git/*" | sort | tee "${LOG_DIR}/inventaires/caches_${RUN_ID}.txt"

  echo "-- Fichiers temporaires / sauvegardes --"
  find . -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*~" -o -name "*.swp" -o -name "*.swo" -o -name ".DS_Store" \) \
    -not -path "./.git/*" | sort | tee "${LOG_DIR}/inventaires/tmp_bak_${RUN_ID}.txt"

  echo "-- Dossiers internes potentiellement non obligatoires --"
  find . -maxdepth 2 -type d \( -name "_tmp" -o -name ".ci-out" -o -name ".ruff_cache" \) \
    -not -path "./.git/*" | sort | tee "${LOG_DIR}/inventaires/dossiers_non_obligatoires_${RUN_ID}.txt"

  echo "-- Gros fichiers (>= 30 MiB) --"
  # Limite à 30 MiB pour repérer les blobs à confirmer
  find . -type f -not -path "./.git/*" -size +30M -exec ls -lh {} \; | awk '{print $5, $9}' | sort -h \
    | tee "${LOG_DIR}/inventaires/gros_fichiers_${RUN_ID}.txt"

  echo "-- Archives/artefacts suspects (à confirmer) --"
  find . -type f \( -name "*.tar.gz" -o -name "*.zip" -o -name "*.7z" \) -not -path "./.git/*" \
    | sort | tee "${LOG_DIR}/inventaires/archives_${RUN_ID}.txt"

  echo "-- Actionlint / bundles spécifiques (signalements connus) --"
  find . -type f -name "actionlint.tar.gz" -not -path "./.git/*" | sort \
    | tee "${LOG_DIR}/inventaires/actionlint_${RUN_ID}.txt"

  echo "-- Figures dérivées multiples (png/pdf/svg concurrents) --"
  find . -type f \( -name "*.png" -o -name "*.pdf" -o -name "*.svg" \) -not -path "./.git/*" \
    | sed -E 's/\.(png|pdf|svg)$//' | sort | uniq -d \
    | tee "${LOG_DIR}/inventaires/figures_multi_format_${RUN_ID}.txt"

  echo "-- Manifests et fichiers d'autorité présents --"
  ls -1 assets/zz-manifests/manifest_*.json 2>/dev/null || true
  [ -f CITATION.cff ] && echo "CITATION.cff"
  [ -f .zenodo.json ] && echo ".zenodo.json"
  [ -f LICENSE ] && echo "LICENSE"
  [ -f README.md ] && echo "README.md"
} 2>&1 | tee -a "$LOG_FILE"

# Résumé quantifié dans TODO_CLEANUP.md
count_file () { [ -f "$1" ] && wc -l < "$1" || echo 0; }
LOGS_N=$(count_file "${LOG_DIR}/inventaires/logs_${RUN_ID}.txt")
CACHES_N=$(count_file "${LOG_DIR}/inventaires/caches_${RUN_ID}.txt")
TMPBAK_N=$(count_file "${LOG_DIR}/inventaires/tmp_bak_${RUN_ID}.txt")
NONOBL_N=$(count_file "${LOG_DIR}/inventaires/dossiers_non_obligatoires_${RUN_ID}.txt")
BIGF_N=$(count_file "${LOG_DIR}/inventaires/gros_fichiers_${RUN_ID}.txt")
ARCH_N=$(count_file "${LOG_DIR}/inventaires/archives_${RUN_ID}.txt")
MULTI_N=$(count_file "${LOG_DIR}/inventaires/figures_multi_format_${RUN_ID}.txt")

{
  echo "## Résumé quantifié"
  echo "- Logs & traces candidates : ${LOGS_N}"
  echo "- Caches & artefacts build : ${CACHES_N}"
  echo "- Temp/Sauvegardes         : ${TMPBAK_N}"
  echo "- Dossiers non obligatoires : ${NONOBL_N}"
  echo "- Gros fichiers (≥30 MiB)   : ${BIGF_N}"
  echo "- Archives/Bundles suspects : ${ARCH_N}"
  echo "- Figures multi-format      : ${MULTI_N}"
  echo
  echo "## Propositions (à valider, **aucune suppression automatique**)"
  echo "1) Construire une **IGNORE LIST** des familles ci-dessus (après revue)."
  echo "2) Consolider une **ADD LIST** pour tout fichier d’autorité (manifests, LICENSE, CITATION, README-REPRO)."
  echo "3) Définir la règle **REVIEW = INVENTAIRE – IGNORE + ADD** (priorité **ADD** > **IGNORE**)."
  echo "4) Spécifier repo-wide les **valeurs par défaut CLI** (--format, --dpi, --outdir, --transparent, --style, --verbose)."
  echo
  echo "## Pistes d'attentions"
  echo "- Vérifier les *gros fichiers* : si données sources/publication, documenter; sinon planifier purge ou externalisation."
  echo "- Vérifier *figures multi-format* : choisir le set canonique (e.g., PNG+SVG) et ignorer le reste."
} >> "$SUMMARY_MD"

# Pause de fin (anti-fermeture si lancé par double-clic)
if [ -t 1 ]; then
  echo
  read -rp "Inventaire terminé. Appuyez sur Entrée pour quitter..."
fi

exit 0
