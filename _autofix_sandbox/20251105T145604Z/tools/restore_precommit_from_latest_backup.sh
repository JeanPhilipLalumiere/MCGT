#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[restore-precommit] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[restore-precommit] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Cherche le backup le plus récent"
latest="$(ls -1t .pre-commit-config.yaml.bak.* 2>/dev/null | head -n1 || true)"
if [[ -z "${latest}" ]]; then
  echo "Aucun backup *.bak.* trouvé. Restauration depuis HEAD…"
  if git cat-file -e HEAD:.pre-commit-config.yaml 2>/dev/null; then
    git show HEAD:.pre-commit-config.yaml > .pre-commit-config.yaml
  else
    echo "ERREUR: impossible de retrouver une config de secours." >&2
    exit 1
  fi
else
  echo "Backup le plus récent: ${latest}"
  cp -f "${latest}" .pre-commit-config.yaml
fi

# (optionnel mais utile) Assure l’hygiène autour de .ci-out
echo "==> (2) Hygiène .ci-out (export-ignore + gitignore)"
GITATTR=".gitattributes"
[[ -f "$GITATTR" ]] || : > "$GITATTR"
# Ajoute une NL si le fichier ne se termine pas par \n
if [[ -s "$GITATTR" ]] && [[ "$(tail -c1 "$GITATTR" || true)" != $'\n' ]]; then echo >> "$GITATTR"; fi
if ! grep -qE '^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$' "$GITATTR"; then
  echo ".ci-out export-ignore" >> "$GITATTR"
  echo "INFO: ajouté à .gitattributes : '.ci-out export-ignore'"
else
  echo "INFO: déjà présent dans .gitattributes"
fi

GITIGN=".gitignore"
[[ -f "$GITIGN" ]] || : > "$GITIGN"
if ! grep -qE '^[[:space:]]*\.ci-out/[[:space:]]*$' "$GITIGN"; then
  echo ".ci-out/" >> "$GITIGN"
  echo "INFO: ajouté à .gitignore : '.ci-out/'"
else
  echo "INFO: déjà présent dans .gitignore"
fi
git rm -r --cached .ci-out 2>/dev/null || true

echo "==> (3) Valide la config et exécute pre-commit (tolérant)"
if pre-commit validate-config; then
  pre-commit run --all-files || true
else
  echo "ATTENTION: .pre-commit-config.yaml invalide — ouvre le fichier pour corriger." >&2
fi

echo "==> (4) Commit & push si diff"
git add .pre-commit-config.yaml "$GITATTR" "$GITIGN" || true
if ! git diff --cached --quiet; then
  git commit -m "revert(pre-commit): restore previous config; ensure .ci-out export-ignore & gitignore"
  git push || true
else
  echo "Rien à committer"
fi

echo "✅ Restauration terminée."
