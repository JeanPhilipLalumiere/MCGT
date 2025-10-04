#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[enforce-eol] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[enforce-eol] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Met à jour .gitattributes (EOL = LF, idempotent)"
touch .gitattributes
add_attr(){ local line="$1"; grep -qxF "$line" .gitattributes 2>/dev/null || echo "$line" >> .gitattributes; }

add_attr "* text=auto eol=lf"
for ext in sh py yml yaml md json ini toml csv tex; do
  add_attr "*.${ext} text eol=lf"
done
# Conserver nos règles d'export-ignore utiles
add_attr "legacy-tex export-ignore"
add_attr "zz-configuration/parameters_registry.json export-ignore"

git add .gitattributes

echo "==> (2) Renormalise les fins de ligne dans l'index (peut prendre quelques secondes)"
git add --renormalize .

echo "==> (3) pre-commit (tolérant) pour auto-fixes"
pre-commit run --all-files || true

echo "==> (4) Commit & push si nécessaire"
if ! git diff --cached --quiet; then
  git commit -m "chore(eol): enforce LF via .gitattributes; renormalize"
  git push
else
  echo "Aucun changement à committer."
fi

echo "==> (5) Vérif schémas rapide (tolérant)"
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh || true
