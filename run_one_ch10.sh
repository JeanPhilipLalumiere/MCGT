#!/usr/bin/env bash
# run_one_ch10.sh (v2) — lancer 1 script chap.10 avec mapping de colonnes et --out explicite
# Usage:
#   ./run_one_ch10.sh <script.py> <csv> [x=... y=... p95=... n=... orig=... recalc=... m1=... m2=...] [out=PATH] [dpi=300] [fmt=png]
#   ./run_one_ch10.sh                       # menu + auto-détection CSV ; propose un out par défaut

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

pick_script() {
  local arr=(
    "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
    "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
    "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"
    "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
    "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
    "zz-scripts/chapter10/plot_fig06_residual_map.py"
  )
  echo "Sélectionne un script:"
  local i=1; for s in "${arr[@]}"; do echo "  [$i] $s"; i=$((i+1)); done
  echo -n "Numéro (1-6) : "; read -r idx
  [[ "$idx" =~ ^[1-6]$ ]] || { echo "[ERR] choix invalide" >&2; exit 2; }
  echo "${arr[$((idx-1))]}"
}

# --- Script ---
SCRIPT="${1:-}"
if [[ -z "$SCRIPT" ]]; then
  SCRIPT="$(pick_script)"
else
  shift
fi
[[ -e "$SCRIPT" ]] || [[ -e "zz-scripts/chapter10/${SCRIPT##*/}" ]] && SCRIPT="${SCRIPT#./}"
[[ -e "$SCRIPT" ]] || SCRIPT="zz-scripts/chapter10/${SCRIPT##*/}"
[[ -r "$SCRIPT" ]] || { echo "[ERR] Script introuvable: $SCRIPT" >&2; exit 3; }

# --- CSV ---
RESULTS="${1:-}"; [[ -n "${RESULTS:-}" ]] && shift || true
if [[ -n "${RESULTS:-}" && ! -r "$RESULTS" ]]; then
  echo "[ERR] CSV fourni introuvable: $RESULTS" >&2; exit 4
fi
if [[ -z "${RESULTS:-}" ]]; then
  for c in \
    zz-data/chapter10/10_mc_results.circ.with_fpeak.csv \
    zz-data/chapter10/10_mc_results.circ.csv \
    zz-data/chapter10/10_mc_results.csv \
    zz-data/10_mc_results.circ.with_fpeak.csv \
    zz-data/10_mc_results.circ.csv \
    zz-data/10_mc_results.csv
  do [[ -r "$c" ]] && RESULTS="$c" && break; done
fi
[[ -n "${RESULTS:-}" ]] || { echo "[ERR] Aucun CSV chap.10 détecté." >&2; exit 5; }

# --- Liste des colonnes ---
echo "[INFO] CSV: $RESULTS"
python3 - "$RESULTS" <<'PY' || true
import sys, pandas as pd, re
p=sys.argv[1]; df=pd.read_csv(p, nrows=0); cols=list(map(str, df.columns))
print("[COLUMNS]", ", ".join(cols))
def f(r): return [c for c in cols if re.search(r, c, re.I)]
print("[HINT  fpeak]", ", ".join(f(r"\bf(_)?peak\b|\bfreq\b|f_max")))
print("[HINT   phi ]", ", ".join(f(r"\bphi\b|\bphi_")))
print("[HINT   p95 ]", ", ".join(f(r"p95|ci.?95|coverage")))
print("[HINT     n ]", ", ".join(f(r"(^n$|_n$|n_|\bnboot\b|\bn_boot\b|\bn_samples\b|\bsamples\b)")))
PY

# --- Construire les flags ---
declare -a EXTRA
DPI="300"; FMT="png"; OUT=""

# mapping clé=valeur
for kv in "$@"; do
  k="${kv%%=*}"; v="${kv#*=}"
  case "$k" in
    x)      EXTRA+=("--x-col" "$v") ;;
    y)      EXTRA+=("--y-col" "$v") ;;
    sigma)  EXTRA+=("--sigma-col" "$v") ;;
    group)  EXTRA+=("--group-col" "$v") ;;
    p95)    EXTRA+=("--p95-col" "$v") ;;
    n)      EXTRA+=("--n-col" "$v") ;;
    orig)   EXTRA+=("--orig-col" "$v") ;;
    recalc) EXTRA+=("--recalc-col" "$v") ;;
    m1)     EXTRA+=("--m1-col" "$v") ;;
    m2)     EXTRA+=("--m2-col" "$v") ;;
    out)    OUT="$v" ;;
    dpi)    DPI="$v" ;;
    fmt)    FMT="$v" ;;
    *) echo "[WARN] clé inconnue ignorée: $k";;
  esac
done

# OUT par défaut (si non fourni) — y compris cas 03b
if [[ -z "$OUT" ]]; then
  base="$(basename "$SCRIPT" .py)"                 # ex: plot_fig03b_bootstrap_coverage_vs_n
  chap="$(echo "$SCRIPT" | sed -n 's|.*chapter\([0-9][0-9]*\).*|\1|p')"
  fig="$(echo "$base"   | sed -n 's|plot_fig\([0-9][0-9]*[a-z]*\)_.*|\1|p')"
  name="$(echo "$base"  | sed -n 's|plot_fig[0-9][0-9]*[a-z]*_||p')"
  if [[ -n "$chap" && -n "$fig" && -n "$name" ]]; then
    printf -v OUT "zz-figures/chapter%02d/%02d_fig_%s.%s" "$chap" "$chap" "${fig}_$name" "$FMT"
    # ex: chapter10/10_fig_03b_bootstrap_coverage_vs_n.png
  else
    # fallback simple
    OUT="zz-figures/chapter10/${base}.png"
  fi
fi

mkdir -p "$(dirname "$OUT")"

echo "[RUN] $SCRIPT --results $RESULTS ${EXTRA[*]:-} --out $OUT (dpi=$DPI fmt=$FMT)"
python3 tools/plot_orchestrator.py "$SCRIPT" --dpi "$DPI" --results "$RESULTS" "${EXTRA[@]:-}" --out "$OUT"
