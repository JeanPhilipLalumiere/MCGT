# repo_add_ci_smoke_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_ci_smoke_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

mkdir -p .github/workflows

cat > .github/workflows/ci-smoke.yml <<'YAML'
name: ci-smoke
on:
  pull_request:
  push:
    branches: [ fix/ch09-fig03-parse ]

jobs:
  smoke:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: [ "3.10", "3.11", "3.12" ]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install minimal deps (chapter10 reqs)
        run: |
          python -m pip install --upgrade pip
          if [ -f zz-scripts/chapter10/requirements.txt ]; then
            pip install -r zz-scripts/chapter10/requirements.txt
          fi

      - name: Sanity py_compile (producers ch10 + runner ch09)
        run: |
          python -m py_compile \
            zz-scripts/chapter10/plot_fig0{1,2,3,4,5}_*.py \
            zz-scripts/chapter09/run_fig03_safe.py

      - name: Probe Round-2
        run: |
          bash ./repo_probe_round2_consistency.sh | tee /tmp/probe.log
          grep -q "Résumé ADD:\s*OK\s*20" /tmp/probe.log
          grep -q "Résumé REVIEW:\s*OK\s*16" /tmp/probe.log
YAML

echo "== GIT ADD =="
git add .github/workflows/ci-smoke.yml || true

if ! git diff --cached --quiet; then
  git commit -m "ci: smoke minimal (py_compile + probe Round-2; py 3.10–3.12)"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
else
  echo "[NOTE] Rien à committer (workflow déjà présent ?)"
fi

if command -v gh >/dev/null 2>&1; then
  gh pr comment "$(git rev-parse --abbrev-ref HEAD)" \
    --body "Ajout **ci-smoke** : py_compile producteurs ch10 + runner ch09, et probe Round-2 (ADD 20/20, REVIEW 16/16)."
else
  echo "[NOTE] gh non dispo — commentaire PR non posté."
fi
