#!/usr/bin/env bash
#------------------------------------------------------------------------------#
# lancer_solveur_chapitre7.sh                                                  #
# Génération des données brutes du Chapitre 7 – Perturbations scalaires         #
#------------------------------------------------------------------------------#
# Usage :
#   ./lancer_solveur_chapitre7.sh [--cs2_param X.Y] [--delta_phi_param A.B] [--ini FILE]
#
# Ce script :
#   1) Parse ses arguments CLI (--cs2_param, --delta_phi_param, --ini)
#   2) Vérifie l’existence du fichier .ini de configuration
#   3) Met à jour l’INI avec cs2_param et delta_phi_param
#   4) Exécute le solveur de perturbations scalaires (CAMB ou CLASS)
#   5) Convertit ses sorties DAT en CSV commentés
#   6) Vérifie sommairement la validité des fichiers générés
#
# Auteur : Projet MCGT
#------------------------------------------------------------------------------#

set -euo pipefail
IFS=$'\n\t'

#------------------------------------------------------------------------------#
# Fonctions utilitaires                                                        #
#------------------------------------------------------------------------------#
print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --cs2_param VALUE       Facteur pour c_s^2 (défaut: 1.0)
  --delta_phi_param VALUE Facteur pour δφ/φ (défaut: 0.05)
  --ini FILE              Fichier ini du solveur (défaut: zz-configuration/perturbations_scalaires.ini)
  -h, --help              Affiche cette aide
EOF
  exit 1
}
error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

#------------------------------------------------------------------------------#
# Valeurs par défaut                                                           #
#------------------------------------------------------------------------------#
CS2_PARAM=1.0
DPHI_PARAM=0.05
INI_FILE=""
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONF_DIR="$ROOT_DIR/zz-configuration"
DATA_DIR="$ROOT_DIR/zz-data/chapter7"
SOLVER_OUT_CS2="$DATA_DIR/solveur_output_cs2.dat"
SOLVER_OUT_PHI="$DATA_DIR/solveur_output_phi.dat"

#------------------------------------------------------------------------------#
# Parse CLI                                                                    #
#------------------------------------------------------------------------------#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cs2_param)
      CS2_PARAM="$2"; shift 2;;
    --delta_phi_param)
      DPHI_PARAM="$2"; shift 2;;
    --ini)
      INI_FILE="$2"; shift 2;;
    -h|--help)
      print_usage;;
    *)
      echo "[WARNING] Option non reconnue : $1"; print_usage;;
  esac
done

# Chemin par défaut de l’INI si non fourni
: "${INI_FILE:=$CONF_DIR/perturbations_scalaires.ini}"

#------------------------------------------------------------------------------#
# 0) Préparation                                                               #
#------------------------------------------------------------------------------#
echo "[INFO] Initialisation…"
mkdir -p "$DATA_DIR"
[[ -f "$INI_FILE" ]] || error_exit "Fichier ini introuvable : $INI_FILE"

#------------------------------------------------------------------------------#
# 1) Mise à jour de l’INI                                                      #
#------------------------------------------------------------------------------#
echo "[INFO] Mise à jour de l’INI avec cs2_param=$CS2_PARAM, delta_phi_param=$DPHI_PARAM"
TMP_INI="${INI_FILE}.tmp"
awk -v cs2="$CS2_PARAM" -v dp="$DPHI_PARAM" '
  BEGIN { found_cs2=0; found_dp=0 }
  /^cs2_param[[:space:]]*=/ { print "cs2_param = " cs2; found_cs2=1; next }
  /^delta_phi_param[[:space:]]*=/ { print "delta_phi_param = " dp; found_dp=1; next }
  { print }
  END {
    if (!found_cs2) print "cs2_param = " cs2
    if (!found_dp) print "delta_phi_param = " dp
  }
' "$INI_FILE" > "$TMP_INI"
mv "$TMP_INI" "$INI_FILE"

#------------------------------------------------------------------------------#
# 2) Exécution du solveur                                                      #
#------------------------------------------------------------------------------#
echo "[INFO] Exécution du solveur de perturbations scalaires"
if command -v camb &> /dev/null; then
  camb "$INI_FILE" output_root="$DATA_DIR/solveur_output" \
    || error_exit "Échec de CAMB"
  mv "$DATA_DIR/solveur_output_cs2.dat" "$SOLVER_OUT_CS2"
  mv "$DATA_DIR/solveur_output_phi.dat" "$SOLVER_OUT_PHI"
elif command -v class &> /dev/null; then
  class --input.ini="$INI_FILE" --output_dir="$DATA_DIR" \
    || error_exit "Échec de CLASS"
  # Adaptez ces noms si CLASS produit des fichiers différents
  mv "$DATA_DIR/class_output_cs2.dat" "$SOLVER_OUT_CS2"
  mv "$DATA_DIR/class_output_phi.dat" "$SOLVER_OUT_PHI"
else
  error_exit "Aucun solveur (camb ou class) trouvé dans le PATH"
fi

# Vérifier existence et non-vacuité
[[ -s "$SOLVER_OUT_CS2" ]] || error_exit "Fichier CS2 vide ou introuvable : $SOLVER_OUT_CS2"
[[ -s "$SOLVER_OUT_PHI" ]] || error_exit "Fichier PHI vide ou introuvable : $SOLVER_OUT_PHI"

#------------------------------------------------------------------------------#
# 3) Conversion en CSV commentés                                               #
#------------------------------------------------------------------------------#
echo "[INFO] Conversion des DAT en CSV commentés"
CS2_CSV="$DATA_DIR/07_cs2_scan.csv"
PHI_CSV="$DATA_DIR/07_delta_phi_phi_scan.csv"

printf "# k [h/Mpc], a, cs2\n" > "$CS2_CSV"
awk -v factor="$CS2_PARAM" -F'[ \t]+' 'BEGIN{OFS=", "} {printf("%.6e, %.4f, %.6e\n",$1,$2,$3*factor)}' \
  "$SOLVER_OUT_CS2" >> "$CS2_CSV"

printf "# k [h/Mpc], a, delta_phi_rel\n" > "$PHI_CSV"
awk -v factor="$DPHI_PARAM" -F'[ \t]+' 'BEGIN{OFS=", "} {printf("%.6e, %.4f, %.6e\n",$1,$2,$3*factor)}' \
  "$SOLVER_OUT_PHI" >> "$PHI_CSV"

#------------------------------------------------------------------------------#
# 4) Vérifications sommaires                                                   #
#------------------------------------------------------------------------------#
echo "[INFO] Vérifications sur les CSV générés"
for f in "$CS2_CSV" "$PHI_CSV"; do
  n=$(grep -v '^#' "$f" | wc -l)
  if (( n < 10 )); then
    echo "[WARNING] Seulement $n lignes de données dans $f"
  else
    echo "[OK] $f contient $n lignes"
  fi
done

echo "[INFO] Génération des données brutes terminée ✔"
exit 0
