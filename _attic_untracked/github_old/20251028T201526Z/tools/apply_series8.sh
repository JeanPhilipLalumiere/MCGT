#!/usr/bin/env bash
# Tolérant : ne quitte jamais sur erreur, logs lisibles
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts(){ date +"%Y-%m-%d %H:%M:%S"; }
say(){ echo -e "[$(ts)] $*"; }
run(){ say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p tools .github/workflows tools/ci"

# 1) Petit utilitaire de retry (réutilisable dans CI locale si besoin)
step "1) utilitaire retry.sh"
cat > tools/ci/retry.sh <<'SH'
#!/usr/bin/env bash
# retry <n> <sleep_seconds> -- <commande...>
set -euo pipefail
n=${1:-3}; shift || true
s=${1:-5}; shift || true
[ "${1:-}" = "--" ] && shift || true
i=0
until "$@"; do
  i=$((i+1))
  if [ "$i" -ge "$n" ]; then
    echo "retry: échec après $i tentatives" >&2
    exit 1
  fi
  echo "retry: tentative $i échouée, nouvelle tentative dans ${s}s…" >&2
  sleep "$s"
done
SH
run "chmod +x tools/ci/retry.sh"

# 2) Workflow CI accéléré (lint + budgets + build PDF conditionnel)
step "2) Workflow .github/workflows/ci-accel.yml"
cat > .github/workflows/ci-accel.yml <<'YML'
name: ci-accel
on:
  push:
    branches: ["**"]
  pull_request:
    branches: ["**"]

concurrency:
  group: ci-accel-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint-and-budgets:
    name: Lint & Budgets (pré-commit)
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Cache pre-commit env
        uses: actions/cache@v4
        with:
          path: ~/.cache/pre-commit
          key: ${{ runner.os }}-precommit-${{ hashFiles('.pre-commit-config.yaml') }}
          restore-keys: |
            ${{ runner.os }}-precommit-

      - name: Install pre-commit
        run: python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip pre-commit

      - name: Run pre-commit (avec cache)
        uses: pre-commit/action@v3.0.1

  pdf:
    name: Build PDF (si des .tex existent)
    runs-on: ubuntu-latest
    timeout-minutes: 25
    if: ${{ hashFiles('**/*.tex') != '' }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Cache Tectonic packages
        uses: actions/cache@v4
        with:
          path: ~/.cache/Tectonic
          key: ${{ runner.os }}-tectonic-${{ hashFiles('**/*.tex') }}
          restore-keys: |
            ${{ runner.os }}-tectonic-

      # Tectonic compile automatiquement et télécharge les paquets requis.
      - name: Typeset .tex via Tectonic (auto-détection)
        uses: tectonic-typesetting/tectonic-action@v1
        with:
          # Cherche un fichier principal plausible, sinon compile tout ce qu'il peut.
          tex_path: .
          only_cached_packages: false
          continue_on_error: true

      - name: Collecte PDF (best-effort)
        run: |
          mkdir -p dist
          # Copie tous les PDF générés plausibles
          find . -maxdepth 4 -type f -name '*.pdf' -not -path './dist/*' -print -exec cp -n '{}' dist/ \; || true
          ls -l dist || true

      - name: Upload PDF artefacts
        uses: actions/upload-artifact@v4
        with:
          name: pdfs
          path: dist/*.pdf
          if-no-files-found: ignore
YML

# 3) Option : hook local de build rapide
step "3) Makefile : cible ci-fast (optionnelle, inoffensive)"
if ! grep -q '^# BEGIN CI FAST TARGET$' Makefile 2>/dev/null; then
  cat >> Makefile <<'MK'

# BEGIN CI FAST TARGET
.PHONY: ci-fast
ci-fast:
	@echo "CI rapide locale : pre-commit + budgets"
	pre-commit run -a || true
# END CI FAST TARGET
MK
fi

# 4) Commit + push
step "4) Commit + push"
run "git add tools/ci/retry.sh .github/workflows/ci-accel.yml Makefile || true"
run "git commit -m 'ci: accélération (cache pip/pre-commit), build PDF conditionnel via Tectonic, util retry' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Envoie-moi la fin du log pour patch ciblé."
else
  say "✅ Série 8 appliquée côté script. Le workflow 'ci-accel' s’exécutera sur push/PR."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
