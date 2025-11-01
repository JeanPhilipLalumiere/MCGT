# repo_round3_add_policy_ci_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round3_policy_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "branche=${BR}"
# On reste sur chore/round3-cli-homog
if [ "$BR" != "chore/round3-cli-homog" ]; then
  git switch chore/round3-cli-homog
fi

mkdir -p tools .github/workflows

# 1) Checker de POLITIQUE CLI (bloquant si un flag commun manque)
cat > tools/check_cli_policy.py <<'PY'
from __future__ import annotations
import csv, sys
from pathlib import Path

CSV = Path("zz-manifests/TODO_round3_cli.csv")
REQUIRED = ["has_out","has_dpi","has_format","has_transparent","has_style","has_verbose"]

if not CSV.exists():
    print(f"[ERROR] Manquant: {CSV}", file=sys.stderr)
    sys.exit(2)

bad = []
with CSV.open(newline="", encoding="utf-8") as f:
    r = csv.DictReader(f)
    for row in r:
        misses = [k for k in REQUIRED if row.get(k,"0") != "1"]
        if misses:
            bad.append((row["path"], misses))

if bad:
    print("CLI policy violations:", file=sys.stderr)
    for p, miss in bad:
        print(f" - {p}: manque {', '.join(miss)}", file=sys.stderr)
    sys.exit(1)

print("[PASS] CLI policy: tous les producteurs ont les flags communs requis.")
PY

# 2) Checker runners "safe" hors attic/ (bloquant)
cat > tools/check_no_safe_runners.py <<'PY'
from __future__ import annotations
import sys
from pathlib import Path

violations = []
for p in Path(".").rglob("run_*_safe.py"):
    # autorisé uniquement sous attic/
    parts = p.as_posix().split("/")
    if "attic" not in parts:
        violations.append(p.as_posix())

if violations:
    print("Safe runners non autorisés hors 'attic/' :", file=sys.stderr)
    for v in violations:
        print(f" - {v}", file=sys.stderr)
    sys.exit(1)

print("[PASS] Aucun runner *_safe.py hors 'attic/'.")
PY

# 3) Workflow CI : cli-policy (rapide)
cat > .github/workflows/ci-cli-policy.yml <<'YML'
name: ci-cli-policy
on:
  pull_request:
  push:
jobs:
  cli-policy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        py: ["3.10","3.11","3.12"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.py }}
      - name: Run policy checkers
        run: |
          python tools/check_cli_common.py || { echo "::error ::check_cli_common.py manquant ou en échec"; exit 1; }
          python tools/check_cli_policy.py
          python tools/check_no_safe_runners.py
YML

# 4) Dry-run local (best-effort)
echo "== DRY-RUN LOCAL =="
python tools/check_cli_common.py || true
python tools/check_cli_policy.py || true
python tools/check_no_safe_runners.py || true

# 5) Commit & push
echo "== GIT ADD/COMMIT/PUSH =="
git add tools/check_cli_policy.py tools/check_no_safe_runners.py .github/workflows/ci-cli-policy.yml
if git diff --cached --quiet; then
  echo "[NOTE] Rien à committer."
else
  git commit -m "ci(policy): enforce flags CLI communs + interdiction des run_*_safe.py hors attic/"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
fi

echo "== CONSEIL PR =="
echo "Ajoute un commentaire à la PR de Round-3: 'CI cli-policy ajoutée (flags communs requis + no *_safe hors attic/)'."
