#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

REPORT=".ci-out/manifests_json_guard_report.txt"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

# -- Dépendance : jq (installé par le workflow en CI ; requis en local pour exécuter le guard)
if ! command -v jq >/dev/null 2>&1; then
  err "jq manquant. Installe-le (ex: conda install -c conda-forge jq) ou lance en CI."
  exit 2
fi

PUB_JSON="zz-manifests/manifest_publication.json"
MAS_JSON="zz-manifests/manifest_master.json"
SHA_SUMS="zz-manifests/manifest_publication.sha256sum"

fail=0

# -- 0) Présence des fichiers attendus
for f in "$PUB_JSON" "$MAS_JSON" "$SHA_SUMS"; do
  if [[ ! -f "$f" ]]; then
    err "Fichier manquant: $f"
    fail=1
  fi
done
((fail)) && {
  echo "❌ manifests-json-guard: ÉCHEC (fichiers manquants). Rapport: $REPORT"
  exit 1
}

# -- Helper: extraction robuste des .path quelle que soit la structure JSON
extract_paths() {
  local json="$1"
  if jq -e 'type=="array"' "$json" >/dev/null 2>&1; then
    jq -r '.[]?|.path? // empty' "$json" | sed '/^$/d'
  else
    jq -r '.. | objects | .path? // empty' "$json" | sed '/^$/d'
  fi
}

log "Lecture JSON & SHA…"
mapfile -t PUB_PATHS < <(extract_paths "$PUB_JSON")
mapfile -t MAS_PATHS < <(extract_paths "$MAS_JSON")
mapfile -t SHA_PATHS < <(awk '{print $2}' "$SHA_SUMS" | sed '/^$/d')

tmp_pub="$(mktemp)"
tmp_mas="$(mktemp)"
tmp_sha="$(mktemp)"
printf "%s\n" "${PUB_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_pub"
printf "%s\n" "${MAS_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_mas"
printf "%s\n" "${SHA_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_sha"

# -- 1) publication.json ⊆ master.json
missing_in_master="$(comm -23 "$tmp_pub" "$tmp_mas" || true)"
if [[ -n "$missing_in_master" ]]; then
  err "Chemins présents dans publication.json mais absents de master.json:"
  echo "$missing_in_master" | tee -a "$REPORT"
  fail=1
else
  log "publication.json est inclus dans master.json"
fi

# -- 2) publication.json ⊆ manifest_publication.sha256sum
missing_in_sha="$(comm -23 "$tmp_pub" "$tmp_sha" || true)"
if [[ -n "$missing_in_sha" ]]; then
  err "Chemins présents dans publication.json mais absents du manifest SHA256:"
  echo "$missing_in_sha" | tee -a "$REPORT"
  fail=1
else
  log "publication.json est inclus dans manifest_publication.sha256sum"
fi

# -- 3) Existence sur disque (publication.json)
missing_fs=()
while IFS= read -r p; do
  [[ -f "$p" ]] || missing_fs+=("$p")
done <"$tmp_pub"
if ((${#missing_fs[@]})); then
  err "Fichiers listés dans publication.json mais absents sur disque:"
  printf "%s\n" "${missing_fs[@]}" | tee -a "$REPORT"
  fail=1
else
  log "Tous les fichiers de publication.json existent sur disque"
fi

# -- 4) Doublons (publication.json)
dups="$(printf "%s\n" "${PUB_PATHS[@]}" | LC_ALL=C sort | uniq -d || true)"
if [[ -n "$dups" ]]; then
  err "Doublons détectés dans publication.json:"
  echo "$dups" | tee -a "$REPORT"
  fail=1
else
  log "Aucun doublon dans publication.json"
fi

# -- 5) Conventions de nommage (publication.json)
CANON_RX='^zz-figures/chapter[0-9]{2}/[0-9]{2}_fig_[A-Za-z0-9_]+\.(png|jpg|jpeg|svg)$'
bad_canon="$(printf "%s\n" "${PUB_PATHS[@]}" | grep -Ev "$CANON_RX" || true)"
if [[ -n "$bad_canon" ]]; then
  err "Chemins non canoniques (publication.json):"
  echo "$bad_canon" | tee -a "$REPORT"
  fail=1
else
  log "Canonicité OK (publication.json)"
fi

bad_prefix="$(printf "%s\n" "${PUB_PATHS[@]}" | grep -E '/fig_' || true)"
if [[ -n "$bad_prefix" ]]; then
  err "Ancien préfixe '/fig_' détecté (publication.json):"
  echo "$bad_prefix" | tee -a "$REPORT"
  fail=1
fi

bad_03b="$(printf "%s\n" "${PUB_PATHS[@]}" | grep -E '03b' || true)"
if [[ -n "$bad_03b" ]]; then
  err "Sous-chaîne '03b' détectée (préférer '03_b') (publication.json):"
  echo "$bad_03b" | tee -a "$REPORT"
  fail=1
fi

if ((fail)); then
  echo "❌ manifests-json-guard: ÉCHEC. Rapport: $REPORT"
  exit 1
fi

echo "✅ manifests-json-guard: OK. Rapport: $REPORT"
