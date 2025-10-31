# repo_step4_patch_manifest_csv_to_gz.sh — génère un patch uniquement
set -euo pipefail
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MAN="$REPO/zz-manifests/manifest_master.json"
OUTDIR="/tmp/mcgt_patch_csvgz_$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUTDIR"
cp -a "$MAN" "$OUTDIR/manifest_master.json.orig"
cp -a "$MAN" "$OUTDIR/manifest_master.json.new"

# Remplacement ciblé pour les 8 chemins DUP (déduits de ton scan)
while read -r p; do
  jq --arg old "$p" --arg new "${p}.gz" '
    (..|objects|select(has("path") and .path==$old)|.path) |= $new
  ' "$OUTDIR/manifest_master.json.new" > "$OUTDIR/_tmp.json" && mv "$OUTDIR/_tmp.json" "$OUTDIR/manifest_master.json.new"
done <<'CSVLIST'
zz-data/chapter10/10_mc_results.csv
zz-data/chapter10/10_mc_results.circ.with_fpeak.csv
zz-data/chapter10/10_mc_results.circ.csv
zz-data/chapter10/10_mc_results.circ.agg.csv
zz-data/chapter10/10_mc_results.agg.csv
zz-data/chapter08/08_chi2_scan2D.csv
zz-data/chapter07/07_delta_phi_matrix.csv
zz-data/chapter07/07_cs2_matrix.csv
CSVLIST

# Fabrique un patch diff lisible
git --no-pager diff --no-index "$OUTDIR/manifest_master.json.orig" "$OUTDIR/manifest_master.json.new" > "$OUTDIR/manifest_csv_to_gz.patch" || true
echo "PATCH prêt: $OUTDIR/manifest_csv_to_gz.patch"
echo "Aperçu:"; sed -n '1,120p' "$OUTDIR/manifest_csv_to_gz.patch"
read -r -p "[PAUSE] Entrée..." _
