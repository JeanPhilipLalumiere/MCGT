#!/usr/bin/env bash
# Script tolérant : jamais d'abandon, toujours lisible
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts() { date +"%Y-%m-%d %H:%M:%S"; }
say(){ echo -e "[$(ts)] $*"; }
run(){ say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p .github/ISSUE_TEMPLATE .github/workflows tools"

step "1) Durcir .gitattributes (export-ignore + binaires + EOL)"
# Ajouts idempotents
add_line() {
  local file="$1"; shift
  local line="$*"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}
[ -f .gitattributes ] || : > .gitattributes
add_line .gitattributes "*.png binary"
add_line .gitattributes "*.jpg binary"
add_line .gitattributes "*.jpeg binary"
add_line .gitattributes "*.gif binary"
add_line .gitattributes "*.npz binary"
add_line .gitattributes "*.gz  binary"
add_line .gitattributes "*.pdf binary"
add_line .gitattributes "* text=auto eol=lf"
add_line .gitattributes "zz-figures/_legacy_conflicts/ export-ignore"
add_line .gitattributes "zz-figures/_legacy_conflicts/** -diff"

step "2) CODEOWNERS"
cat > .github/CODEOWNERS <<'OWN'
# Propriétaires par défaut
* @JeanPhilipLalumiere
OWN

step "3) Modèles PR & Issues"
cat > .github/PULL_REQUEST_TEMPLATE.md <<'PR'
## Objet
- [ ] Description claire du changement
- [ ] Type (feat | fix | chore | docs | ci | refactor | test | perf)

## Vérifications
- [ ] Pre-commit passe en local (`pre-commit run -a`)
- [ ] CI verte
- [ ] Pas de fichiers générés suivis

## Liens
Closes #
PR
cat > .github/ISSUE_TEMPLATE/bug_report.yml <<'YML'
name: Bug
description: Signaler un bug
labels: [bug]
body:
  - type: textarea
    id: what
    attributes: { label: "Que se passe-t-il ?", description: "Comportement observé vs attendu" }
    validations: { required: true }
  - type: textarea
    id: repro
    attributes: { label: "Reproduction", description: "Étapes, logs, versions" }
    validations: { required: true }
YML
cat > .github/ISSUE_TEMPLATE/feature_request.yml <<'YML'
name: Feature
description: Proposer une amélioration
labels: [enhancement]
body:
  - type: textarea
    id: value
    attributes: { label: "Valeur", description: "Pourquoi c'est utile ?" }
    validations: { required: true }
  - type: textarea
    id: scope
    attributes: { label: "Portée", description: "Critères d'acceptation" }
YML

step "4) Release Drafter (changelog auto sur PR merge)"
cat > .github/release-drafter.yml <<'YML'
name-template: "v$NEXT_PATCH_VERSION"
tag-template: "v$NEXT_PATCH_VERSION"
categories:
  - title: ✨ Features
    labels: [feat, feature, enhancement]
  - title: 🐛 Fixes
    labels: [fix, bug]
  - title: 🧰 Maintenance
    labels: [chore, ci, deps, refactor]
change-template: "- $TITLE (#$NUMBER) by @$AUTHOR"
template: |
  ## Changements
  $CHANGES
YML
cat > .github/workflows/release-drafter.yml <<'YML'
name: release-drafter
on:
  push:
    branches: [main, master]
  pull_request:
    types: [opened, synchronize, reopened, closed]
jobs:
  update_release_draft:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: release-drafter/release-drafter@v6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
YML

step "5) Dependabot (MAJ actions hebdo)"
cat > .github/dependabot.yml <<'YML'
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
YML

step "6) Vérif titre de PR (Conventional Commits) + Concurrency"
cat > .github/workflows/semantic-pr.yml <<'YML'
name: semantic-pr
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
concurrency:
  group: semantic-${{ github.ref }}
  cancel-in-progress: true
jobs:
  semantic:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            chore,ci,docs,feat,fix,perf,refactor,revert,style,test
          requireScope: false
          validateSingleCommit: false
YML

step "7) .git-blame-ignore-revs (ignorer les commits massifs de ménage)"
cat > .git-blame-ignore-revs <<'REV'
# Commits de ménage format/CI à ignorer dans blame
dc77ba8 ci(integrity,pdf): manifeste robuste…
1963600 ci(budgets): fix PermissionError…
51367d7 chore(ci,pre-commit): gardes générés…
262bc11 ci: fix gardes, ajouter CI…
b7ee6ba data: add .gz copies…
adff886 chore: untrack generated…
6ded4e6 chore: ignore generated outputs…
REV
git config blame.ignoreRevsFile .git-blame-ignore-revs || true

step "8) Renforcement CI existante : rendre les jobs non redondants"
# Ajout 'concurrency' si absent (idempotent) dans workflows principaux
for wf in .github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  if ! grep -q '^concurrency:' "$wf"; then
    # insérer après 'on:' (simple et robuste)
    awk '{
      print $0
      if($0 ~ /^on:/ && !injected){ print "concurrency:\n  group: " FILENAME "-${{ github.ref }}\n  cancel-in-progress: true"; injected=1 }
    }' "$wf" > "$wf.tmp" && mv "$wf.tmp" "$wf" || true
  fi
done

step "9) Commit + push (jamais bloquant)"
run "git add .gitattributes .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md .github/ISSUE_TEMPLATE/*.yml .github/release-drafter.yml .github/workflows/release-drafter.yml .github/dependabot.yml .github/workflows/semantic-pr.yml .git-blame-ignore-revs .github/workflows/*.yml || true"
run "git commit -m 'chore(ci,meta): CODEOWNERS, templates PR/issue, release-drafter, dependabot, semantic PR, concurrency, gitattributes durci, blame-ignore' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Renvoyez-moi le log pour patch ciblé."
else
  say "✅ Série 5 appliquée sans erreurs bloquantes côté script."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
