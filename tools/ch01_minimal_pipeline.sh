#!/usr/bin/env bash
# CH01 – Pipeline minimal canonique (Introduction & applications)
# ------------------------------------------------------------------
# Hypothèses :
# - Tu lances ce script depuis n'importe où, mais ton env Python MCGT
#   (ex. mcgt-dev) est déjà activé.
# - Le dépôt MCGT est propre (pas de fichiers en cours d'édition critique).

set -Eeuo pipefail

echo "[CH01] Pipeline minimal – Introduction & applications"
echo "[CH01] Détection de la racine du dépôt…"

# Localiser la racine du dépôt à partir du dossier tools/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

echo "[CH01] REPO_ROOT = ${REPO_ROOT}"
echo

# Petite fonction utilitaire pour exécuter les scripts Python si présents
run_python() {
  local script_path="$1"
  shift || true

  if [ -f "${script_path}" ]; then
    echo "[CH01] >> python ${script_path} $*"
    python "${script_path}" "$@"
    echo
  else
    echo "[CH01][WARN] Script absent, on saute : ${script_path}"
    echo
  fi
}

# ------------------------------------------------------------------
# 1) Génération des données CH01
# ------------------------------------------------------------------
echo "[CH01] Étape 1/4 – Génération des données"
run_python zz-scripts/chapter01/generate_data_chapter01.py

# ------------------------------------------------------------------
# 2) Figures principales CH01
# ------------------------------------------------------------------
echo "[CH01] Étape 2/4 – Figures principales"

run_python zz-scripts/chapter01/plot_fig01_early_plateau.py
run_python zz-scripts/chapter01/plot_fig02_logistic_calibration.py
run_python zz-scripts/chapter01/plot_fig03_relative_error_timeline.py
run_python zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py
run_python zz-scripts/chapter01/plot_fig05_I1_vs_T.py
run_python zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py

# ------------------------------------------------------------------
# 3) Compilation LaTeX CH01 (optionnelle mais recommandée)
# ------------------------------------------------------------------
echo "[CH01] Étape 3/4 – Compilation LaTeX (si les sources existent)"

LATEX_DIR="01-introduction-applications"
TEX_CONCEPTUEL="${LATEX_DIR}/01_introduction_conceptuel.tex"
TEX_APPLI="${LATEX_DIR}/01_applications_calibration_conceptuel.tex"

if [ -f "${TEX_CONCEPTUEL}" ]; then
  echo "[CH01] >> pdflatex (conceptuel)"
  pdflatex -interaction=nonstopmode "${TEX_CONCEPTUEL}" || echo "[CH01][WARN] pdflatex conceptuel a retourné un code non nul"
  echo
else
  echo "[CH01][WARN] Fichier LaTeX manquant : ${TEX_CONCEPTUEL}"
fi

if [ -f "${TEX_APPLI}" ]; then
  echo "[CH01] >> pdflatex (applications/calibration)"
  pdflatex -interaction=nonstopmode "${TEX_APPLI}" || echo "[CH01][WARN] pdflatex applications a retourné un code non nul"
  echo
else
  echo "[CH01][WARN] Fichier LaTeX manquant : ${TEX_APPLI}"
fi

# ------------------------------------------------------------------
# 4) Diagnostic manifests global (optionnel)
# ------------------------------------------------------------------
echo "[CH01] Étape 4/4 – Diagnostic des manifests (si disponible)"

if [ -x tools/run_diag_manifests.sh ]; then
  echo "[CH01] >> bash tools/run_diag_manifests.sh"
  bash tools/run_diag_manifests.sh || echo "[CH01][WARN] run_diag_manifests.sh a retourné un code non nul"
  echo
else
  echo "[CH01][WARN] Script tools/run_diag_manifests.sh introuvable ou non exécutable."
fi

echo "[CH01] Pipeline minimal CH01 terminé."
