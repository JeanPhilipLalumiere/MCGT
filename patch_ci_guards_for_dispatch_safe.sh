# patch_ci_guards_for_dispatch_safe.sh
#!/usr/bin/env bash
set -Eeuo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR=".ci-out"
mkdir -p "$OUTDIR"
prompt_hold(){ if [ -t 0 ]; then echo "────────────────────────────────────────────────"; read -rp "Appuie sur Entrée pour fermer ce script..."; fi; }
on_err(){ code=$?; echo "[ERREUR] Code=$code — rien n'a été supprimé."; prompt_hold; exit "$code"; }
trap on_err ERR

echo "[INFO] Début : $TS (UTC)"
echo "[CTX] Repo : $(pwd)"

# Chemins
G1=".github/workflows/readme-guard.yml"
G2=".github/workflows/manifest-guard.yml"
G3=".github/workflows/guard-ignore-and-sdist.yml"

# Sauvegardes (si existent)
for f in "$G1" "$G2" "$G3"; do
  if [ -f "$f" ]; then
    cp -f "$f" "$f.bak.$TS"
    cp -f "$f" "$OUTDIR/$(basename "$f").before.$TS.yml"
    echo "[BAK] $f -> $f.bak.$TS"
  fi
done

# ──────────────────────────────────────────────────────────
# readme-guard.yml — compatible PR + dispatch, sans PR requis
# ──────────────────────────────────────────────────────────
cat >"$G1" <<'YAML'
name: readme-guard
on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch: {}
permissions:
  contents: read
concurrency:
  group: readme-guard-${{ github.ref }}
  cancel-in-progress: true
jobs:
  guard:
    name: guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: README badge guard (works on PR & dispatch)
        shell: bash
        run: |
          set -euo pipefail
          # Si le pattern "badges orphelins après H1" est détecté → échec.
          if awk 'BEGIN{a=0;h=0} /<!-- END BADGES -->/{a=1} /^# /{h=1}
                   { if(a==1&&h==0&&index($0,"[![")>0){ print; bad=1 } }
                   END{ exit bad?0:1 }' README.md; then
            echo "::error::README contient des badges orphelins sous le H1."
            exit 1
          else
            echo "README OK"
          fi
YAML

# ──────────────────────────────────────────────────────────
# manifest-guard.yml — valide présence + JSON + diag optionnel
# ──────────────────────────────────────────────────────────
cat >"$G2" <<'YAML'
name: manifest-guard
on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch: {}
permissions:
  contents: read
concurrency:
  group: manifest-guard-${{ github.ref }}
  cancel-in-progress: true
jobs:
  guard:
    name: guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check manifest presence
        shell: bash
        run: |
          set -euo pipefail
          test -f zz-manifests/manifest_master.json || { echo "::error::zz-manifests/manifest_master.json manquant"; exit 1; }
          echo "[OK] manifest présent"
      - name: Validate JSON syntax (python stdlib)
        shell: bash
        run: |
          set -euo pipefail
          python3 - <<'PY'
import json,sys
p="zz-manifests/manifest_master.json"
with open(p,'rb') as f: json.load(f)
print("JSON OK:", p)
PY
      - name: Optional diag_consistency.py if present
        shell: bash
        run: |
          set -euo pipefail
          if [ -f zz-scripts/diag_consistency.py ]; then
            python3 zz-scripts/diag_consistency.py || { echo "::error::diag_consistency a échoué"; exit 1; }
          else
            echo "[SKIP] zz-scripts/diag_consistency.py absent"
          fi
YAML

# ──────────────────────────────────────────────────────────
# guard-ignore-and-sdist.yml — vérifie .gitignore + contenu sdist
# ──────────────────────────────────────────────────────────
cat >"$G3" <<'YAML'
name: guard-ignore-and-sdist
on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch: {}
permissions:
  contents: read
concurrency:
  group: guard-ignore-and-sdist-${{ github.ref }}
  cancel-in-progress: true
jobs:
  guard:
    name: guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check .gitignore contains required patterns
        shell: bash
        run: |
          set -euo pipefail
          req=0
          grep -E '(^|/)zz-out(/|/|\*\*)?' .gitignore >/dev/null 2>&1 || { echo "::error::.gitignore doit ignorer zz-out/**"; req=1; }
          grep -E '(^|/)_attic_untracked(/|/|\*\*)?' .gitignore >/dev/null 2>&1 || { echo "::error::.gitignore doit ignorer _attic_untracked/**"; req=1; }
          [ $req -eq 0 ] || exit 1
          echo "[OK] .gitignore couvre zz-out/** et _attic_untracked/**"

      - name: Build sdist
        shell: bash
        run: |
          set -euo pipefail
          python3 -m pip install --upgrade pip build >/dev/null
          python3 -m build --sdist
          ls -lh dist/*.tar.gz

      - name: Inspect sdist for forbidden artefacts
        shell: bash
        run: |
          set -euo pipefail
          TARBALL="$(ls dist/*.tar.gz | head -n1)"
          echo "[INFO] Inspect: $TARBALL"
          tar -tzf "$TARBALL" > sdist.lst
          if grep -E '(^|/)zz-out/|(^|/)_attic_untracked/|/__pycache__/|\.py[co]$|\.tmp$|\.log$|\.save$|\.bak($|[^/])|\.autofix\..*\.bak' sdist.lst; then
            echo "::error::Artefacts interdits détectés dans la sdist."
            exit 1
          fi
          echo "[OK] sdist propre"
YAML

echo "[WRITE] YAML réécrits."
git --no-pager diff -- .github/workflows | sed -n '1,200p' || true

echo
read -r -p "Commit & push ces changements ? [y/N] " ans
if [[ "${ans:-N}" =~ ^[yY]$ ]]; then
  git add .github/workflows/*.yml
  git commit -m "ci(guards): support workflow_dispatch + checks PR/dispatch robustes [SAFE $TS]"
  git push
  echo "[GIT] Changements poussés."
else
  echo "[GIT] Commit/push laissé à ta main."
fi

echo "[DONE] Tu peux relancer: ./rerun_ci_ref_safe_v3.sh release/zz-tools-0.3.1"
prompt_hold
