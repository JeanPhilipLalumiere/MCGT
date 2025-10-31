# repo_add_fig_manifest_check_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_fig_manifest_check_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "${BR}"

mkdir -p tools .github/workflows

# 1) Checker Python (hash/existence vs manifeste)
cat > tools/_check_fig_manifest.py <<'PY'
import csv, sys, hashlib
from pathlib import Path

manifest = Path("zz-manifests/figure_manifest.csv")
if not manifest.exists():
    print(f"[ERR] Manifeste absent: {manifest}", file=sys.stderr)
    sys.exit(2)

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

errs = 0
with manifest.open("r", encoding="utf-8", newline="") as fo:
    rd = csv.DictReader(fo)
    for row in rd:
        fig = Path(row["path"])
        exp_sha = (row.get("sha256") or "").strip().lower()
        exp_exists = row.get("exists","").strip()
        if exp_exists not in {"0","1"}:
            print(f"[ERR] exists invalide pour {fig}: {exp_exists}")
            errs += 1
            continue
        if exp_exists == "0":
            if fig.exists():
                print(f"[ERR] attendu absent mais présent: {fig}")
                errs += 1
            else:
                print(f"[OK] absent (conforme manifeste): {fig}")
            continue
        # exists == "1"
        if not fig.exists():
            print(f"[ERR] figure manquante: {fig}")
            errs += 1
            continue
        got_sha = sha256(fig)
        if exp_sha and got_sha != exp_sha:
            print(f"[ERR] SHA256 diff: {fig}\n  exp={exp_sha}\n  got={got_sha}")
            errs += 1
        else:
            size = fig.stat().st_size
            print(f"[OK] {fig}  bytes={size}  sha256={got_sha[:12]}…")

if errs:
    print(f"[FAIL] {errs} écart(s) détecté(s).", file=sys.stderr)
    sys.exit(1)
print("[PASS] Manifeste figures conforme.")
PY

# 2) Wrapper shell appelable localement et en CI
cat > tools/check_fig_manifest.sh <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
python - <<'PY'
import sys; sys.version_info >= (3,10) or (_ for _ in ()).throw(SystemExit("Python >=3.10 requis"))
PY
python tools/_check_fig_manifest.py
SH
chmod +x tools/check_fig_manifest.sh

# 3) Workflow CI dédié (valide manifeste sur 3.10–3.12)
cat > .github/workflows/ci-fig-manifest.yml <<'YML'
name: ci-fig-manifest
on:
  pull_request:
    paths:
      - "zz-manifests/figure_manifest.csv"
      - "zz-figures/**"
      - "zz-scripts/**"
      - ".github/workflows/ci-fig-manifest.yml"
      - "tools/check_fig_manifest.sh"
      - "tools/_check_fig_manifest.py"
  push:
    branches: ["**"]
    paths:
      - "zz-manifests/figure_manifest.csv"
      - "zz-figures/**"
      - "zz-scripts/**"
      - ".github/workflows/ci-fig-manifest.yml"
      - "tools/check_fig_manifest.sh"
      - "tools/_check_fig_manifest.py"
jobs:
  verify-figures:
    runs-on: ubuntu-latest
    strategy:
      matrix: { python-version: ["3.10", "3.11", "3.12"] }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "${{ matrix.python-version }}" }
      - name: Check figure manifest (hash/existence)
        run: tools/check_fig_manifest.sh
YML

echo "== DRY-RUN local =="
tools/check_fig_manifest.sh || { echo "[WARN] checker a échoué localement"; :; }

echo "== GIT ADD & COMMIT =="
git add tools/_check_fig_manifest.py tools/check_fig_manifest.sh .github/workflows/ci-fig-manifest.yml || true
if git diff --cached --quiet; then
  echo "[NOTE] Rien à committer."
else
  git commit -m "ci: vérification manifeste figures (existence + SHA256) sur py 3.10–3.12"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
fi

echo "== CONSEIL PR =="
echo 'Commente la PR #36 : "Ajout du check manifeste (existence+SHA256) — verrou Round-2."' 
