#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; if ((code!=0)); then echo; echo "[ERREUR] Sortie avec code $code"; fi' EXIT

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Vérifs repo
have git || { err "git manquant"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { err "Pas dans un dépôt Git."; exit 1; }

BRANCH_CUR="$(git rev-parse --abbrev-ref HEAD)"
DEFAULT_BRANCH="$( (have gh && gh repo view --json defaultBranchRef -q .defaultBranchRef.name) || git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}' || echo main )"

mkdir -p .github/workflows constraints

# 0) Constraints neutre (laisser vide pour l’instant, prêt à pinner si besoin)
if [[ ! -f constraints/security-pins.txt ]]; then
  info "Création constraints/security-pins.txt (neutre)"
  cat > constraints/security-pins.txt <<'TXT'
# constraints/security-pins.txt
# Ajoutez ici des pins si nécessaire, ex. :
# pip-audit==2.7.*
# certifi==2024.8.30
TXT
fi

ts="$(date -u +%Y%m%dT%H%M%SZ)"

# 1) Sauvegardes
for f in .github/workflows/pip-audit.yml .github/workflows/codeql.yml; do
  if [[ -f "$f" ]]; then
    cp -f "$f" "$f.bak.$ts"
  fi
done

# 2) Écrire versions canoniques, propres
cat > .github/workflows/pip-audit.yml <<'YAML'
name: pip-audit
on:
  workflow_dispatch:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
  schedule:
    - cron: "11 4 * * 5"
permissions:
  contents: read
concurrency:
  group: deps-${{ github.ref }}
  cancel-in-progress: true
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Install project (best-effort)
        env:
          PIP_CONSTRAINT: constraints/security-pins.txt
        run: |
          python -m pip install -U pip -c "$PIP_CONSTRAINT"
          if [ -f requirements.txt ]; then
            pip install -r requirements.txt -c "$PIP_CONSTRAINT" || true
          fi
          if [ -f requirements-dev.txt ]; then
            pip install -r requirements-dev.txt -c "$PIP_CONSTRAINT" || true
          fi
      - name: Install pip-audit
        env:
          PIP_CONSTRAINT: constraints/security-pins.txt
        run: pip install pip-audit -c "$PIP_CONSTRAINT"
      - name: Run pip-audit
        run: |
          if [ -f requirements.txt ]; then
            if [ -f requirements-dev.txt ]; then
              pip-audit --progress-spinner off -r requirements.txt -r requirements-dev.txt
            else
              pip-audit --progress-spinner off -r requirements.txt
            fi
          else
            pip-audit --progress-spinner off
          fi
YAML

cat > .github/workflows/codeql.yml <<'YAML'
name: codeql
on:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
  schedule:
    - cron: "19 3 * * 2"
permissions:
  contents: read
concurrency:
  group: codeql-${{ github.ref }}
  cancel-in-progress: true
jobs:
  analyze:
    name: Analyze (CodeQL)
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: python
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Install deps (best-effort)
        env:
          PIP_CONSTRAINT: constraints/security-pins.txt
        run: |
          if [ -f requirements.txt ]; then
            python -m pip install -U pip -c "$PIP_CONSTRAINT"
            pip install -r requirements.txt -c "$PIP_CONSTRAINT" || true
          fi
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with:
          category: "/language:python"
YAML

# 3) Commit + push si diff
if ! git diff --quiet -- .github/workflows/pip-audit.yml .github/workflows/codeql.yml constraints/security-pins.txt; then
  info "Commit des workflows canoniques…"
  git add .github/workflows/pip-audit.yml .github/workflows/codeql.yml constraints/security-pins.txt
  git commit -m "ci: canonize pip-audit (constraints + spinner off) & tidy CodeQL (concurrency, deps)"
  git push
else
  info "Aucun changement détecté (déjà propre)."
fi

# 4) Dispatch sur branche courante et branche par défaut (si gh présent)
if have gh; then
  info "Dispatch pip-audit sur $BRANCH_CUR"
  gh workflow run .github/workflows/pip-audit.yml -r "$BRANCH_CUR" || warn "Dispatch pip-audit ($BRANCH_CUR) a échoué"
  info "Dispatch codeql sur $BRANCH_CUR"
  gh workflow run .github/workflows/codeql.yml -r "$BRANCH_CUR" || warn "Dispatch codeql ($BRANCH_CUR) a échoué"

  if [[ "$DEFAULT_BRANCH" != "$BRANCH_CUR" ]]; then
    info "Dispatch pip-audit sur $DEFAULT_BRANCH"
    gh workflow run .github/workflows/pip-audit.yml -r "$DEFAULT_BRANCH" || warn "Dispatch pip-audit ($DEFAULT_BRANCH) a échoué"
    info "Dispatch codeql sur $DEFAULT_BRANCH"
    gh workflow run .github/workflows/codeql.yml -r "$DEFAULT_BRANCH" || warn "Dispatch codeql ($DEFAULT_BRANCH) a échoué"
  fi
else
  warn "'gh' non disponible : déclenchement manuel requis si besoin."
fi

# 5) Aperçu (1..120)
for f in .github/workflows/pip-audit.yml .github/workflows/codeql.yml; do
  echo "──────── $f (aperçu 1..120)"
  nl -ba "$f" | sed -n '1,120p' | sed 's/^/    /'
done

info "Terminé."
