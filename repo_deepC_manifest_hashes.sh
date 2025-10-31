#!/usr/bin/env bash
# repo_deepC_manifest_hashes.sh  —  Lecture seule
# But: croiser manifest_master/publication avec le disque, produire SHA256,
#      lister les MISSING/UNREFERENCED et fabriquer un SHA256SUMS pour la publication.
set -o pipefail; set +e
ts="$(date +%Y%m%dT%H%M%S)"
OUT="/tmp/mcgt_deepC_${ts}"
mkdir -p "$OUT"
echo "=== DEEP C (manifest+hashes) — $ts — OUT=$OUT ===" | tee "$OUT/SUMMARY.txt"

# Anti-fermeture agressif
trap 'code=$?; echo; echo "[PAUSE] Appuie sur Entrée pour terminer (DEEP C) ..." ; read -r _; exit $code' EXIT

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
import os, sys, json, hashlib, csv, datetime, stat

OUT = os.environ.get("OUT",".")
os.makedirs(OUT, exist_ok=True)

def iso(ts):
    try: return datetime.datetime.fromtimestamp(ts).isoformat(timespec="seconds")
    except: return ""

def sha256(path, chunk=1024*1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def collect_paths_from_record(rec):
    # Accepte plusieurs schémas de manifestes
    keys_singular = ["path","file","target"]
    keys_plural   = ["paths","files","targets"]
    out = []
    for k in keys_singular:
        v = rec.get(k)
        if isinstance(v, str): out.append(v)
    for k in keys_plural:
        v = rec.get(k)
        if isinstance(v, list):
            out.extend([x for x in v if isinstance(x, str)])
    return out

def load_manifest_items(manifest_path):
    try:
        with open(manifest_path,"r",encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"[WARN] Impossible de lire {manifest_path}: {e}")
        return []

    if isinstance(data, list):
        items = data
    elif isinstance(data, dict):
        for key in ("entries","items","files"):
            if key in data and isinstance(data[key], list):
                items = data[key]; break
        else:
            # Peut-être un dict {path:..., type:...}
            items = [data]
    else:
        items = []
    return items

manifests = [
    ("manifest_master.json", "zz-manifests/manifest_master.json"),
    ("manifest_publication.json", "zz-manifests/manifest_publication.json"),
]

scan_rows = []
present_publication = []
missing_counts = {}

for name, mp in manifests:
    if not os.path.isfile(mp):
        print(f"[MISS] {mp} absent")
        continue
    items = load_manifest_items(mp)
    miss = 0
    for idx, rec in enumerate(items):
        role = rec.get("role") or rec.get("type") or rec.get("kind") or ""
        for p in collect_paths_from_record(rec):
            status = "missing"
            size = mtime = digest = ""
            if os.path.exists(p):
                try:
                    st = os.stat(p)
                    size = str(st.st_size)
                    mtime = iso(st.st_mtime)
                    # Hash seulement pour fichiers réguliers
                    if stat.S_ISREG(st.st_mode):
                        digest = sha256(p)
                    status = "present"
                    if name == "manifest_publication.json":
                        present_publication.append((digest, p))
                except Exception as e:
                    status = f"error:{e}"
            else:
                miss += 1
            scan_rows.append([name, str(idx), role, p, status, size, mtime, digest])
    missing_counts[name] = miss

# Écrit le scan TSV
scan_tsv = os.path.join(OUT,"manifest_scan.tsv")
with open(scan_tsv,"w",newline="",encoding="utf-8") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["manifest","idx","role","path","status","size_bytes","mtime_iso","sha256"])
    w.writerows(scan_rows)

# SHA256SUMS pour publication (présents uniquement)
sha_pub = os.path.join(OUT,"SHA256SUMS_publication.txt")
with open(sha_pub,"w",encoding="utf-8") as f:
    for d,p in present_publication:
        if d and p:
            f.write(f"{d}  {p}\n")

# Unreferenced (dans arbres clefs mais hors manifestes)
manifest_set = set(r[3] for r in scan_rows)
roots = ["zz-data","zz-figures","zz-scripts","scripts","tools","mcgt","zz_tools"]
ignore = (".git","_attic_untracked","_snapshots","zz-out",".ci-","attic","backups","_tmp","release_zenodo_codeonly")
unref_rows = []
for root in roots:
    if not os.path.isdir(root): continue
    for dp, dn, files in os.walk(root):
        # Ignore répertoires bruyants
        base = os.path.basename(dp)
        if any(seg in dp for seg in ignore): 
            continue
        for fn in files:
            p = os.path.join(dp,fn)
            if p not in manifest_set:
                try:
                    st = os.stat(p)
                    unref_rows.append([p, st.st_size, iso(st.st_mtime)])
                except:
                    unref_rows.append([p, "", ""])
unref_tsv = os.path.join(OUT,"unreferenced.tsv")
with open(unref_tsv,"w",newline="",encoding="utf-8") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["path","size_bytes","mtime_iso"])
    w.writerows(unref_rows)

# Résumé
summary = os.path.join(OUT,"SUMMARY.txt")
with open(summary,"a",encoding="utf-8") as f:
    f.write("\n--- Missing par manifeste ---\n")
    for k,v in missing_counts.items():
        f.write(f"{k}: {v}\n")
    f.write(f"\nRows dans manifest_scan.tsv: {len(scan_rows)}\n")
    f.write(f"Unreferenced (non listés par manifestes): {len(unref_rows)} -> {unref_tsv}\n")
    f.write(f"SHA256 publication: {sha_pub}\n")
print(f"[OK] manifest_scan.tsv => {scan_tsv}")
print(f"[OK] SHA256SUMS_publication.txt => {sha_pub}")
print(f"[OK] unreferenced.tsv => {unref_tsv}")
PY

# Liste des artefacts
echo; ls -lh "$OUT"
