#!/usr/bin/env bash
set -euo pipefail

# === PSX: empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 4b — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 4b — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Marque exécutables les helpers step3/step4 (évite l'échec du hook)"
for f in tools/step3_reduce_ruff_ignores_ch07_ch08.sh tools/step4_fix_ch07_ch08_inline_errors.sh; do
  if [[ -f "$f" ]]; then
    chmod +x "$f" || true
    git add --chmod=+x "$f" || git add "$f"
  fi
done

echo "==> (2) Ajoute un ignore fichier pour E402 dans ch07 (import après sys.path)"
python3 - <<'PY'
from pathlib import Path
p = Path("zz-scripts/chapter07/generate_data_chapter07.py")
s = p.read_text(encoding="utf-8")
lines = s.splitlines(True)
inserted = False
tag = "# ruff: noqa: E402\n"
if tag.strip() not in s:
    if lines and lines[0].startswith("#!"):
        lines.insert(1, tag)
    else:
        lines.insert(0, tag)
    p.write_text("".join(lines), encoding="utf-8")
    print("E402 file-level ignore ajouté dans", p)
else:
    print("E402 file-level ignore déjà présent dans", p)
PY

echo "==> (3) Pré-commit (tolérant) + commit/push si diff"
pre-commit run --all-files || true
git add -A
if ! git diff --staged --quiet; then
  git commit -m "fix: mark helper scripts + add file-level 'ruff: noqa: E402' in ch07"
  git push
else
  echo "Aucun changement à committer."
fi
