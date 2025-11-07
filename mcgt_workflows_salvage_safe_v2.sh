# ~/MCGT/mcgt_workflows_salvage_safe_v2.sh
#!/usr/bin/env bash
# Répare proprement 3 workflows (pre-commit-autoupdate, audit, publish)
# Valide avec actionlint (sans lui passer un répertoire)
# GARDE-FOU : la fenêtre reste ouverte en fin de script (succès/erreur).

set -Eeuo pipefail
shopt -s nullglob

# ---------- GARDE-FOU : pause avant sortie ----------
PAUSE_MSG_OK=${PAUSE_MSG_OK:-$'\n✅ Terminé. Appuie sur Entrée pour fermer cette fenêtre…'}
PAUSE_MSG_ERR=${PAUSE_MSG_ERR:-$'\n❌ Une erreur est survenue. Consulte le log.\nAppuie sur Entrée pour fermer cette fenêtre…'}

pause_always() {
  { echo -ne "$1"
    if [ -t 0 ]; then read -r _; else
      if [ -e /dev/tty ]; then read -r _ </dev/tty; else sleep 15; fi
    fi
  } || true
}

LOG_DIR="/tmp/mcgt_workflows_salvage_$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run.log"
exec > >(tee -a "$LOG") 2>&1

on_error() {
  code=$?
  echo -e "\n--- TRACEBACK (exit $code) ---"
  echo "Script        : $0"
  echo "Log           : $LOG"
  echo "TMP dir       : $LOG_DIR"
  echo "Branche git   : $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  git --no-pager log --oneline -n 5 || true
  pause_always "$PAUSE_MSG_ERR"
  exit $code
}
trap on_error ERR
trap 'pause_always "$PAUSE_MSG_OK"' EXIT

echo "# --- Contexte ---"
echo "PWD          : $(pwd)"
echo "LOG          : $LOG"
echo "TMP/LOG DIR  : $LOG_DIR"

git rev-parse --is-inside-work-tree >/dev/null
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
echo "Repo root    : $REPO_ROOT"
echo "Branche      : $(git rev-parse --abbrev-ref HEAD)"

mkdir -p .github/workflows

# ---------- Installer actionlint si absent ----------
ACTIONLINT="${HOME}/.local/bin/actionlint"
if ! command -v "$ACTIONLINT" >/dev/null 2>&1; then
  echo "# actionlint non présent, installation locale…"
  mkdir -p "${HOME}/.local/bin"
  curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash \
    -o "$LOG_DIR/download-actionlint.bash"
  bash "$LOG_DIR/download-actionlint.bash" latest "${HOME}/.local/bin"
  chmod +x "${HOME}/.local/bin/actionlint" || true
fi
"$ACTIONLINT" -version

# ---------- Chemins temporaires ----------
TMP1="$LOG_DIR/pre-commit-autoupdate.yml.tmp"
TMP2="$LOG_DIR/audit.yml.tmp"
TMP3="$LOG_DIR/publish.yml.tmp"

# ---------- Contenus propres ----------
cat > "$TMP1" <<'YAML'
name: pre-commit autoupdate

on:
  schedule:
    - cron: '0 5 * * 1'  # Lundi 05:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  autoupdate:
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install pre-commit
        run: python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install --upgrade pip pre-commit

      - name: Run pre-commit autoupdate
        run: pre-commit autoupdate

      - name: Commit changes (if any)
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout -B ci/pre-commit-autoupdate
          git add -A
          git commit -m "chore(pre-commit): autoupdate" || echo "no changes"

      - name: Create PR
        uses: peter-evans/create-pull-request@v7
        with:
          branch: ci/pre-commit-autoupdate
          title: "chore(pre-commit): autoupdate"
          commit-message: "chore(pre-commit): autoupdate"
          body: "Weekly pre-commit autoupdate"
          delete-branch: true
YAML

cat > "$TMP2" <<'YAML'
name: audit

on:
  workflow_dispatch:
  pull_request:
    paths:
      - ".github/workflows/audit.yml"
      - "tools/pip_audit_runtime.sh"
      - "requirements*.txt"
      - "pyproject.toml"
  push:
    branches:
      - "fix/audit-on-main-*"

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  audit:
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: pip-audit (JSON + summary)
        run: bash tools/pip_audit_runtime.sh

      - name: Upload audit.json
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: audit-json
          path: audit.json
          if-no-files-found: ignore
YAML

cat > "$TMP3" <<'YAML'
name: Build & Publish

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Build sdist+wheel
        run: |
          python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install --upgrade pip build
          python -m build

      - name: Show dist tree
        run: |
          python - <<'PY'
          import pathlib
          p = pathlib.Path('dist')
          print('DIST CONTENTS:')
          for x in sorted(p.glob('*')):
              print(' -', x, x.stat().st_size, 'bytes')
          PY

      - name: Upload dist
        uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist

  publish:
    needs: build
    runs-on: ubuntu-24.04
    environment: pypi
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist
      - name: Publish to PyPI (trusted publisher)
        uses: pypa/gh-action-pypi-publish@v1.10.1
        with:
          packages-dir: dist
YAML

# ---------- Validation des fichiers temporaires (unitaires) ----------
echo "# Validation actionlint (fichiers temporaires)…"
"$ACTIONLINT" -color -shellcheck= -pyflakes= "$TMP1"
"$ACTIONLINT" -color -shellcheck= -pyflakes= "$TMP2"
"$ACTIONLINT" -color -shellcheck= -pyflakes= "$TMP3"

# ---------- Remplacement atomique ----------
install -m 0644 "$TMP1" ".github/workflows/pre-commit-autoupdate.yml"
install -m 0644 "$TMP2" ".github/workflows/audit.yml"
install -m 0644 "$TMP3" ".github/workflows/publish.yml"

# ---------- Validation repo : lister explicitement les fichiers YAML ----------
echo "# Validation actionlint (sélection explicite des .yml/.yaml)…"
mapfile -t WF_FILES < <(git ls-files -- .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true)
# Fallback si ls-files ne retourne rien (ex: fichiers non suivis)
if [ ${#WF_FILES[@]} -eq 0 ]; then
  mapfile -t WF_FILES < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
fi

if [ ${#WF_FILES[@]} -eq 0 ]; then
  echo "Aucun fichier workflow trouvé pour la validation — rien à lint."
else
  "$ACTIONLINT" -color -shellcheck= -pyflakes= "${WF_FILES[@]}"
fi

# ---------- Commit optionnel ----------
git add .github/workflows/pre-commit-autoupdate.yml \
        .github/workflows/audit.yml \
        .github/workflows/publish.yml

if ! git diff --cached --quiet; then
  git commit -m "ci: replace truncated workflows with valid YAML (autoupdate, audit, publish)" --no-verify
  echo "# Conseil : pousse quand prêt →  git push"
else
  echo "# Aucun changement à committer (fichiers identiques)."
fi

echo "# OK. Log complet : $LOG"
# pause finale via trap
