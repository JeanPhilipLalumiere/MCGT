#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[fix-exec] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[fix-exec] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Auto-fix trivials (EOF + trailing spaces)"
pre-commit run end-of-file-fixer -a || true
pre-commit run trailing-whitespace -a || true

echo "==> (2) Rendre exécutables tous les fichiers suivis avec shebang"
mapfile -d '' -t SHEBANGS < <(git ls-files -z | xargs -0 -r awk 'FNR==1 && /^#!/ {print FILENAME}' | sort -u | tr '\n' '\0')
if (( ${#SHEBANGS[@]} )); then
  chmod +x "${SHEBANGS[@]}" || true
  git add --chmod=+x "${SHEBANGS[@]}" || true
else
  echo "Aucun fichier shebang à corriger."
fi

# (2b) Auto-corriger ce script lui-même s'il n'était pas encore suivi/exécutable
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -f "$SCRIPT_PATH" ]]; then
  chmod +x "$SCRIPT_PATH" || true
  git add --chmod=+x "$SCRIPT_PATH" || true
fi

echo "==> (3) S’assurer de legacy-tex export-ignore + (optionnel) .gitignore"
grep -q -E '^[[:space:]]*legacy-tex[[:space:]]+export-ignore[[:space:]]*$' .gitattributes 2>/dev/null || echo "legacy-tex export-ignore" >> .gitattributes
grep -q -E '^legacy-tex/$' .gitignore 2>/dev/null || echo "legacy-tex/" >> .gitignore

echo "==> (4) pre-commit complet (tolérant)"
pre-commit run --all-files || true

echo "==> (5) Commit & push si diff"
git add -A
git commit -m "chore: fix exec bits on shebang scripts; apply whitespace fixes; legacy-tex export-ignore/gitignore" || true
git push || true
