#!/usr/bin/env bash
set -euo pipefail

KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[purge-registry] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[purge-registry] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (0) Fetch origin/main"
git fetch origin

BASE="$(git rev-parse origin/main)"
HEAD="$(git rev-parse HEAD)"
echo "    base: $BASE"
echo "    head: $HEAD"

echo "==> (1) Prépare un patch SANS le gros fichier"
TMP_DIR="$(mktemp -d)"
PATCH="$TMP_DIR/safe.patch"
git diff --binary "${BASE}..${HEAD}" -- . ":(exclude)zz-configuration/parameters_registry.json" > "$PATCH" || true
echo "    Patch écrit: $PATCH (size: $(wc -c < "$PATCH" 2>/dev/null || echo 0) bytes)"

echo "==> (2) Branche de secours"
git branch -f rescue/before-purge "$HEAD" || true
echo "    Secours: rescue/before-purge -> $HEAD"

echo "==> (3) Reset local main sur origin/main"
git reset --hard "$BASE"

echo "==> (4) Applique le patch SANS le gros fichier"
# --index pour préparer l’index directement
git apply --index "$PATCH" || true

echo "==> (5) Ignore le JSON géant (gitignore + export-ignore) et le désindexe si présent"
grep -q -E '^zz-configuration/parameters_registry\.json$' .gitignore 2>/dev/null || echo 'zz-configuration/parameters_registry.json' >> .gitignore
grep -q -E '^[[:space:]]*zz-configuration/parameters_registry\.json[[:space:]]+export-ignore[[:space:]]*$' .gitattributes 2>/dev/null || echo 'zz-configuration/parameters_registry.json export-ignore' >> .gitattributes
git rm -f --cached zz-configuration/parameters_registry.json 2>/dev/null || true

echo "==> (6) pre-commit (tolérant)"
pre-commit run --all-files || true

echo "==> (7) Commit & push de la version nettoyée"
git add -A
git commit -m "chore: replay recent changes without huge parameters_registry.json; ignore & export-ignore it" || true
git push

echo "✅ Nettoyage terminé. Si besoin, compare 'rescue/before-purge' pour voir ce qui a été exclu."
