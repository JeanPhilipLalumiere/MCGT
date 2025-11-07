#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

REPORT=".ci-out/manifests_json_guard_report.txt"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

# jq requis
if ! command -v jq >/dev/null 2>&1; then
  err "jq manquant. Installe-le (ex: conda install -c conda-forge jq) ou lance en CI."
  exit 2
fi

PUB_JSON="zz-manifests/manifest_publication.json"
MAS_JSON="zz-manifests/manifest_master.json"
SHA_SUMS="zz-manifests/manifest_publication.sha256sum"

fail=0
for f in "$PUB_JSON" "$MAS_JSON" "$SHA_SUMS"; do
  [[ -f "$f" ]] || {
    err "Fichier manquant: $f"
    fail=1
  }
done
((fail)) && {
  echo "❌ manifests-json-guard: ÉCHEC (fichiers manquants). Rapport: $REPORT"
  exit 1
}

# Extraction robuste des chemins .path quel que soit le schéma JSON
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

# Tri/uniq
tmp_pub="$(mktemp)"
tmp_mas="$(mktemp)"
tmp_sha="$(mktemp)"
printf "%s\n" "${PUB_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_pub"
printf "%s\n" "${MAS_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_mas"
printf "%s\n" "${SHA_PATHS[@]}" | LC_ALL=C sort -u >"$tmp_sha"

# Filtrage "figures" pour checks SHA & nommage
FIG_RX='^zz-figures/.*\.(png|jpg|jpeg|svg)$'
tmp_fig_pub="$(mktemp)"
tmp_fig_sha="$(mktemp)"
grep -E "$FIG_RX" "$tmp_pub" >"$tmp_fig_pub" || true
grep -E "$FIG_RX" "$tmp_sha" >"$tmp_fig_sha" || true

# 1) publication.json ⊆ master.json (sur TOUTES les ressources)
missing_in_master="$(comm -23 "$tmp_pub" "$tmp_mas" || true)"
if [[ -n "$missing_in_master" ]]; then
  err "Chemins présents dans publication.json mais absents de master.json:"
  echo "$missing_in_master" | tee -a "$REPORT"
  fail=1
else
  log "publication.json est inclus dans master.json"
fi

# 2) (FIGURES SEULEMENT) publication.json ⊆ manifest_publication.sha256sum
missing_in_sha="$(comm -23 "$tmp_fig_pub" "$tmp_fig_sha" || true)"
if [[ -n "$missing_in_sha" ]]; then
  err "Figures présentes dans publication.json mais absentes du manifest SHA256:"
  echo "$missing_in_sha" | tee -a "$REPORT"
  fail=1
else
  log "Correspondance figures ↔ SHA256 OK"
fi

# 3) Existence sur disque (sur TOUTES les ressources publiées)
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

# 4) Doublons (sur TOUTES les ressources)
dups="$(printf "%s\n" "${PUB_PATHS[@]}" | LC_ALL=C sort | uniq -d || true)"
if [[ -n "$dups" ]]; then
  err "Doublons détectés dans publication.json:"
  echo "$dups" | tee -a "$REPORT"
  fail=1
else
  log "Aucun doublon dans publication.json"
fi

# 5) Conventions de nommage (FIGURES SEULEMENT)
mapfile -t FIG_PUB_ARR <"$tmp_fig_pub"
if ((${#FIG_PUB_ARR[@]})); then
  CANON_RX='^zz-figures/chapter[0-9]{2}/[0-9]{2}_fig_[A-Za-z0-9_]+\.(png|jpg|jpeg|svg)$'
  bad_canon="$(printf "%s\n" "${FIG_PUB_ARR[@]}" | grep -Ev "$CANON_RX" || true)"
  if [[ -n "$bad_canon" ]]; then
    err "Chemins non canoniques (figures) :"
    echo "$bad_canon" | tee -a "$REPORT"
    fail=1
  else
    log "Canonicité OK (figures)"
  fi

  bad_prefix="$(printf "%s\n" "${FIG_PUB_ARR[@]}" | grep -E '/fig_' || true)"
  [[ -z "$bad_prefix" ]] || {
    err "Ancien préfixe '/fig_' détecté (figures) :"
    echo "$bad_prefix" | tee -a "$REPORT"
    fail=1
  }

  bad_03b="$(printf "%s\n" "${FIG_PUB_ARR[@]}" | grep -E '03b' || true)"
  [[ -z "$bad_03b" ]] || {
    err "Sous-chaîne '03b' détectée (préférer '03_b') (figures) :"
    echo "$bad_03b" | tee -a "$REPORT"
    fail=1
  }
else
  log "Aucune figure dans publication.json (rien à valider côté nommage/SHA)."
fi

if ((fail)); then
  echo "❌ manifests-json-guard: ÉCHEC. Rapport: $REPORT"
  exit 1
fi

echo "✅ manifests-json-guard: OK. Rapport: $REPORT"
