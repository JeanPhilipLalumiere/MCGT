#!/usr/bin/env bash
set -euo pipefail
STRICT_ORPHANS="${STRICT_ORPHANS:-0}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

OUT_DIR=".ci-out"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/figures_guard_report.txt"
ALLOWLIST_FILE=".ci-config/figures_orphans_allowlist.txt"
: >"$REPORT"

err() { echo "ERROR: $*" | tee -a "$REPORT"; }
info() { echo "INFO:  $*" | tee -a "$REPORT"; }
fail=0

info "==> Scan des figures suivies par git"
mapfile -t FS < <(git ls-files 'zz-figures/**/*.png' 'zz-figures/**/*.jpg' 'zz-figures/**/*.jpeg' 'zz-figures/**/*.svg' 2>/dev/null | LC_ALL=C sort || true)

# Limite la recherche aux fichiers “source” (exclut artefacts/archives/baks/sha256sum/gitignore)
mapfile -t SEARCH < <(
  git ls-files |
    grep -Ev '^(\.ci-out|\.ci-logs|\.ci-archive)/' |
    grep -Ev '\.bak($|\.)' |
    grep -Ev 'manifest_publication\.sha256sum$' |
    grep -Ev '^\.gitignore$'
)

info "==> Scan des références aux figures (dans les sources)"
REF_PAT='zz-figures/[^"'"'"')\] >]+\.((png)|(jpg)|(jpeg)|(svg))'
mapfile -t REFS < <(grep -h -o -E "${REF_PAT}" "${SEARCH[@]}" 2>/dev/null | LC_ALL=C sort -u || true)

info "==> Vérification des conventions de nommage et de la casse"
bad_names=()
mismatch_prefix=()
upper_in_name=()

for f in "${FS[@]}"; do
  base="$(basename "$f")"
  dir="$(dirname "$f")"
  chap="$(basename "$dir")" # ex: chapter07
  chapnum="${chap#chapter}" # ex: 07
  [[ "$base" =~ [A-Z] ]] && upper_in_name+=("$f")
  if [[ ! "$base" =~ ^[0-9]{2}_fig_[0-9]{2}_[a-z0-9_]+\.(png|jpe?g|svg)$ ]]; then
    bad_names+=("$f")
  fi
  prefix="${base%%_*}" # ex: 07
  [[ "$prefix" != "$chapnum" ]] && mismatch_prefix+=("$f")
done

if ((${#upper_in_name[@]})); then
  err "Fichiers avec MAJUSCULES dans le nom:"
  printf '  - %s\n' "${upper_in_name[@]}" | tee -a "$REPORT"
  fail=1
fi
if ((${#bad_names[@]})); then
  err "Fichiers qui ne respectent pas ^NN_fig_MM_[a-z0-9_]+.(png|jpg|jpeg|svg)$ :"
  printf '  - %s\n' "${bad_names[@]}" | tee -a "$REPORT"
  fail=1
fi
if ((${#mismatch_prefix[@]})); then
  err "Fichiers dont le préfixe NN ne correspond pas au dossier chapterNN :"
  printf '  - %s\n' "${mismatch_prefix[@]}" | tee -a "$REPORT"
  fail=1
fi

info "==> Vérification d'anciennes références (ex: chapterXX/fig_) [sources uniquement]"
mapfile -t OLDREFS < <(grep -n -E 'zz-figures/chapter[0-9]{2}/fig_' "${SEARCH[@]}" || true)
if ((${#OLDREFS[@]})); then
  err "Anciennes références détectées (doivent être NN_fig_...):"
  printf '  - %s\n' "${OLDREFS[@]}" | tee -a "$REPORT"
  fail=1
fi

info "==> Croisement références <-> fichiers"
tmp_refs="$(mktemp)"
tmp_fs="$(mktemp)"
printf '%s\n' "${REFS[@]}" | LC_ALL=C sort -u >"$tmp_refs"
printf '%s\n' "${FS[@]}" | LC_ALL=C sort -u >"$tmp_fs"

missing="$(comm -23 "$tmp_refs" "$tmp_fs" || true)"
orphans="$(comm -13 "$tmp_refs" "$tmp_fs" || true)"

if [[ -n "$missing" ]]; then
  err "Références pointant vers des fichiers absents:"
  echo "$missing" | sed 's/^/  - /' | tee -a "$REPORT"
  fail=1
fi
if [[ -n "$orphans" ]]; then
  info "Orphelins (présents mais non référencés en sources) — informatif :"
  echo "$orphans" | sed 's/^/  - /' | tee -a "$REPORT"
fi

echo "" | tee -a "$REPORT"
if ((fail == 0)); then
  echo "✅ Figures guard: OK (aucune erreur bloquante). Rapport: $REPORT"
else
  echo "❌ Figures guard: ÉCHEC. Voir le rapport: $REPORT"
  exit 1
fi

# STRICT_ORPHANS enforcement (avec allowlist)
mkdir -p .ci-config
: >"$REPORT" # s'assurer que $REPORT existe même si rien n'a encore écrit

# Charger l'allowlist (globs), ignorer vides/commentaires
mapfile -t _ALLOW < <(grep -vE '^\s*($|#)' "$ALLOWLIST_FILE" 2>/dev/null || true)

# Extraire les "orphelins" depuis le rapport produit plus haut par le script :
#   - entre "INFO:  Orphelins" et le prochain "INFO:" (ou EOF)
mapfile -t _ORPH_ALL < <(
  awk '
    /^INFO:  Orphelins / { flag=1; next }
    flag && /^  - /      { sub(/^[[:space:]]*-[[:space:]]*/, "", \$0); print \$0; next }
    flag && /^INFO:/     { flag=0 }
  ' "$REPORT" 2>/dev/null || true
)

# Filtrer avec allowlist (globs)
_ORPH=()
for o in "${_ORPH_ALL[@]:-}"; do
  keep=1
  if declare -p _ALLOW >/dev/null 2>&1; then _allow_list=("${_ALLOW[@]}"); else _allow_list=(); fi
  for p in "${_allow_list[@]}"; do
    if [[ "$o" == "$p" ]]; then
      keep=0
      break
    fi
  done
  ((keep)) && _ORPH+=("$o")
done

__len__ORPH=0
if declare -p _ORPH >/dev/null 2>&1; then __len__ORPH=${#_ORPH[@]}; fi
if ((__len__ORPH)); then
  info "==> Orphelins (hors allowlist) :"
  for o in "${_ORPH[@]}"; do echo "  - $o" | tee -a "$REPORT"; done
  if [[ "$STRICT_ORPHANS" == "1" ]]; then
    err "Orphelins détectés et STRICT_ORPHANS=1"
    fail=1
  fi
else
  info "==> Aucun orphelin hors allowlist."
fi

# === STRICT_ORPHANS enforcement (basé sur la section "hors allowlist") ===
if [[ "${STRICT_ORPHANS:-0}" == "1" ]]; then
  oa_count="$(
    awk '
      /^\s*INFO:  ==> Orphelins \(hors allowlist\)/ { flag=1; next }
      flag && /^\s*INFO:/ { flag=0; next }
      flag && /^\s*-\s*$/ { next }        # un tiret seul = aucun item
      flag && /^\s{2}- / { c++ }          # items: lignes commençant par "  - "
      END { print (c+0) }
    ' "$REPORT" 2>/dev/null || echo 0
  )"
  if [[ "$oa_count" =~ ^[0-9]+$ ]] && ((oa_count > 0)); then
    err "Orphelins détectés (hors allowlist): ${oa_count} et STRICT_ORPHANS=1"
    fail=1
  fi
fi
# ==========================================================================
exit "$fail"
