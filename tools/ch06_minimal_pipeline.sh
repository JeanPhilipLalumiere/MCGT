#!/usr/bin/env bash
# MCGT — CH06 minimal pipeline (Option B: éviter la régénération longue si les données existent déjà)
# -----------------------------------------------------------------------------
# Par défaut:
#   - Si tous les fichiers "data" attendus existent et ne sont pas vides => on SKIP generate_* (rapide)
#   - Sinon => on relance la génération complète (potentiellement ~3h)
#
# Variables d'environnement utiles:
#   SKIP_DATA=1   -> ne JAMAIS relancer la génération de données (même si des fichiers manquent)
#   FORCE_DATA=1  -> forcer la régénération complète des données (même si elles existent)
#   STRICT_DIAG=1 -> échouer si tools/run_diag_manifests.sh retourne non-zéro (par défaut: on tolère warnings)
# -----------------------------------------------------------------------------

set -Eeuo pipefail

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
run() { echo "+ $*"; "$@"; }

on_err() {
  local code=$?
  echo
  log "[ERREUR] Arrêt avec code $code"
  log "[ASTUCE] Rien n’a été supprimé. Vérifie les logs ci-dessus."
  exit "$code"
}
trap on_err ERR

# Se placer à la racine git si possible
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "== CH06 – PIPELINE MINIMAL : CMB =="

# --- Fichiers data attendus (utilisés ensuite par les scripts de figures) ---
required_files=(
  zz-configuration/pdot_plateau_z.dat
  zz-data/chapter06/06_alpha_evolution.csv
  zz-data/chapter06/06_cls_lcdm_spectrum.dat
  zz-data/chapter06/06_cls_spectrum.dat
  zz-data/chapter06/06_delta_cls.csv
  zz-data/chapter06/06_delta_cls_relative.csv
  zz-data/chapter06/06_params_cmb.json
  zz-data/chapter06/06_delta_rs_scan.csv
  zz-data/chapter06/06_delta_rs_scan_2d.csv
  zz-data/chapter06/06_cmb_chi2_scan_2d.csv
  zz-data/chapter06/06_delta_Tm_scan.csv
)

# --- 1/3 Data ---
log "[1/3] Génération des données..."

need_regen=0
for f in "${required_files[@]}"; do
  if [[ ! -s "$f" ]]; then
    need_regen=1
    break
  fi
done

if [[ "${FORCE_DATA:-0}" == "1" ]]; then
  need_regen=1
fi

if [[ "${SKIP_DATA:-0}" == "1" ]]; then
  log "[SKIP] SKIP_DATA=1 → aucune régénération de données."
elif [[ "$need_regen" == "1" ]]; then
  log "[RUN] Données manquantes ou FORCE_DATA=1 → régénération (peut être long)."

  log "[INFO] Script : zz-scripts/chapter06/generate_pdot_plateau_vs_z.py"
  run python zz-scripts/chapter06/generate_pdot_plateau_vs_z.py

  log "[INFO] Script : zz-scripts/chapter06/generate_data_chapter06.py"
  # IMPORTANT: ne pas passer d'arguments non supportés (sinon erreur argparse)
  run python zz-scripts/chapter06/generate_data_chapter06.py
else
  log "[SKIP] Données CH06 déjà présentes → pas de régénération."
fi

# Vérif présence data (non-fatale; on affiche juste l'état)
missing=0
log "[INFO] Vérification présence des fichiers data attendus…"
for f in "${required_files[@]}"; do
  if [[ -s "$f" ]]; then
    sz="$(stat -c%s "$f" 2>/dev/null || true)"
    if [[ -z "${sz:-}" ]]; then
      sz="$(wc -c < "$f" 2>/dev/null || true)"
    fi
    echo "[OK] $f (${sz:-?} bytes)"
  else
    echo "[MISSING/EMPTY] $f"
    missing=1
  fi
done

log "✅ Étape données CH06 terminée."

# --- 2/3 Figures ---
log "[2/3] Génération des figures..."

log "[INFO] Fig. 01 – schéma dataflow CMB"
run python zz-scripts/chapter06/plot_fig01_cmb_dataflow_diagram.py

log "[INFO] Fig. 02 – Cℓ ΛCDM vs MCGT"
run python zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py

log "[INFO] Fig. 03 – ΔCℓ relatif"
run python zz-scripts/chapter06/plot_fig03_delta_cls_relative.py

log "[INFO] Fig. 04 – Δr_s vs paramètres"
run python zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py

log "[INFO] Fig. 05 – Heatmap Δχ²"
run python zz-scripts/chapter06/plot_fig05_delta_chi2_heatmap.py

log "✅ Génération des figures CH06 terminée."

# --- 3/3 Diag manifests ---
log "[3/3] Vérification des manifests (publication + master)..."

diag_code=0
# Tolérer warnings: tools/run_diag_manifests.sh peut retourner 3 même si Errors: 0
# On capture le code sans déclencher le trap ERR.
trap - ERR
bash tools/run_diag_manifests.sh || diag_code=$?
trap on_err ERR

if [[ "$diag_code" -ne 0 ]]; then
  if [[ "${STRICT_DIAG:-0}" == "1" ]]; then
    log "[ERREUR] run_diag_manifests.sh a retourné $diag_code (STRICT_DIAG=1)."
    exit "$diag_code"
  else
    log "[WARN] run_diag_manifests.sh a retourné $diag_code (souvent = warnings). On continue (STRICT_DIAG=0)."
  fi
fi

if [[ "$missing" -ne 0 ]]; then
  log "[WARN] Certains fichiers data attendus manquent/vides."
  log "[ASTUCE] Pour régénérer complètement: FORCE_DATA=1 bash tools/ch06_minimal_pipeline.sh"
  log "[ASTUCE] Pour forcer le mode rapide malgré manquants: SKIP_DATA=1 bash tools/ch06_minimal_pipeline.sh"
fi

log "[OK] CH06 pipeline minimal terminé."
