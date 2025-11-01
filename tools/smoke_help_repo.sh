#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="_tmp/smoke_help_${TS}"
mkdir -p "$OUTDIR"
REPORT="$OUTDIR/report.tsv"
LOG="$OUTDIR/run.log"
: >"$REPORT"; : >"$LOG"

say(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

mapfile -t FILES < <(git ls-files 'zz-scripts/chapter??/plot_*.py' | sort)

ok=0; fail=0
set +e  # on n'abat pas la session si un --help échoue
for f in "${FILES[@]}"; do
  say "TEST --help: $f"
  python "$f" --help >/dev/null 2>>"$LOG"
  if [[ $? -eq 0 ]]; then
    printf "OK\t%s\n" "$f" >>"$REPORT"; ((ok++))
  else
    printf "FAIL\t%s\n" "$f" >>"$REPORT"; ((fail++))
  fi
done
set -e

printf "TOTAL\t%d\nOK\t%d\nFAIL\t%d\n" "${#FILES[@]}" "$ok" "$fail" | tee -a "$LOG"
echo "Rapport TSV : $REPORT"
echo "Log complet : $LOG"
# --- enforce non-zero exit on FAIL lines in TSV (idempotent) ---
REPORT_TSV="${REPORT_TSV:-$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1)}"
if [[ -z "${REPORT_TSV}" || ! -f "${REPORT_TSV}" ]]; then
  echo "[ERR] REPORT_TSV introuvable — lance d’abord le test pour générer un TSV"; exit 2;
fi
if grep -q '^FAIL\t' "$REPORT_TSV"; then
  echo "[ERR] FAIL détectés dans $REPORT_TSV"
  exit 1
fi
# --- enforce non-zero exit on FAIL lines in TSV (idempotent) ---
if grep -q '^FAIL\t' "$REPORT_TSV"; then
  echo "[ERR] FAIL détectés dans $REPORT_TSV"
  exit 1
fi

# == Résumé & sortie stricte ==
FAILS="$(grep -c '^FAIL\t' "${REPORT_TSV}" || true)"
OKS="$(grep -c '^OK\t'   "${REPORT_TSV}" || true)"
echo "OK=${OKS}  FAIL=${FAILS}"
if [[ "${FAILS}" -ne 0 ]]; then
  echo "[FAIL] --help: ${FAILS} échec(s) détecté(s)"; exit 1;
fi
