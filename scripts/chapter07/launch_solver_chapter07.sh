#!/usr/bin/env bash
#------------------------------------------------------------------------------#
# launch_solver_chapter7.sh                                                    #
# Generation of raw data for Chapter 7 – Scalar perturbations                  #
#------------------------------------------------------------------------------#
# Usage :
#   ./launch_solver_chapter7.sh [--cs2_param X.Y] [--delta_phi_param A.B] [--ini FILE]
#
# This script :
#   1) Parses CLI args (--cs2_param, --delta_phi_param, --ini)
#   2) Checks existence of the .ini configuration file
#   3) Updates the INI with cs2_param and delta_phi_param
#   4) Runs the scalar perturbation solver (CAMB or CLASS)
#   5) Converts its DAT outputs into commented CSVs
#   6) Performs basic checks on generated files
#
# Author : MCGT Project
#------------------------------------------------------------------------------#

set -euo pipefail
IFS=$'\n\t'

#------------------------------------------------------------------------------#
# Utility functions                                                            #
#------------------------------------------------------------------------------#
print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --cs2_param VALUE       Factor for c_s^2 (default: 1.0)
  --delta_phi_param VALUE Factor for δφ/φ (default: 0.05)
  --ini FILE              Solver ini file (default: config/scalar_perturbations.ini)
  -h, --help              Show this help
EOF
  exit 1
}
error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

#------------------------------------------------------------------------------#
# Defaults                                                                     #
#------------------------------------------------------------------------------#
CS2_PARAM=1.0
DPHI_PARAM=0.05
INI_FILE=""
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONF_DIR="$ROOT_DIR/configuration"
DATA_DIR="$ROOT_DIR/assets/zz-data/chapter07"
OUTPUT_CS2="$DATA_DIR/output_solver_cs2.dat"
OUTPUT_PHI="$DATA_DIR/output_solver_phi.dat"

#------------------------------------------------------------------------------#
# Parse CLI                                                                    #
#------------------------------------------------------------------------------#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cs2_param)
      CS2_PARAM="$2"
      shift 2
      ;;
    --delta_phi_param)
      DPHI_PARAM="$2"
      shift 2
      ;;
    --ini)
      INI_FILE="$2"
      shift 2
      ;;
    -h | --help)
      print_usage
      ;;
    *)
      echo "[WARNING] Unrecognized option : $1"
      print_usage
      ;;
  esac
done

# Default INI path if not provided
: "${INI_FILE:=$CONF_DIR/scalar_perturbations.ini}"

#------------------------------------------------------------------------------#
# 0) Preparation                                                                #
#------------------------------------------------------------------------------#
echo "[INFO] Initialization…"
mkdir -p "$DATA_DIR"
[[ -f "$INI_FILE" ]] || error_exit "INI file not found : $INI_FILE"

#------------------------------------------------------------------------------#
# 1) Update INI                                                                 #
#------------------------------------------------------------------------------#
echo "[INFO] Updating INI with cs2_param=$CS2_PARAM, delta_phi_param=$DPHI_PARAM"
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
' "$INI_FILE" >"$TMP_INI"
mv "$TMP_INI" "$INI_FILE"

#------------------------------------------------------------------------------#
# 2) Run solver                                                                 #
#------------------------------------------------------------------------------#
echo "[INFO] Running scalar perturbation solver"
if command -v camb &>/dev/null; then
  camb "$INI_FILE" output_root="$DATA_DIR/solver_output" ||
    error_exit "CAMB failed"
  # expect CAMB to produce solver_output_cs2.dat and solver_output_phi.dat
  mv "$DATA_DIR/solver_output_cs2.dat" "$OUTPUT_CS2"
  mv "$DATA_DIR/solver_output_phi.dat" "$OUTPUT_PHI"
elif command -v class &>/dev/null; then
  class --input.ini="$INI_FILE" --output_dir="$DATA_DIR" ||
    error_exit "CLASS failed"
  # adapt these names if CLASS produces different filenames
  mv "$DATA_DIR/class_output_cs2.dat" "$OUTPUT_CS2"
  mv "$DATA_DIR/class_output_phi.dat" "$OUTPUT_PHI"
else
  error_exit "No solver (camb or class) found in PATH"
fi

# Check existence and non-emptiness
[[ -s "$OUTPUT_CS2" ]] || error_exit "CS2 file empty or missing: $OUTPUT_CS2"
[[ -s "$OUTPUT_PHI" ]] || error_exit "PHI file empty or missing: $OUTPUT_PHI"

#------------------------------------------------------------------------------#
# 3) Convert DAT -> commented CSVs                                             #
#------------------------------------------------------------------------------#
echo "[INFO] Converting DAT to commented CSV"
CS2_CSV="$DATA_DIR/07_cs2_scan.csv"
PHI_CSV="$DATA_DIR/07_delta_phi_scan.csv"

printf "# k [h/Mpc], a, cs2\n" >"$CS2_CSV"
awk -v factor="$CS2_PARAM" -F'[ \t]+' 'BEGIN{OFS=", "} {printf("%.6e, %.4f, %.6e\n",$1,$2,$3*factor)}' \
  "$OUTPUT_CS2" >>"$CS2_CSV"

printf "# k [h/Mpc], a, delta_phi_rel\n" >"$PHI_CSV"
awk -v factor="$DPHI_PARAM" -F'[ \t]+' 'BEGIN{OFS=", "} {printf("%.6e, %.4f, %.6e\n",$1,$2,$3*factor)}' \
  "$OUTPUT_PHI" >>"$PHI_CSV"

#------------------------------------------------------------------------------#
# 4) Basic checks                                                              #
#------------------------------------------------------------------------------#
echo "[INFO] Verifying generated CSVs"
for f in "$CS2_CSV" "$PHI_CSV"; do
  n=$(grep -c -v '^#' "$f")
  if ((n < 10)); then
    echo "[WARNING] Only $n data lines in $f"
  else
    echo "[OK] $f contains $n lines"
  fi
done

echo "[INFO] Raw data generation completed ✔"
exit 0
