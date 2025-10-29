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
