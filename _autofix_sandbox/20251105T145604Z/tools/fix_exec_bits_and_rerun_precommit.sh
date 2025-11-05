#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[exec-bits] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[exec-bits] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Corrige les bits exécutables sur tous les fichiers shebang"
fixed=0
while IFS= read -r -d $'\0' f; do
  [[ -f "$f" ]] || continue
  # plus robuste que `head -n1` (évite les rc inattendus)
  if LC_ALL=C read -r firstline <"$f" && [[ "$firstline" =~ ^#! ]]; then
    if [[ ! -x "$f" ]]; then
      chmod +x "$f"
      git add --chmod=+x "$f" || git add "$f"
      ((++fixed))
    fi
  fi
done < <(git ls-files -z)
printf "Fichiers corrigés: %d\n" "$fixed"

echo "==> (2) Pré-commit (tolérant, 2 passes)"
pre-commit install || true
pre-commit run --all-files || true
pre-commit run --all-files || true

echo "==> (3) Commit/push si nécessaire"
if ! git diff --quiet; then
  git add -A
  git commit -m "chore: set exec bits on shebang scripts; apply pre-commit fixes"
  git push
else
  echo "Aucun changement à committer."
fi
