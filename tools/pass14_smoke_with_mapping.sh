#!/usr/bin/env bash
# PASS14 — Smoke runner avec capture CSV/LOG et mapping d'arguments minimal
# - Évite "Is a directory" : si un ancien run a créé un dossier .out/.err, on écrit dans .out.txt/.err.txt
# - Ne crée que le dossier parent des fichiers OUT/ERR
# - Classe les statuts : OK / FAIL / NEEDS_INPUT / TIMEOUT
# - Produit : CSV (résumé par script) + LOG (chronologique)

set -uo pipefail

# ---------- Config via variables d'env (valeurs par défaut) ----------
PYTHON="${PYTHON:-python}"
OUTROOT="${OUTROOT:-zz-out/pass14_run}"
LOG_DIR="${LOG_DIR:-zz-out}"
SMOKE_CSV="${SMOKE_CSV:-$LOG_DIR/homog_smoke_pass14.csv}"
SMOKE_LOG="${SMOKE_LOG:-$LOG_DIR/homog_smoke_pass14.log}"
PER_SCRIPT_TIMEOUT="${PER_SCRIPT_TIMEOUT:-8s}"

# ---------- Utilitaires ----------
ts() { date "+%Y-%m-%dT%H:%M:%S%z"; }
log() { echo "[$(ts)] $*" | tee -a "$SMOKE_LOG" >/dev/null; }

now_ns() {
  if date +%s%N >/dev/null 2>&1; then
    date +%s%N
  else
    echo $(( $(date +%s) * 1000000000 ))
  fi
}

calc_elapsed() {
  awk -v s="$1" -v e="$2" 'BEGIN{printf "%.2f",(e-s)/1e9}'
}

parent_dir() {
  local p="$1"
  case "$p" in
    */*) printf "%s\n" "${p%/*}" ;;
    *)   printf ".\n" ;;
  esac
}

# Mapping d’arguments (ajoute des cas si tu veux pré-remplir certains scripts)
default_args_for() {
  case "$1" in
    # "zz-scripts/manifest_tools/verify_manifest.py") echo "--csv zz-out/manifest.csv --meta zz-out/manifest_meta.json";;
    # "zz-scripts/chapter09/apply_poly_unwrap_rebranch.py") echo "--csv data/p95.csv";;
    *) echo "";;
  esac
}

reason_from_stderr() {
  local err="$1"
  [[ -s "$err" ]] || { echo ""; return; }
  if grep -m1 -q "the following arguments are required" "$err"; then
    grep -m1 "the following arguments are required" "$err"; return
  fi
  if grep -m1 -q "^usage:" "$err"; then
    grep -m1 "^usage:" "$err"; return
  fi
  awk 'NF{last=$0} END{print last}' "$err"
}

ensure_dirs() {
  mkdir -p "$LOG_DIR" "$OUTROOT"
  : > "$SMOKE_LOG"
  echo "file,status,reason,elapsed_sec,out_path,out_size" > "$SMOKE_CSV"
}

list_scripts() {
  LC_ALL=C find zz-scripts -type f -name "*.py" | LC_ALL=C sort
}

# ---------- Exécution ----------
main() {
  ensure_dirs
  log "[PASS14] Smoke headless avec mapping d'arguments"

  local ok=0 fail=0 needs=0 timeout_n=0 skip_unknown=0 total=0

  local timeout_cmd=()
  if command -v timeout >/dev/null 2>&1; then
    timeout_cmd=(timeout --preserve-status "$PER_SCRIPT_TIMEOUT")
  fi

  while IFS= read -r script; do
    [[ -n "$script" ]] || continue
    total=$((total+1))

    local base name_no_ext out_path err_path
    base="$(basename "$script")"
    name_no_ext="${base%.py}"
    out_path="$OUTROOT/$(dirname "$script")/$name_no_ext.out"
    err_path="$OUTROOT/$(dirname "$script")/$name_no_ext.err"

    # Crée uniquement le dossier parent
    mkdir -p "$(parent_dir "$out_path")"

    # Si un ANCIEN run a créé un DOSSIER .out/.err, bascule vers .out.txt/.err.txt
    if [[ -d "$out_path" ]]; then out_path="${out_path}.txt"; fi
    if [[ -d "$err_path" ]]; then err_path="${err_path}.txt"; fi

    local extra_args
    extra_args="$(default_args_for "$script")"
    # split propre en tableau
    IFS=' ' read -r -a extra_arr <<< "$extra_args"

    log "RUN $script"
    local start_ns end_ns elapsed rc
    start_ns="$(now_ns)"

    if ((${#timeout_cmd[@]})); then
      "${timeout_cmd[@]}" "$PYTHON" "$script" "${extra_arr[@]}" >"$out_path" 2>"$err_path"
      rc=$?
    else
      "$PYTHON" "$script" "${extra_arr[@]}" >"$out_path" 2>"$err_path"
      rc=$?
    fi

    end_ns="$(now_ns)"
    elapsed="$(calc_elapsed "$start_ns" "$end_ns")"

    local status="OK" reason="" out_size=""
    if [[ -f "$out_path" ]]; then
      out_size="$(wc -c < "$out_path" | tr -d ' ')"
    else
      out_size=""
    fi

    if [[ "$rc" -eq 0 ]]; then
      status="OK"; reason=""; ok=$((ok+1))
      log "[OK] $script (${elapsed}s)"
    else
      if [[ "$rc" -eq 124 || "$rc" -eq 137 ]]; then
        status="TIMEOUT"; reason="Timeout after $PER_SCRIPT_TIMEOUT"; timeout_n=$((timeout_n+1))
        log "[TIMEOUT] $script (${elapsed}s)"
      else
        if [[ "$rc" -eq 2 ]] && grep -q -E "(^usage:|the following arguments are required)" "$err_path" 2>/dev/null; then
          status="NEEDS_INPUT"; reason="$(reason_from_stderr "$err_path")"; needs=$((needs+1))
          log "[NEEDS_INPUT] $script rc=$rc (${elapsed}s)"
        else
          status="FAIL"; reason="$(reason_from_stderr "$err_path")"; fail=$((fail+1))
          log "[FAIL] $script rc=$rc (${elapsed}s)"
        fi
      fi
    fi

    echo "${script},${status},${reason},${elapsed},${out_path},${out_size}" >> "$SMOKE_CSV"

  done < <(list_scripts)

  log "[PASS14] [SUMMARY] OK                 $ok"
  log "[PASS14] [SUMMARY] NEEDS_INPUT        $needs"
  log "[PASS14] [SUMMARY] SKIP_UNKNOWN_ARGS  $skip_unknown"
  log "[PASS14] [SUMMARY] TIMEOUT            $timeout_n"
  log "[PASS14] [SUMMARY] FAIL               $fail"
  log "[PASS14] Rapport:"
  log " - $SMOKE_CSV"
  log " - $SMOKE_LOG"
}

main "$@"
