#!/usr/bin/env bash
set -euo pipefail

echo "[PASS13-RUN] Re-scan smoke (--out) + analyse fraîche"

# 1) (Re)lancer le smoke runner
if [[ -x tools/pass13_smoke_out_all.sh ]]; then
  tools/pass13_smoke_out_all.sh
else
  echo "[ERR] tools/pass13_smoke_out_all.sh introuvable"; exit 1
fi

# 2) Analyse fraîche
if [[ -x tools/pass13_analyze.sh ]]; then
  tools/pass13_analyze.sh
else
  echo "[ERR] tools/pass13_analyze.sh introuvable"; exit 1
fi

# 3) Résumés utiles à l’écran
echo
echo "=== Résumé agrégé par chapitre (top 20) ==="
column -s, -t zz-out/pass13_summary_by_chapter.txt | head -n 20 || true

echo
echo "=== Top signatures FAIL_EXEC (top 20) ==="
head -n 40 zz-out/pass13_fail_exec_signatures.txt || true

echo
echo "=== Scripts demandant des arguments obligatoires (échantillon) ==="
sed -E 's/,.*$//' zz-out/pass13_required_args.txt | uniq | sed 's/^/ - /' | head -n 20 || true

echo
echo "=== Scripts avec options inconnues (--out/--dpi?) (échantillon) ==="
sed -E 's/,.*$//' zz-out/pass13_unknown_args.txt | uniq | sed 's/^/ - /' | head -n 20 || true

echo
echo "[PASS13-RUN] Terminé. Consulte :"
echo " - zz-out/homog_smoke_pass13.csv"
echo " - zz-out/homog_smoke_pass13.log"
echo " - zz-out/pass13_summary_by_chapter.txt"
echo " - zz-out/pass13_fail_exec_signatures.txt"
echo " - zz-out/pass13_required_args.txt"
echo " - zz-out/pass13_unknown_args.txt"
