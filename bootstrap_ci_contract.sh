#!/usr/bin/env bash
# bootstrap_ci_contract.sh — crée/MAJ le document "Contrat CI" et ouvre une PR
# - Ne touche qu'aux fichiers docs/
# - Garde-fou: n'écrase rien d'autre; garde la fenêtre ouverte à la fin
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs docs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/bootstrap_ci_contract_${TS}.log"

say(){ echo -e "$*" | tee -a "$LOG" ; }

say "[INFO] Branche de travail"
git fetch origin >/dev/null 2>&1 || true
git switch main >/dev/null 2>&1
git pull --ff-only || true
git switch -c chore/ci-contract || git switch chore/ci-contract

DOC=docs/README-CI.md
say "[INFO] Écrit/Met à jour ${DOC}"

cat > "$DOC" <<'MD'
# Contrat CI — MCGT

## Checks **requis** sur `main`
- **pypi-build/build** — job `build` dans `.github/workflows/pypi-build.yml`
- **secret-scan/gitleaks** — workflow `secret-scan.yml` (SARIF normalisé)

### Déclencheurs attendus
- `pypi-build.yml` : `on: [pull_request, workflow_dispatch]` et `push: main` (facultatif si utile)
- `secret-scan.yml` : `on: [pull_request, workflow_dispatch]` (ou `schedule` si configuré)

## Politique de merge et protections
- **Méthode** : `--squash` (historique linéaire)
- **Linear history** : activé
- **Reviews** : **min. 1** approbation
- **Conversation resolution** : **obligatoire**
- **Required status checks** : uniquement `pypi-build/build` et `secret-scan/gitleaks`

## Conventions
- **Nom de job** pour build : `build` (obligatoire, pour stabiliser le contexte)
- Les autres workflows (budgets/guard/semantic/audit/…) : **non requis** par défaut
- Pas de secrets en clair; rapports sécurité au format SARIF si applicable

## Maintenance
- Tout changement de contexts requis → **PR dédiée** modifiant ce document
- Commandes utiles :
  - `gh run list --branch main --limit 10`
  - `gh workflow run pypi-build.yml --ref main`
  - `gh api repos/:owner/:repo/branches/main/protection`
MD

git add "$DOC"
if ! git diff --cached --quiet; then
  git commit -m "docs(ci): Contrat CI — checks requis, merge policy, conventions"
  git push -u origin HEAD
  say "[INFO] Ouverture PR…"
  gh pr create --fill || say "[WARN] Ouverture PR via CLI a échoué — ouvre-la dans l’UI."
else
  say "[SKIP] Aucun changement à committer."
fi

say "[NEXT] Vérifie que seuls les 2 checks restent requis; marque les autres comme non requis si besoin."
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
