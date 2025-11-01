#!/usr/bin/env bash
# repo_deepD_data_inventory.sh  —  Lecture seule
# But: inventorier zz-data/* (et un échantillon zz-figures/*), compter lignes/colonnes,
#      extraire entêtes/schemas, résumer par chapitre. Rapide et sans dépendances exotiques.
set -o pipefail; set +e
ts="$(date +%Y%m%dT%H%M%S)"
OUT="/tmp/mcgt_deepD_${ts}"
mkdir -p "$OUT"
echo "=== DEEP D (data inventory) — $ts — OUT=$OUT ===" | tee "$OUT/SUMMARY.txt"

# Anti-fermeture agressif
trap 'code=$?; echo; echo "[PAUSE] Appuie sur Entrée pour terminer (DEEP D) ..." ; read -r _; exit $code' EXIT

# Activation conda non bloquante
if command -v conda >/dev/null 2>&1; then
  BASE="$(conda info --base 2>/dev/null)"
  [ -n "$BASE" ] && [ -f "$BASE/etc/profile.d/conda.sh" ] && . "$BASE/etc/profile.d/conda.sh"
  conda activate mcgt-dev >/dev/null 2>&1 || true
fi

# Localisation
[ -d "$HOME/MCGT" ] && cd "$HOME/MCGT" || true
pwd | tee -a "$OUT/SUMMARY.txt"

export OUT

python3 - <<'PY'
import os, sys, csv, gzip, json, io, re, datetime

OUT = os.environ.get("OUT",".")
os.makedirs(OUT, exist_ok=True)

DATA_ROOT = "zz-data"
FIG_ROOTS = ["zz-figures/chapter04","zz-figures/chapter05"]  # léger échantillon

def iso(ts):
    try:
        return datetime.datetime.fromtimestamp(ts).isoformat(timespec="seconds")
    except:
        return ""

def read_head(path, n=2, gz=False, encodings=("utf-8","latin-1")):
    data = b""
    try:
        opener = gzip.open if gz else open
        with opener(path, "rb") as f:
            data = f.read(4096)  # 4 KB suffisent pour header
    except Exception as e:
        return "", ""
    for enc in encodings:
        try:
            txt = data.decode(enc, errors="replace")
            lines = txt.splitlines()
            h = lines[0] if lines else ""
            d = lines[1] if len(lines) > 1 else ""
            return h, d
        except:
            continue
    return "", ""

def count_rows(path, gz=False):
    try:
        if gz:
            with gzip.open(path, "rt", encoding="utf-8", errors="ignore") as f:
                return sum(1 for _ in f)
        else:
            with open(path, "rt", encoding="utf-8", errors="ignore") as f:
                return sum(1 for _ in f)
    except:
        return ""

def est_delim(cols):
    # heuristique séparateur
    if cols.count(",") >= cols.count("\t") and cols.count(",")>0:
        return ","
    if cols.count("\t")>0:
        return "\t"
    if cols.count(";")>0:
        return ";"
    return None

def split_cols(header):
    delim = est_delim(header)
    if delim: 
        return delim, [c.strip() for c in header.split(delim)]
    # .dat → espace
    parts = re.split(r"\s+", header.strip())
    if len(parts)>1:
        return "ws", parts
    return None, []

rows_data = []
for dp, dn, fs in os.walk(DATA_ROOT):
    for fn in fs:
        p = os.path.join(dp,fn)
        try:
            st = os.stat(p)
        except:
            continue
        size = st.st_size
        mtime = iso(st.st_mtime)
        ext = fn.lower()
        gz = ext.endswith(".gz")
        base_ext = ext[:-3] if gz else ext

        chapter = ""
        m = re.search(r"(chapter\d{2})", p)
        if m: chapter = m.group(1)

        kind = ""
        if base_ext.endswith(".csv") or base_ext.endswith(".dat") or base_ext.endswith(".tsv"):
            kind = "table"
            h,d = read_head(p, gz=gz)
            delim, cols = split_cols(h)
            nrows = count_rows(p, gz=gz)
            ncols = len(cols) if cols else ""
            rows_data.append([p, chapter, kind, "gz" if gz else "plain", size, mtime, nrows, ncols, h, d])
        elif base_ext.endswith(".json"):
            kind = "json"
            top = ""
            try:
                with (gzip.open(p,"rt",encoding="utf-8") if gz else open(p,"rt",encoding="utf-8")) as f:
                    obj = json.load(f)
                if isinstance(obj, dict):
                    keys = list(obj.keys())[:20]
                    top = "dict:" + ",".join(keys)
                elif isinstance(obj, list):
                    top = f"list(len~{len(obj)})"
                else:
                    top = type(obj).__name__
            except Exception as e:
                top = f"json_error:{e}"
            rows_data.append([p, chapter, kind, "gz" if gz else "plain", size, mtime, "", "", top, ""])
        else:
            # autre type ignoré ici
            continue

# Écrit TSV
tsv = os.path.join(OUT,"data_inventory.tsv")
with open(tsv,"w",newline="",encoding="utf-8") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["path","chapter","kind","compression","size_bytes","mtime_iso","rows","cols","header_or_json","first_data_row"])
    w.writerows(rows_data)

# Sommaire par chapitre
by_ch = {}
for r in rows_data:
    ch = r[1] or "unknown"
    by_ch.setdefault(ch, {"files":0, "rows":0, "bytes":0})
    by_ch[ch]["files"] += 1
    try:
        by_ch[ch]["rows"] += int(r[6]) if r[6] not in ("","json_error") else 0
    except: pass
    by_ch[ch]["bytes"] += int(r[4]) if r[4] not in ("","json_error") else 0

sum_tsv = os.path.join(OUT,"data_summary_by_chapter.tsv")
with open(sum_tsv,"w",newline="",encoding="utf-8") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["chapter","n_files","approx_rows","total_bytes"])
    for ch,agg in sorted(by_ch.items()):
        w.writerow([ch, agg["files"], agg["rows"], agg["bytes"]])

print(f"[OK] data_inventory.tsv => {tsv}")
print(f"[OK] data_summary_by_chapter.tsv => {sum_tsv}")
PY

# Un petit du -sh par chapitre (lecture seule)
du -sh zz-data/chapter* 2>/dev/null | sort -h > "$OUT/du_zz_data.txt" || true
echo "[OK] du_zz_data.txt => $OUT/du_zz_data.txt"
echo; ls -lh "$OUT"
