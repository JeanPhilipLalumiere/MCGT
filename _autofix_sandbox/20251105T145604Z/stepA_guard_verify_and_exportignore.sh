#!/usr/bin/env bash
# File: stepA_guard_verify_and_exportignore.sh
set -Euo pipefail

VERSION="${VERSION:-v0.3.x}"
DOI_ID="${DOI_ID:-17428428}"  # 10.5281/zenodo.17428428
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/stepA_${STAMP}.log"; mkdir -p _logs
trap 'read -r -p "[HOLD] Terminé. Entrée pour revenir au shell… " _' EXIT
exec > >(tee -a "$LOG") 2>&1

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] missing: $1"; exit 2; }; }
for b in git jq; do need "$b"; done
command -v gh >/dev/null && HAS_GH=1 || HAS_GH=0

echo "[INFO] Verify tag reachability main←${VERSION}"
git fetch --tags origin >/dev/null 2>&1 || true
TAG_SHA="$(git rev-parse "${VERSION}")"
MAIN_SHA="$(git rev-parse origin/main || git rev-parse main)"
if git merge-base --is-ancestor "${TAG_SHA}" "${MAIN_SHA}"; then
  echo "[OK] ${VERSION} est atteint depuis main (main ⊇ tag)."
else
  echo "[WARN] ${VERSION} n'est pas sur main. Suggéré: créer PR pour fast-forward main -> ${TAG_SHA}."
fi

echo "[INFO] Check .zenodo.json related_identifiers & DOI in docs"
fail=0
test -f .zenodo.json && jq -e \
  --arg url "https://github.com/JeanPhilipLalumiere/MCGT/releases/tag/${VERSION}" \
  '([.related_identifiers[]?.identifier] // []) | index($url)' .zenodo.json >/dev/null || { echo "[WARN] .zenodo.json (racine) sans related_identifiers vers tag"; fail=1; }
grep -q "10.5281/zenodo.${DOI_ID}" CITATION.cff || { echo "[WARN] DOI absent CITATION.cff (racine)"; fail=1; }
grep -q "10.5281/zenodo.${DOI_ID}" README.md || { echo "[WARN] DOI absent README.md (racine)"; fail=1; }
test $fail -eq 0 && echo "[OK] DOI/related_identifiers OK."

echo "[INFO] Vérif assets release (si gh dispo)"
if [ ${HAS_GH:-0} -eq 1 ]; then
  gh release view "${VERSION}" --json url,assets | jq -r '.url, ([.assets[].name] // [])'
fi

echo "[INFO] Ajout export-ignore (idempotent) pour attic/logs"
ATTR=.gitattributes
touch "$ATTR"
bak="${ATTR}.bak_${STAMP}"
cp -f "$ATTR" "$bak"
add_line(){ grep -Fq "$1" "$ATTR" || printf "%s\n" "$1" >> "$ATTR"; }
add_line "_attic_untracked/** export-ignore"
add_line "_logs/** export-ignore"
add_line "release_zenodo_codeonly/** export-ignore"
if ! diff -q "$bak" "$ATTR" >/dev/null; then
  git add "$ATTR"
  git commit -m "chore: add export-ignore for attic/logs/release bundles"
  echo "[OK] .gitattributes mis à jour."
else
  echo "[OK] .gitattributes déjà correct."
fi

echo "[NEXT] Protection distante (à lancer si OK) :"
cat <<'EOF'
# Protéger la branche main (exemple strict, nécessite GH_TOKEN avec repo:admin)
gh api -X PUT repos/:owner/:repo/branches/main/protection \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1}' \
  -f restrictions='null' \
  -f allow_force_pushes=false \
  -f allow_deletions=false

# (Optionnel) Protéger les tags v*
gh api -X PUT repos/:owner/:repo/tags/protection \
  -H "Accept: application/vnd.github+json" \
  -f patterns='["v*"]'
EOF
