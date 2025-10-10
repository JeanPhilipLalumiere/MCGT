#!/usr/bin/env bash
set -euo pipefail

CSV="zz-out/homog_smoke_pass13.csv"
LOG="zz-out/homog_smoke_pass13.log"
OUTDIR="zz-out"
[[ -s "$CSV" ]] || { echo "[ERR] $CSV introuvable ou vide (lance d'abord pass13)"; exit 1; }
[[ -s "$LOG" ]] || { echo "[ERR] $LOG introuvable ou vide (lance d'abord pass13)"; exit 1; }

CH_SUM="$OUTDIR/pass13_summary_by_chapter.txt"
TOP_ERR="$OUTDIR/pass13_fail_exec_signatures.txt"
REQ_ARGS="$OUTDIR/pass13_required_args.txt"
UNK_ARGS="$OUTDIR/pass13_unknown_args.txt"

echo "[PASS13-A] Analyse…"

# 1) résumé par chapitre et par statut
awk -F, '
  BEGIN{ OFS="," }
  NR==1{next}
  {
    # file,status,reason,elapsed_sec,out_path,out_size
    f=$1; st=$2;
    if (match(f, /chapter([0-9]{2})\//, m)) chap=m[1]; else chap="??";
    key=chap SUBSEP st;
    c[key]++;
  }
  END{
    print "chapter,status,count";
    for (k in c) {
      split(k,a,SUBSEP);
      print a[1], a[2], c[k];
    }
  }' "$CSV" \
  | sort -t, -k1,1 -k2,2 \
  > "$CH_SUM"

# 2) top signatures d’erreurs FAIL_EXEC (on compacte la fin des logs par bloc)
#    On découpe LOG par séparateur '----- <file> (rc=..., Ns) -----'
python3 - <<'PY'
import re, collections, pathlib
log = pathlib.Path("zz-out/homog_smoke_pass13.log").read_text(encoding="utf-8", errors="replace")
blocks = re.split(r"^-{5}\s+.*?\)\s*-{5}\s*$", log, flags=re.M)
# Les lignes d'erreurs utiles (dernières ~10) sont déjà compactées en source ; on agrège par signature courte
norm = lambda s: re.sub(r"\s+", " ", s.strip())
cnt = collections.Counter()
for b in blocks:
    s = norm(b)
    if not s: continue
    # tronquer pour signature courte (éviter paths)
    s = re.sub(r"/[\w\-/\.]+", "<PATH>", s)
    s = re.sub(r"line \d+", "line <N>", s)
    s = re.sub(r"\d+\.\d+|\d+", "<NUM>", s)
    # ne garder que 200 chars
    cnt[s[:200]] += 1

out = pathlib.Path("zz-out/pass13_fail_exec_signatures.txt")
with out.open("w", encoding="utf-8") as f:
    for sig, n in cnt.most_common(40):
        f.write(f"[{n}] {sig}\n\n")
PY

# 3) scripts à args obligatoires
awk -F, 'NR>1 && $2 ~ /SKIP_REQUIRED_ARGS/ {print $1 "," $3}' "$CSV" \
  | sort \
  > "$REQ_ARGS"

# 4) scripts aux options inconnues
awk -F, 'NR>1 && $2 ~ /SKIP_UNKNOWN_ARGS/ {print $1 "," $3}' "$CSV" \
  | sort \
  > "$UNK_ARGS"

echo "[PASS13-A] Écrits :"
echo " - $CH_SUM"
echo " - $TOP_ERR"
echo " - $REQ_ARGS"
echo " - $UNK_ARGS"

# 5) aperçu rapide
echo
echo "=== Aperçu par chapitre (top) ==="
column -s, -t "$CH_SUM" | head -n 20 || true

echo
echo "=== Top signatures FAIL_EXEC ==="
head -n 40 "$TOP_ERR" || true

echo
echo "=== Scripts avec arguments obligatoires ==="
sed -E 's/,.*$//' "$REQ_ARGS" | uniq | sed 's/^/ - /' | head -n 20 || true

echo
echo "=== Scripts avec options inconnues (--out/--dpi?) ==="
sed -E 's/,.*$//' "$UNK_ARGS" | uniq | sed 's/^/ - /' | head -n 20 || true
