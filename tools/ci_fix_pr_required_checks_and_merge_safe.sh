#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE
set -u -o pipefail; set +e

PR="${1:-20}"            # Numéro PR (ex. 20)
BASE="${2:-main}"        # Branche de base (ex. main)

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

need(){ command -v "$1" >/dev/null 2>&1 || { err "Commande requise manquante: $1"; exit 0; }; }

need git; need gh; need jq

# --- Détection branche de la PR ---
BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)"
if [ -z "${BR:-}" ]; then err "Impossible d'obtenir la branche de la PR #$PR"; exit 0; fi
info "PR #$PR • base=$BASE • branch=$BR"

# --- Se placer sur la branche PR + se mettre à jour ---
git fetch origin >/dev/null 2>&1
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"
git pull --ff-only || true
# Mise à jour avec BASE (rebase 'clean', sinon merge)
if git merge-base --is-ancestor "origin/$BASE" HEAD; then
  ok "HEAD contient déjà origin/$BASE"
else
  info "Rebase sur origin/$BASE…"
  git rebase "origin/$BASE" || { warn "Rebase a échoué, tentative merge fast-forward"; git merge --no-edit "origin/$BASE" || true; }
fi

# --- Corriger/écrire le workflow secret-scan (canon minimal propre) ---
WF=.github/workflows/secret-scan.yml
mkdir -p .github/workflows
cat > "$WF" <<'YAML'
permissions:
  contents: read
name: secret-scan

on:
  workflow_dispatch:
  push:
    branches: ['**']
  pull_request:
    branches: ['**']

concurrency:
  group: secrets-${{ github.ref }}
  cancel-in-progress: false

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        with:
          args: detect --no-banner --source . --redact --report-format sarif --report-path gitleaks.sarif

      - name: Upload SARIF to code scanning
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: gitleaks.sarif
YAML
ok "secret-scan.yml écrit (job=gitleaks, pas de matrix/if, PR attach, no cancel)"

# --- S'assurer que pypi-build possède workflow_dispatch (relance manuelle) ---
PYP=.github/workflows/pypi-build.yml
if [ -f "$PYP" ] && ! grep -q 'workflow_dispatch' "$PYP"; then
  awk '1; /^on:/{print "  workflow_dispatch:"}' "$PYP" > _tmp.pypi-build.yml && mv _tmp.pypi-build.yml "$PYP"
  ok "Ajout de 'workflow_dispatch' dans pypi-build.yml"
else
  info "pypi-build.yml OK (workflow_dispatch présent ou fichier absent)"
fi

# --- Commit + push (crée un nouveau SHA pour attacher les checks requis) ---
git add "$WF" $PYP 2>/dev/null
git commit -m "ci(secret-scan): PR attach; no filters; no cancel; job=gitleaks; add dispatch to pypi-build if missing" >/dev/null 2>&1 || info "Rien à committer"
git push || true

HEAD_SHA="$(git rev-parse HEAD)"
ok "HEAD = $HEAD_SHA"

# --- Relance ciblée des 2 workflows requis ---
gh workflow run .github/workflows/pypi-build.yml  -r "$BR" >/dev/null 2>&1 || warn "dispatch pypi-build.yml impossible (pas de trigger?)"
gh workflow run .github/workflows/secret-scan.yml -r "$BR" >/dev/null 2>&1 || warn "dispatch secret-scan.yml impossible (pas de trigger?)"

# --- Poll des check-runs attachés au HEAD courant ---
REQ1="pypi-build/build"
REQ2="secret-scan/gitleaks"

info "Attente SUCCESS des contexts requis: $REQ1 | $REQ2"
MAX=60; SLEEP=10
seen_build=""; seen_leaks=""
for i in $(seq 1 $MAX); do
  JSON="$(gh api repos/:owner/:repo/commits/$HEAD_SHA/check-runs -H 'Accept: application/vnd.github+json' 2>/dev/null)"
  C_BUILD=$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="pypi-build/build" or .name=="build") | .conclusion' | tail -n1)
  C_GLKS=$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="secret-scan/gitleaks" or .name=="gitleaks") | .conclusion' | tail -n1)
  ST_BUILD="${C_BUILD:-<none>}"; ST_GLKS="${C_GLKS:-<none>}"
  printf "[%02d/%02d] pypi-build/build=%s ; secret-scan/gitleaks=%s\n" "$i" "$MAX" "$ST_BUILD" "$ST_GLKS"

  # Si secret-scan se fait "cancel", relance-le
  if [ "${ST_GLKS}" = "cancelled" ] && [ "$seen_leaks" != "bumped" ]; then
    warn "secret-scan cancelled → relance ciblée"
    gh workflow run .github/workflows/secret-scan.yml -r "$BR" >/dev/null 2>&1 || true
    seen_leaks="bumped"
  fi

  # Si build est null/<none>, laisse un peu de temps ; si 'cancelled', relance
  if [ "${ST_BUILD}" = "cancelled" ] && [ "$seen_build" != "bumped" ]; then
    warn "pypi-build cancelled → relance ciblée"
    gh workflow run .github/workflows/pypi-build.yml -r "$BR" >/dev/null 2>&1 || true
    seen_build="bumped"
  fi

  if [ "${ST_BUILD}" = "success" ] && [ "${ST_GLKS}" = "success" ]; then
    ok "Les deux checks requis sont SUCCESS sur le HEAD courant."
    break
  fi
  sleep "$SLEEP"
done

# --- Tentative merge (rebase) ---
info "Tentative de merge (rebase)…"
gh pr merge "$PR" --rebase --delete-branch && exit 0

warn "Merge CLI refusé. Possible policy 'strict up-to-date' pas reconnue par GH CLI."
warn "Essaye: gh pr merge --rebase --delete-branch --auto (si auto-merge activé) ou clique 'Rebase and merge' dans l'UI."
exit 0
