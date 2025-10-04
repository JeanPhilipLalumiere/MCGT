#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# 0) S'assurer que .ci-out/ est ignoré côté Git
grep -qxF '.ci-out/' .gitignore 2>/dev/null || echo '.ci-out/' >> .gitignore
git add .gitignore

# 1) Patch du guard pour écrire dans .ci-out/parameters_registry.json
f="tools/ci_step9_parameters_registry_guard.sh"
[[ -f "$f" ]] || { echo "introuvable: $f"; exit 1; }

# Remplace le chemin de sortie du registre dans le script (ligne REGISTRY = …)
perl -0777 -pe 's|(REGISTRY\s*=\s*ROOT/")zz-configuration(")/"parameters_registry\.json"|$1.ci-out$2/"parameters_registry.json"|s' -i "$f"
# Et ajuste les occurrences textuelles éventuelles
sed -i 's#zz-configuration/parameters_registry.json#.ci-out/parameters_registry.json#g' "$f"

# 2) Exécute le guard pour (re)générer le registre dans .ci-out (tolérant)
KEEP_OPEN=0 bash "$f" || true

# 3) Hooks, commit, push
pre-commit run --all-files || true
git add "$f"
git commit -m "ci: redirect parameters_registry.json output to .ci-out (non-versionné)" || true
git push || true
