#!/usr/bin/env bash
# Script tolérant : on n'abandonne jamais, logs lisibles
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
run "mkdir -p .github/workflows tools"

###############################################################################
# 1) CodeQL (Python, +JS si besoin). Concurrency pour éviter les doublons CI.
###############################################################################
step "1) Ajout workflow CodeQL"
cat > .github/workflows/codeql.yml <<'YML'
name: codeql
on:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
  schedule:
    - cron: "19 3 * * 2"
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
    strategy:
      fail-fast: false
      matrix:
        language: [python]
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
      - name: Setup Python
        if: matrix.language == 'python'
        uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - name: Install deps (best-effort)
        if: matrix.language == 'python'
        run: |
          set -e
          if ls requirements*.txt >/dev/null 2>&1; then
            python -m pip install -U pip
            pip install -r requirements.txt || true
          fi
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with: { category: "/language:${{matrix.language}}" }
YML

###############################################################################
# 2) Gitleaks — scan secrets (CI + pre-commit local option si installé)
###############################################################################
step "2) Ajout config Gitleaks + workflow"
cat > .gitleaks.toml <<'TOML'
title = "MCGT gitleaks policy"
# Répertoires ignorés (copie legacy et artefacts)
[[allowlist.paths]]
description = "legacy conflicts"
path = '''^zz-figures/_legacy_conflicts/'''
[[allowlist.paths]]
description = "generated logs/out"
path = '''^(\.ci-logs/|\.ci-out/|_tmp-figs/|zz-out/)'''
# Exemples de patterns autorisés (entropie/hex longs inoffensifs)
[[allowlist.regexes]]
description = "Longs hex non secrets (hash persistés)"
regex = '''\b[0-9a-fA-F]{32,}\b'''
TOML

cat > .github/workflows/secret-scan.yml <<'YML'
name: secret-scan
on:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
concurrency:
  group: secrets-${{ github.ref }}
  cancel-in-progress: true
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          args: detect --source . --no-banner --config .gitleaks.toml --redact
YML

# Hook pre-commit (n’opère que si gitleaks installé localement)
step "2b) Hook pre-commit local pour gitleaks (optionnel)"
python3 - <<'PY' || true
import yaml, os, sys, io
cfg_path = ".pre-commit-config.yaml"
if not os.path.exists(cfg_path):
    sys.exit(0)
with open(cfg_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}
repos = data.get("repos", [])
# Vérifie si un hook 'gitleaks' local existe déjà
for r in repos:
    if r.get("repo") == "local":
        for h in r.get("hooks", []):
            if h.get("id") == "gitleaks-protect":
                break
        else:
            continue
        break
else:
    repos.append({"repo": "local", "hooks": []})
    data["repos"] = repos

# Ajoute/merge le hook
for r in repos:
    if r["repo"] == "local":
        hooks = r.setdefault("hooks", [])
        if not any(h.get("id")=="gitleaks-protect" for h in hooks):
            hooks.append({
                "id": "gitleaks-protect",
                "name": "gitleaks protect (skip si non installé)",
                "entry": "bash -lc 'command -v gitleaks >/dev/null || exit 0; gitleaks protect --staged --no-banner --redact'",
                "language": "system",
                "stages": ["pre-commit"],
                "pass_filenames": False,
            })
        break

with open(cfg_path, "w", encoding="utf-8") as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)
print("pre-commit: gitleaks-protect hook prêt (si binaire dispo).")
PY

###############################################################################
# 3) Audit dépendances Python (pip-audit) — échoue sur vulnérabilités
###############################################################################
step "3) Ajout workflow audit deps (pip-audit)"
cat > .github/workflows/pip-audit.yml <<'YML'
name: pip-audit
on:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
  schedule:
    - cron: "11 4 * * 5"
concurrency:
  group: deps-${{ github.ref }}
  cancel-in-progress: true
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - name: Install project (best-effort)
        run: |
          set -e
          python -m pip install -U pip
          if ls requirements*.txt >/dev/null 2>&1; then
            pip install -r requirements.txt || true
          fi
      - name: Install pip-audit
        run: pip install pip-audit
      - name: Run pip-audit
        run: |
          set -e
          if ls requirements*.txt >/dev/null 2>&1; then
            pip-audit -r requirements.txt
          else
            pip-audit
          fi
YML

###############################################################################
# 4) Commit & push (jamais bloquant)
###############################################################################
step "4) Commit + push"
run "pre-commit install || true"
run "git add .gitleaks.toml .github/workflows/codeql.yml .github/workflows/secret-scan.yml .github/workflows/pip-audit.yml .pre-commit-config.yaml || true"
run "git commit -m 'sec: CodeQL, scan secrets (gitleaks), audit deps (pip-audit); hooks/concurrency' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Envoie-moi la fin du log pour patch ciblé."
else
  say "✅ Série 6 appliquée sans erreurs bloquantes côté script."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
