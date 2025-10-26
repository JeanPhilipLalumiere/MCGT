#!/usr/bin/env bash
# Applique une liste "add-to-manifest" en batch.
# Accepte 1 colonne (path) ou 3 colonnes (path sha256 mtime_iso).
set -euo pipefail

ts(){ date -u +'%Y-%m-%dT%H:%M:%SZ'; }
say(){ echo "[$(ts)] $*"; }

LIST="${LIST:-}"
BATCH="${BATCH:-50}"
APPLY="${APPLY:-0}"
MASTER="zz-manifests/manifest_master.json"

latest_by_name(){ ls -1 "$1" 2>/dev/null | sort -r | head -n1 || true; }

# Heuristique de rôle (doit appartenir à ALLOWED_ROLES côté tests)
guess_role() {
  local p="$1"
  case "$p" in
    tools/*|*.sh|*.py|*.ipynb|*.R|*.jl|*.lua|*.c|*.cpp|*.h|*.hpp|*.java|*.ts|*.js|*.go|*.rs) echo "code" ;;
    policies/*|config/*|*.yml|*.yaml|*.toml|*.ini|*.cfg|*.conf|*.json|*.lock) echo "config" ;;
    data/*|datasets/*|raw/*|intermediate/*|processed/*|*.csv|*.tsv|*.parquet|*.feather|*.h5|*.hdf5|*.nc|*.npy|*.npz) echo "data" ;;
    docs/*|*.md|*.rst|*.tex|*.pdf) echo "document" ;;
    bib/*|*.bib|*.ris|*.enl) echo "bibliography" ;;
    assets/*|figures/*|images/*|img/*|*.png|*.jpg|*.jpeg|*.svg|*.tif|*.tiff|*.gif|*.eps) echo "artifact" ;;
    *) echo "code" ;;  # par défaut, sans risque
  esac
}

if [[ -z "${LIST}" ]]; then
  LIST="$(latest_by_name "_tmp/proposed_add_to_manifest.*.txt")"
fi

if [[ -z "$LIST" || ! -f "$LIST" ]]; then
  say "[input] aucune liste valide fournie/trouvée"
  echo "ADDED:0"
  exit 0
fi

say "== apply_add: start == LIST=${LIST} BATCH=${BATCH} APPLY=${APPLY}"

TOTAL=$(grep -c '^[^#[:space:]]' "$LIST" || true)
say "[input] total lignes (non commentées): ${TOTAL:-0}"
say "[preview] first ${BATCH} (avec auto-metadata si manquante):"

BACKUP="zz-manifests/manifest_master.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -v "$MASTER" "$BACKUP" >/dev/null 2>&1 || true
say "[backup] -> ${BACKUP}"

ADDED=0
n=0
line_num=0

while IFS= read -r raw; do
  line_num=$((line_num+1))
  [[ -z "$raw" || "$raw" =~ ^[[:space:]]*# ]] && continue

  # split souple (espaces/onglets)
  set -- $raw
  path="${1:-}"; sha="${2:-}"; mt="${3:-}"
  [[ -z "$path" ]] && continue

  n=$((n+1))
  (( n > BATCH )) && break

  # Compléter métadonnées si absentes
  if [[ -z "${sha:-}" || -z "${mt:-}" ]]; then
    if [[ ! -f "$path" ]]; then
      say "[warn] introuvable: $path (ligne $line_num) — ignoré"
      continue
    fi
    sha="$(sha256sum "$path" | awk '{print $1}')"
    mt="$(date -u -d "@$(stat -c %Y "$path")" +'%Y-%m-%dT%H:%M:%SZ')"
  fi

  size="$(stat -c%s "$path" 2>/dev/null || echo 0)"
  ghash="$(git rev-list -1 HEAD -- "$path" 2>/dev/null || true)"
  [[ -z "$ghash" ]] && ghash=null
  role="$(guess_role "$path")"

  printf "  + %-60s %s  %s  [role=%s]\n" "$path" "$sha" "$mt" "$role"

  if [[ "$APPLY" == "1" ]]; then
    # upsert + renseigne role si absent
    jq --arg p "$path" --arg sha "$sha" --arg mt "$mt" \
       --argjson size "$size" --arg gh "$ghash" --arg role "$role" '
      .entries = (
        .entries
        | (map(select(.path == $p)) | length) as $exists
        | if $exists == 0 then
            . + [{
              path:$p, role:$role, sha256:$sha, size_bytes:$size, mtime_iso:$mt,
              git_hash: ($gh|if .=="null" then null else . end)
            }]
          else
            map(if .path == $p
                then
                  (if (.role == null) then . + {role:$role} else . end)
                  + {sha256:$sha, size_bytes:$size, mtime_iso:$mt}
                  + ( ($gh|if .=="null" then {} else {git_hash:$gh} end) )
                else .
                end)
          end
      )
    ' "$MASTER" > "$MASTER.tmp" && mv -f "$MASTER.tmp" "$MASTER"
    ADDED=$((ADDED+1))
  fi
done < "$LIST"

echo "ADDED:${ADDED}"
say "== apply_add: done =="
