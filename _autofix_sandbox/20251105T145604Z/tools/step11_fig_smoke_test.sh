#!/usr/bin/env bash
set -euo pipefail

# ---------- PSX robuste (script enfant) ----------
: "${WAIT_ON_EXIT:=1}"
_end_pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ CLI smoke test — exit $rc"
  else
    echo "❌ CLI smoke test — exit $rc"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    if [ -r /dev/tty ]; then
      printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
      IFS= read -r _ < /dev/tty
      printf "\n" > /dev/tty
    elif [ -t 0 ]; then
      read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
      echo
    else
      echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
trap '_end_pause' EXIT
# -------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
OUTDIR_BASE="${OUTDIR_BASE:-.ci-out}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${OUTDIR:-$OUTDIR_BASE/fig-smoke-$TS}"
mkdir -p "$OUTDIR"
export MCGT_OUTDIR="$OUTDIR"

# Liste par défaut (scripts patchés v3), surcharge possible via SCRIPTS_FILE
DEFAULT_SCRIPTS=(
  "zz-scripts/chapter01/plot_fig01_early_plateau.py"
  "zz-scripts/chapter02/plot_fig00_spectrum.py"
  "zz-scripts/chapter07/plot_fig01_cs2_heatmap.py"
  "zz-scripts/chapter08/plot_fig03_mu_vs_z.py"
  "zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py"
)

if [[ -n "${SCRIPTS_FILE:-}" && -f "${SCRIPTS_FILE:-}" ]]; then
  mapfile -t SCRIPTS < "${SCRIPTS_FILE}"
else
  SCRIPTS=("${DEFAULT_SCRIPTS[@]}")
fi

# Timeout (si disponible)
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout 180s"
fi

# Helpers
_count_files() {
  find "$OUTDIR" -type f | wc -l | tr -d ' '
}

BEFORE=$(_count_files)
TOTAL=0
OK=0
FAIL=0

# Rapport JSON
REPORT="$(mktemp)"
echo '{"runs":[' > "$REPORT"
SEP=""

for s in "${SCRIPTS[@]}"; do
  ((TOTAL++)) || true
  START=$(_count_files)
  echo "==> Run: $s"
  # Tous les scripts n'acceptent pas -v; on essaie sans forcer, et tolère les erreurs
  set +e
  ${TIMEOUT_BIN:-} python -u "$s" --format=png --dpi=120 --transparent --outdir="$OUTDIR"
  rc=$?
  set -e
  AFTER=$(_count_files)
  NEW=$((AFTER - START))
  if [[ $rc -eq 0 && $NEW -ge 1 ]]; then
    echo "OK: $s (${NEW} fichier(s) généré(s))"
    ((OK++)) || true
    result="ok"
  else
    echo "WARN/FAIL: $s (rc=$rc, nouveaux fichiers: $NEW)"
    ((FAIL++)) || true
    result="fail"
  fi
  # Append JSON entry
  echo -n ${SEP}'{"script":' >> "$REPORT"
  printf '%s' "$(printf '%s' "$s" | python -c 'import json,sys;print(json.dumps(sys.stdin.read()))')" >> "$REPORT"
  echo -n ',"rc":'"$rc"',"new_files":'"$NEW"',"result":"'${result}'"}' >> "$REPORT"
  SEP=","
done

FINAL=$(_count_files)
echo '],"summary":{"total":'"$TOTAL"',"ok":'"$OK"',"fail":'"$FAIL"',"outdir":"'$(printf '%s' "$OUTDIR")'","files_start":'"$BEFORE"',"files_end":'"$FINAL"'}}' >> "$REPORT"

mkdir -p .ci-out
cp "$REPORT" .ci-out/fig_smoke_report.json
echo
echo "Rapport JSON: .ci-out/fig_smoke_report.json"
echo "Résumé: total=$TOTAL ok=$OK fail=$FAIL outdir=$OUTDIR (fichiers: $BEFORE → $FINAL)"
