#!/usr/bin/env bash
# run_ch10_v3.sh — relance chap.10 avec détection intelligente du --results
# Garde-fous : la fenêtre NE SE FERME PAS (pause ou shell interactif en sortie)

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    echo "[HOLD] Pas de TTY : ouverture d'un shell interactif (tapez 'exit' pour fermer)."
    bash --noprofile --norc -i
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT

# (optionnel) activer l’environnement
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

# Dossiers à explorer pour trouver des résultats
SEARCH_DIRS=( "zz-data" "zz-data/chapter10" )

# Priorités de base (si on trouve exactement ces noms)
PRIO_BASENAMES=(
  "10_mc_results.circ.with_fpeak.csv"
  "10_mc_results.circ.csv"
  "10_mc_results.csv"
)

# Fallbacks globaux
GLOB_PATTERNS=(
  "10_mc_results*.csv"
  "*mc_results*.csv"
  "*results*.csv"
)

# Permet de forcer un fichier en $1
if [ "${1-}" != "" ]; then
  if [ -r "$1" ]; then
    RESULTS_PATH="$1"
  else
    echo "[ERR] Fichier fourni introuvable: $1"
    # On continue sans exit pour passer au scan intelligent
  fi
fi

pick_from_prio() {
  for d in "${SEARCH_DIRS[@]}"; do
    for b in "${PRIO_BASENAMES[@]}"; do
      local p="$d/$b"
      if [ -r "$p" ]; then echo "$p"; return 0; fi
    done
  done
  return 1
}

scan_candidates() {
  local found=()
  for d in "${SEARCH_DIRS[@]}"; do
    for pat in "${GLOB_PATTERNS[@]}"; do
      # nullglob local pour éviter l’écho du motif si rien ne matche
      shopt -s nullglob
      for f in "$d"/$pat; do
        [ -r "$f" ] && found+=( "$f" )
      done
      shopt -u nullglob
    done
  done
  # dédoublonnage simple
  if [ ${#found[@]} -gt 0 ]; then
    printf "%s\n" "${found[@]}" | awk '!seen[$0]++'
  fi
}

if [ -z "${RESULTS_PATH-}" ]; then
  # 1) essai sur les basenames prioritaires
  if RESULTS_PATH="$(pick_from_prio)"; then
    echo "[INFO] Using --results (prio) = $RESULTS_PATH"
  else
    # 2) scan large
    MAPFILE -t ALL <<<"$(scan_candidates || true)"
    if [ ${#ALL[@]} -eq 0 ]; then
      echo "[ERR] Aucun CSV de résultats trouvé dans: ${SEARCH_DIRS[*]}"
      echo "      Place un fichier puis relance, ou passe son chemin en argument."
      printf "      Exemples attendus :\n"
      for b in "${PRIO_BASENAMES[@]}"; do
        echo "      - zz-data/$b"
      done
      exit 2
    fi

    echo "[ASK] Aucun fichier prioritaire exact. Candidats détectés :"
    i=0
    for f in "${ALL[@]}"; do
      printf "  [%02d] %s\n" "$i" "$f"
      i=$((i+1))
    done

    if [ -t 0 ]; then
      read -r -p "Sélectionnez l’index du fichier à utiliser (ou 'q' pour quitter) : " idx
      if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 0 ] && [ "$idx" -lt ${#ALL[@]} ]; then
        RESULTS_PATH="${ALL[$idx]}"
        echo "[INFO] Using --results (choix) = $RESULTS_PATH"
        # Proposer un symlink canonique (facultatif mais pratique)
        read -r -p "Créer un alias canonique vers zz-data/10_mc_results.circ.with_fpeak.csv ? [o/N] " yn
        if [[ "$yn" =~ ^[oOyY]$ ]]; then
          mkdir -p zz-data
          ln -sfn "$RESULTS_PATH" "zz-data/10_mc_results.circ.with_fpeak.csv"
          echo "[LINK] zz-data/10_mc_results.circ.with_fpeak.csv -> $RESULTS_PATH"
        fi
      else
        echo "[ERR] Sélection invalide."
        exit 2
      fi
    else
      echo "[ERR] Lancement non-interactif et fichier prioritaire introuvable."
      echo "      Relance en fournissant un chemin explicite, par ex.:"
      echo "      ./run_ch10_v3.sh zz-data/chapter10/mon_fichier_results.csv"
      exit 2
    fi
  fi
fi

# --- Orchestration chap.10 ---
SCRIPTS=(
  "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
  "zz-scripts/chapter10/plot_fig06_residual_map.py"
)

mkdir -p zz-manifests
LOG=zz-manifests/last_orchestration_ch10.log
: > "$LOG"

OK=0; KO=0
for s in "${SCRIPTS[@]}"; do
  echo "[RUN] $s --results $RESULTS_PATH" | tee -a "$LOG"
  if python3 tools/plot_orchestrator.py "$s" --dpi 300 -- --results "$RESULTS_PATH" >>"$LOG" 2>&1; then
    echo "[OK ] $s" | tee -a "$LOG"; OK=$((OK+1))
  else
    echo "[KO ] $s (voir $LOG)" | tee -a "$LOG"; KO=$((KO+1))
  fi
done

echo
echo "=== Résumé chap.10 ==="
echo "OK : $OK"
echo "KO : $KO"
echo "Log: $LOG"

python3 tools/figure_manifest_builder.py | tee -a "$LOG"
