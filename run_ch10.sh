#!/usr/bin/env bash
# === Chap.10 ciblé : relance avec --results et PAUSE/hold garantis ===

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    # Terminal interactif → bloquer pour lecture
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    # Pas de TTY (lancement via icône/GUI) → ouvrir un shell interactif
    echo "[HOLD] Session non-interactive détectée."
    echo "       Ouverture d'un shell interactif. Tapez 'exit' pour fermer."
    # shell de garde : pas de profils pour rester propre
    bash --noprofile --norc -i
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT

# (optionnel) activer l’environnement
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

# --- Sélection du --results ---
# Priorité décroissante ; tu peux aussi passer un chemin en $1 pour forcer.
CANDIDATES=(
  "zz-data/10_mc_results.circ.with_fpeak.csv"
  "zz-data/10_mc_results.circ.csv"
  "zz-data/10_mc_results.csv"
)

pick_results() {
  # Si l'utilisateur fournit un chemin explicite en $1
  if [ "${1-}" != "" ]; then
    if [ -r "$1" ]; then echo "$1"; return 0
    else
      echo "[ERR] Fichier fourni introuvable: $1" >&2
      return 1
    fi
  fi
  # Sinon on pioche dans la liste
  for f in "${CANDIDATES[@]}"; do
    if [ -r "$f" ]; then echo "$f"; return 0; fi
  done
  return 1
}

RES="$(pick_results "${1-}")" || {
  echo "[ERR] Aucun fichier '10_mc_results*.csv' lisible trouvé dans zz-data/."
  echo "      Place l’un des fichiers suivants (ou passe un chemin en argument) puis relance :"
  printf "      - %s\n" "${CANDIDATES[@]}"
  exit 2
}
echo "[INFO] Using --results = $RES"

# --- Scripts chap.10 typiquement dépendants de --results ---
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
  echo "[RUN] $s --results $RES" | tee -a "$LOG"
  if python3 tools/plot_orchestrator.py "$s" --dpi 300 -- --results "$RES" >>"$LOG" 2>&1; then
    echo "[OK ] $s" | tee -a "$LOG"; OK=$((OK+1))
  else
    ALT_OK=0
    for alt in "${CANDIDATES[@]}"; do
      [ "$alt" = "$RES" ] && continue
      [ ! -r "$alt" ] && continue
      echo "[RETRY] $s --results $alt" | tee -a "$LOG"
      if python3 tools/plot_orchestrator.py "$s" --dpi 300 -- --results "$alt" >>"$LOG" 2>&1; then
        echo "[OK*] $s (fallback $alt)" | tee -a "$LOG"; OK=$((OK+1)); ALT_OK=1; break
      fi
    done
    if [ $ALT_OK -eq 0 ]; then
      echo "[KO ] $s (voir $LOG)" | tee -a "$LOG"; KO=$((KO+1))
    fi
  fi
done

echo
echo "=== Résumé chap.10 ==="
echo "OK: $OK"
echo "KO: $KO"
echo "Log: $LOG"

# Rafraîchir manifestes pour enregistrer les figures produites
python3 tools/figure_manifest_builder.py | tee -a "$LOG"
