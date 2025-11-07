#!/usr/bin/env bash
# finalize_pins_ci.sh — Idempotent finalizer for constrained installs, CI, docs & hooks
# Usage: bash finalize_pins_ci.sh
set -Eeuo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
echo "[INFO] Finalisation pins/CI/hooks — $ts"

# 1) Pins stricts
mkdir -p constraints
cat > constraints/security-pins.txt <<'PINZ'
# Pins de sécurité centralisés (appliqués via PIP_CONSTRAINT)
requests==2.32.5
jupyterlab==4.4.8
PINZ

# 2) Séparation runtime/dev (assure jupyterlab hors runtime, présent en dev)
if [ -f requirements.txt ]; then
  sed -i.bak '/^[[:space:]]*jupyterlab\b/Id' requirements.txt || true
  mkdir -p _tmp && mv -f requirements.txt.bak "_tmp/requirements.txt.$ts.before" 2>/dev/null || true
fi
grep -qi '^[[:space:]]*jupyterlab' requirements-dev.txt 2>/dev/null || echo 'jupyterlab==4.4.8' >> requirements-dev.txt

# 3) CI complète (réécrit le workflow au propre)
mkdir -p .github/workflows
cat > .github/workflows/ci-pins.yml <<'YML'
name: ci-pins
on:
  push:
  pull_request:
jobs:
  constraint-guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }

      - name: Fail if unconstrained "pip install" exists in repo files
        run: |
          python - <<'PY'
import re,sys,os
bad=[]
skip_dirs = {'.git','_tmp','venv','.venv','.mypy_cache','.pytest_cache','.ruff_cache'}
def wanted_dir(root, d):
  return d not in skip_dirs
for root,dirs,files in os.walk('.'):
  dirs[:] = [d for d in dirs if wanted_dir(root,d)]
  for f in files:
    if f.endswith(('.sh','.bash','.zsh','.ps1','.py','.md','.yml','.yaml')) or f.startswith('Makefile'):
      p=os.path.join(root,f)
      try:
        t=open(p,errors='ignore').read()
      except Exception:
        continue
      for i,line in enumerate(t.splitlines(),1):
        if re.search(r'\\bpip\\s+install\\b', line) and 'PIP_CONSTRAINT=' not in line:
          bad.append(f"{p}:{i}: {line.strip()}")
if bad:
  print("Unconstrained pip install found:")
  print("\\n".join(bad))
  sys.exit(1)
print("OK: no unconstrained pip install")
PY

      - name: Install runtime (constrained)
        run: PIP_CONSTRAINT=constraints/security-pins.txt python -m pip install -r requirements.txt

      - name: Install dev (constrained)
        run: PIP_CONSTRAINT=constraints/security-pins.txt python -m pip install -r requirements-dev.txt

      - name: pip-audit runtime
        uses: pypa/gh-action-pip-audit@v1
        with:
          requirements: requirements.txt

      - name: pip-audit dev
        uses: pypa/gh-action-pip-audit@v1
        with:
          requirements: requirements-dev.txt
YML

# 4) Outil de sweep (idempotent) — insère PIP_CONSTRAINT manquant
mkdir -p tools
cat > tools/sweep_fix_pip_invocations.sh <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
echo "[INFO] Sweep: insertion PIP_CONSTRAINT si manquant"
changed=0
while IFS= read -r -d '' f; do
  case "$f" in
    _tmp/*|venv/*|.venv/*|.git/*) continue ;;
  esac
  tmp="$(mktemp)"
  perl -0777 -pe 's/(\bpip\s+install\b(?![^\n]*PIP_CONSTRAINT=))/PIP_CONSTRAINT=constraints\/security-pins.txt \1/g' "$f" > "$tmp" || true
  if ! cmp -s "$f" "$tmp"; then
    mkdir -p _tmp/sweep_before && cp "$f" "_tmp/sweep_before/${f//\//__}"
    mv "$tmp" "$f"
    echo "[FIX] $f"; changed=1
  else
    rm -f "$tmp"
  fi
done < <(git ls-files -z | grep -zE '\.sh$|\.py$|\.md$|(^|/)Makefile(\.|$)|\.ya?ml$')
[ $changed -eq 0 ] && echo "[OK] Aucun changement nécessaire." || echo "[DONE] Modifications appliquées."
SH
chmod +x tools/sweep_fix_pip_invocations.sh

# 5) Doc CONTRIBUTING (création + section contraintes)
mkdir -p docs
if [ ! -f docs/CONTRIBUTING.md ]; then
  cat > docs/CONTRIBUTING.md <<'MD'
# CONTRIBUTING

## Dépendances & contraintes de sécurité

Runtime :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
```

Développement :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements-dev.txt
```

Audit :
```bash
pip-audit -r requirements.txt && pip-audit -r requirements-dev.txt
```
MD
else
  grep -q 'PIP_CONSTRAINT=constraints/security-pins.txt' docs/CONTRIBUTING.md || cat >> docs/CONTRIBUTING.md <<'MD'

## Dépendances & contraintes de sécurité

Runtime :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
```

Développement :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements-dev.txt
```

Audit :
```bash
pip-audit -r requirements.txt && pip-audit -r requirements-dev.txt
```
MD
fi

# 6) README (rappel court, si absent)
if [ -f README.md ] && ! grep -q 'PIP_CONSTRAINT=constraints/security-pins.txt' README.md; then
  cat >> README.md <<'MD'

### Installation (sécurisée par contrainte)

```bash
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements-dev.txt
```
MD
fi

# 7) Hook pre-commit minimal (ajout si manquant)
if [ ! -f .pre-commit-config.yaml ]; then
  cat > .pre-commit-config.yaml <<'YAML'
repos:
- repo: local
  hooks:
  - id: guard-no-jupyterlab-in-runtime
    name: guard: jupyterlab must stay in dev
    entry: bash -lc 'grep -qi "^[[:space:]]*jupyterlab" requirements.txt && { echo "jupyterlab doit rester dans requirements-dev.txt"; exit 1; } || exit 0'
    language: system
    files: ^requirements\.txt$
  - id: guard-pip-constraint-anywhere
    name: guard: pip installs must use constraints
    entry: bash -lc '! grep -RIn --exclude-dir=_tmp --exclude-dir=.git --exclude-dir=venv --exclude-dir=.venv -E "\bpip +install\b" . || grep -RIn --exclude-dir=_tmp --exclude-dir=.git --exclude-dir=venv --exclude-dir=.venv -E "\bpip +install\b(?!.*PIP_CONSTRAINT=)" . && exit 1 || exit 0'
    language: system
YAML
else
  if ! grep -q 'guard-pip-constraint-anywhere' .pre-commit-config.yaml; then
    cat >> .pre-commit-config.yaml <<'YAML'

# appended by finalize_pins_ci.sh
repos:
- repo: local
  hooks:
  - id: guard-pip-constraint-anywhere
    name: guard: pip installs must use constraints
    entry: bash -lc '! grep -RIn --exclude-dir=_tmp --exclude-dir=.git --exclude-dir=venv --exclude-dir=.venv -E "\bpip +install\b" . || grep -RIn --exclude-dir=_tmp --exclude-dir=.git --exclude-dir=venv --exclude-dir=.venv -E "\bpip +install\b(?!.*PIP_CONSTRAINT=)" . && exit 1 || exit 0'
    language: system
YAML
  fi
fi

# 8) Sweep automatique (facultatif)
if [ -x tools/sweep_fix_pip_invocations.sh ]; then
  ./tools/sweep_fix_pip_invocations.sh || true
fi

# 9) Commit & push (si changements)
git add -A || true
if ! git diff --cached --quiet; then
  git commit -m "security: normalize pins, complete CI constraint-guard, add docs & non-interactive hooks"
  branch="$(git branch --show-current || true)"
  if [ -n "$branch" ] && git config --get branch."$branch".remote >/dev/null 2>&1; then
    git push -u origin "$branch" || true
  fi
else
  echo "[INFO] Rien à committer."
fi

echo "[OK] Finalisation terminée — sans interaction."
