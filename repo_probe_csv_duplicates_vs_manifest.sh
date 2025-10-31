# repo_probe_csv_duplicates_vs_manifest.sh (lecture seule)
set +e; set -u
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MAN="$REPO/zz-manifests/manifest_master.json"
if [ ! -f "$MAN" ]; then echo "Manifest introuvable: $MAN"; read -r -p "[PAUSE]"; exit 1; fi

echo "== ENTRÉES manifest pointant vers .csv (suspect si .csv.gz existe) =="
jq -r '..|select(type=="object" and has("path"))|.path' "$MAN" 2>/dev/null \
 | grep -E '\.csv$' | while read -r c; do
     gz="${c}.gz"
     if [ -f "$REPO/${gz#/}" ]; then
       printf "CSV_DUP  %-80s  has_gz=YES\n" "$c"
     else
       printf "CSV_SOLO %-80s  has_gz=NO \n" "$c"
     fi
   done | tee /tmp/manifest_csv_scan.txt

echo; echo "Résumé:"
awk '{c[$1]++}END{for(k in c) printf "%s\t%d\n",k,c[k]}' /tmp/manifest_csv_scan.txt | sort
read -r -p "[PAUSE] Entrée..." _
