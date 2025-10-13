#!/usr/bin/env bash
# source POSIX copy helper (safe_cp)
. "$(dirname "$0")/lib_posix_cp.sh" 2>/dev/null || . "/home/jplal/MCGT/tools/lib_posix_cp.sh" 2>/dev/null

set -euo pipefail
echo "[PASS12] Retrait des PASS5B-SHIM + re-scan v5 + auto-rollback ciblé si besoin"

INVENTORY="tools/homog_pass4_cli_inventory_safe_v5.sh"
[[ -x "$INVENTORY" ]] || { echo "[ERR] $INVENTORY introuvable"; exit 1; }

marker_open="# === [PASS5B-SHIM] ==="
marker_close="# === [/PASS5B-SHIM] ==="

# 1) Lister les fichiers qui contiennent un shim PASS5B
mapfile -t SHIM_FILES < <(grep -rl --exclude-dir=.git -e "$marker_open" zz-scripts || true)
echo "[PASS12] Fichiers avec PASS5B: ${#SHIM_FILES[@]}"

# 2) Retrait idempotent du bloc (backup pass12bak une seule fois)
removed=0
for f in "${SHIM_FILES[@]}"; do
  [[ -f "$f" ]] || continue
  safe_cp "$f" "$f.pass12bak" 2>/dev/null || true
  python3 - "$f" "$marker_open" "$marker_close" <<'PY'
import sys, re, pathlib
p = pathlib.Path(sys.argv[1]); mo=sys.argv[2]; mc=sys.argv[3]
s = p.read_text(encoding="utf-8", errors="replace")
s2 = re.sub(rf"(?ms)^\s*{re.escape(mo)}.*?{re.escape(mc)}\s*\n?", "", s)
if s2 != s:
    p.write_text(s2, encoding="utf-8")
    print(f"[OK] Shim retiré: {p}")
tools/pass12_remove_shims_and_verify.shverify.sh shims."].*\n)?(?:from __future__.*\n)?)([ \t]*[ru]?["\']{3}.*?["\']{3}\s*\n)',
[PASS12] Retrait des PASS5B-SHIM + re-scan v5 + auto-rollback ciblé si besoin
[PASS12] Fichiers avec PASS5B: 0
[PASS12] Shims retirés (tentatives): 0
[HOMOG-PASS4-SAFE v5] Inventaire CLI (--help) tolérant (usage-based), parallèle, Agg
[DONE] Scan écrit:
 - zz-out/homog_cli_inventory_pass4.txt
 - zz-out/homog_cli_inventory_pass4.csv
 - zz-out/homog_cli_fail_list.txt
zz-scripts/chapter10/plot_fig07_synthesis.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig01_iso_p95_maps.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig06_residual_map.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK
zz-scripts/chapter08/plot_fig05_residuals.py | argparse:yes | parse_args:no | main_guard:yes | savefig:yes | show:yes | help:OK
zz-scripts/chapter10/regen_fig05_using_circp95.py | argparse:yes | parse_args:yes | main_guard:yes | savefig:yes | show:no | help:OK

[SUMMARY] --help OK: 102, FAIL: 0
[LIST] Fichiers en échec: zz-out/homog_cli_fail_list.txt
[PASS12] ✅ Aucun FAIL après retrait des shims.
[PASS12] Fini.
[200~# tools/pass13_smoke_out_all.sh
cat <<'BASH' > tools/pass13_smoke_out_all.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[PASS13] Smoke headless (--out) sur tous les scripts + rapport"

SROOT="zz-scripts"
OUTDIR="zz-out/smoke"
REPDIR="zz-out"
CSV="$REPDIR/homog_smoke_pass13.csv"
LOG="$REPDIR/homog_smoke_pass13.log"
mkdir -p "$OUTDIR" "$REPDIR"
: > "$CSV"
: > "$LOG"

echo "file,status,reason,elapsed_sec,out_path,out_size" >> "$CSV"

export MPLBACKEND=Agg

run_one() {
  local f="$1"
  local rel="${f#${SROOT}/}"
  local outp="$OUTDIR/${rel%.py}.png"
  mkdir -p "$(dirname "$outp")"

  local t0 t1 dt
  t0=$(date +%s)
  # On redirige stderr pour analyse
  local tmp_err
  tmp_err="$(mktemp)"
  timeout 60s python3 "$f" --out "$outp" --dpi 96 > /dev/null 2> "$tmp_err"
  rc=$?
  t1=$(date +%s); dt=$((t1 - t0))

  if [[ $rc -eq 0 ]]; then
    local sz="0"
    [[ -s "$outp" ]] && sz=$(stat -c '%s' "$outp" 2>/dev/null || stat -f '%z' "$outp")
    echo "$f,OK,,${dt},$outp,$sz" >> "$CSV"
  else
    local err; err="$(tr -d '\r' < "$tmp_err" | tail -n 10)"
    local reason="FAIL_EXEC"
    grep -qiE 'the following arguments are required' <<<"$err" && reason="SKIP_REQUIRED_ARGS"
    grep -qiE 'unrecognized arguments|unrecognised arguments' <<<"$err" && reason="SKIP_UNKNOWN_ARGS"
    grep -qiE 'usage:|--help' <<<"$err" && reason="${reason};USAGE_HINT"

    echo "$f,$reason,$(echo "$err" | tr '\n' ' ' | sed 's/,/;/g'),${dt},$outp," >> "$CSV"
    {
      echo "----- $f (rc=$rc, ${dt}s) -----"
      echo "$err"
      echo
    } >> "$LOG"
  fi

  rm -f "$tmp_err"
}

export -f run_one
export SROOT OUTDIR CSV LOG

# Lister tous les .py des chapitres 01..10
find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" \
  | sort \
  | xargs -I{} -P"$(nproc)" bash -lc 'run_one "$@"' _ {}

echo "[PASS13] Rapport:"
echo " - $CSV"
echo " - $LOG"
# Résumé court
awk -F, 'NR>1 {c[$2]++} END{for (k in c) printf "[SUMMARY] %-20s %d\n", k, c[k];}' "$CSV" | sort
