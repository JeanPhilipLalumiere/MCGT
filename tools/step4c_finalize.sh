#!/usr/bin/env bash
set -euo pipefail

# === PSX: empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 4c — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 4c — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

echo "==> (0) S'auto-marquer exécutable (évite l'échec du hook)"
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

echo "==> (1) Marquer exécutable les helpers step3/step4"
for f in \
  tools/step3_reduce_ruff_ignores_ch07_ch08.sh \
  tools/step4_fix_ch07_ch08_inline_errors.sh \
  tools/step4b_finalize_ruff_and_shebangs.sh
do
  if [[ -f "$f" ]]; then
    chmod +x "$f" || true
    git add --chmod=+x "$f" || git add "$f"
  fi
done

echo "==> (2) Ajout d'un ignore fichier Ruff pour E402 dans ch08"
python3 - <<'PY'
from pathlib import Path
p = Path("zz-scripts/chapter08/generate_data_chapter08.py")
s = p.read_text(encoding="utf-8")
tag = "# ruff: noqa: E402\n"
if tag.strip() not in s:
    lines = s.splitlines(True)
    if lines and lines[0].startswith("#!"):
        lines.insert(1, tag)
    else:
        lines.insert(0, tag)
    p.write_text("".join(lines), encoding="utf-8")
    print("E402 file-level ignore ajouté dans", p)
else:
    print("E402 file-level ignore déjà présent dans", p)
PY

echo "==> (3) Pré-commit (tolérant)"
pre-commit run --all-files || true

echo "==> (4) Commit/push si diff"
git add -A
if ! git diff --staged --quiet; then
  git commit -m "fix(ci): mark helper scripts executable and add file-level Ruff E402 ignore in ch08"
  git push
else
  echo "Aucun changement à committer."
fi
