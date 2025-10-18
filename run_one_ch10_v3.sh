#!/usr/bin/env bash
set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _; fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

SCRIPT="${1:-}"; RESULTS="${2:-}"; shift 2 || true
[[ -r "$SCRIPT" ]] || { echo "[ERR] Script introuvable: $SCRIPT"; exit 2; }
[[ -r "$RESULTS" ]] || { echo "[ERR] CSV introuvable: $RESULTS"; exit 3; }

# Parser clé=valeur
declare -a EXTRA
OUT=""; DPI="300"; FMT="png"
for kv in "$@"; do
  k="${kv%%=*}"; v="${kv#*=}"
  case "$k" in
    x) EXTRA+=("--x-col" "$v");;
    y) EXTRA+=("--y-col" "$v");;
    sigma) EXTRA+=("--sigma-col" "$v");;
    group) EXTRA+=("--group-col" "$v");;
    p95) EXTRA+=("--p95-col" "$v");;
    n) EXTRA+=("--n-col" "$v");;
    orig) EXTRA+=("--orig-col" "$v");;
    recalc) EXTRA+=("--recalc-col" "$v");;
    m1) EXTRA+=("--m1-col" "$v");;
    m2) EXTRA+=("--m2-col" "$v");;
    out) OUT="$v";;
    dpi) DPI="$v";;
    fmt) FMT="$v";;
  esac
done

# OUT par défaut si manquant (tolère 03b)
if [[ -z "$OUT" ]]; then
  base="$(basename "$SCRIPT" .py)"
  chap="$(echo "$SCRIPT" | sed -n 's|.*chapter\([0-9][0-9]*\).*|\1|p')"
  fig="$(echo "$base"   | sed -n 's|plot_fig\([0-9][0-9]*[a-z]*\)_.*|\1|p')"
  name="$(echo "$base"  | sed -n 's|plot_fig[0-9][0-9]*[a-z]*_||p')"
  if [[ -n "$chap" && -n "$fig" && -n "$name" ]]; then
    printf -v OUT "zz-figures/chapter%02d/%02d_fig_%s.%s" "$chap" "$chap" "${fig}_$name" "$FMT"
  else
    OUT="zz-figures/chapter10/${base}.png"
  fi
fi
mkdir -p "$(dirname "$OUT")"

echo "[RUN] (orchestrator) $SCRIPT → $OUT"
set +e
python3 tools/plot_orchestrator.py "$SCRIPT" --dpi "$DPI" --results "$RESULTS" "${EXTRA[@]}" --out "$OUT"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "[WARN] orchestrator=$rc, fallback direct"
  python3 "$SCRIPT" --dpi "$DPI" --results "$RESULTS" "${EXTRA[@]}" --out "$OUT"
fi
