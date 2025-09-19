#!/usr/bin/env bash
set -u
PY=${PY:-python3}
DIR_SCHEMAS=${DIR_SCHEMAS:-zz-schemas}
DIR_DATA_EN=${DIR_DATA_EN:-zz-data}

ok=0; bad=0; skip=0

run_pair() {
  local schema="$1"
  local inst="$2"
  if [[ ! -f "$schema" ]]; then
    echo "SKIP: missing schema  $schema"; ((skip++)); return
  fi
  if [[ ! -f "$inst" ]]; then
    echo "SKIP: missing sample  $inst";  ((skip++)); return
  fi
  echo "JSON: $inst  ↔  $schema"
  if "$PY" "$DIR_SCHEMAS/validate_json.py" "$schema" "$inst"; then
    ((ok++))
  else
    ((bad++))
  fi
}

echo "== JSON validation (safe SKIP) =="

# --- Chapter 10 (MC) ---
run_pair "$DIR_SCHEMAS/mc_config_schema.json"       "$DIR_DATA_EN/chapter10/10_mc_config.json"
run_pair "$DIR_SCHEMAS/mc_best_schema.json"         "$DIR_DATA_EN/chapter10/10_mc_best.json"

# --- Chapter 09 (GW phase) ---
run_pair "$DIR_SCHEMAS/metrics_phase_schema.json"          "$DIR_DATA_EN/chapter09/09_metrics_phase.json"
run_pair "$DIR_SCHEMAS/09_best_params.schema.json"         "$DIR_DATA_EN/chapter09/09_best_params.json"
run_pair "$DIR_SCHEMAS/09_phases_imrphenom.meta.schema.json" "$DIR_DATA_EN/chapter09/09_phases_imrphenom.meta.json"

# --- Chapter 08 (coupling) ---
run_pair "$DIR_SCHEMAS/08_coupling_params.schema.json"     "$DIR_DATA_EN/chapter08/08_coupling_params.json"

# --- Chapter 07 (scalar perturbations) ---
run_pair "$DIR_SCHEMAS/07_params_perturbations.schema.json" "$DIR_DATA_EN/chapter07/07_params_perturbations.json"
run_pair "$DIR_SCHEMAS/07_meta_perturbations.schema.json"   "$DIR_DATA_EN/chapter07/07_meta_perturbations.json"

# --- Chapter 06 (CMB) ---
run_pair "$DIR_SCHEMAS/06_cmb_params.schema.json"          "$DIR_DATA_EN/chapter06/06_params_cmb.json"

# --- Chapter 05 (BBN) ---
run_pair "$DIR_SCHEMAS/05_nucleosynthesis_parameters.schema.json" "$DIR_DATA_EN/chapter05/05_bbn_params.json"

# --- Chapter 03 (f(R) stability) ---
run_pair "$DIR_SCHEMAS/03_meta_stability_fR.schema.json"   "$DIR_DATA_EN/chapter03/03_meta_stability_fR.json"

# --- Chapter 02 (primordial spectrum) ---
run_pair "$DIR_SCHEMAS/02_spec_spectrum.schema.json"       "$DIR_DATA_EN/chapter02/02_primordial_spectrum_spec.json"
run_pair "$DIR_SCHEMAS/02_optimal_parameters.schema.json"  "$DIR_DATA_EN/chapter02/02_optimal_parameters.json"

echo "Summary: ok=$ok bad=$bad skip=$skip"
exit 0
