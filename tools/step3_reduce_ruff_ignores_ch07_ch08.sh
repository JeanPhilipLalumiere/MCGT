#!/usr/bin/env bash
. tools/lib_psx.sh
psx_install "step3_reduce_ruff_ignores_ch07_ch08.sh"
set -euo pipefail

# === PSX: empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 3 — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 3 — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

# S’auto-marquer exécutable si besoin (évite un futur échec du hook)
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

echo "==> (1) Nettoyage per-file-ignores (ch07/ch08) dans pyproject.toml"
python3 - <<'PY'
from pathlib import Path
p = Path("pyproject.toml")
s = p.read_text(encoding="utf-8")

header = "[tool.ruff.lint.per-file-ignores]"
start = s.find(header)
if start == -1:
    print("Aucun bloc per-file-ignores — rien à faire.")
else:
    # localiser la fin du bloc (prochaine section commençant par '[') :
    import re
    m = re.search(r'(?m)^\[', s[start+len(header):])
    end = start + len(header) + (m.start() if m else len(s)-start-len(header))
    body = s[start+len(header):end]

    # parser lignes "clé = [..]"
    existing = {}
    for line in body.splitlines():
        if "=" in line and not line.strip().startswith("#"):
            k, rest = line.split("=", 1)
            key = k.strip().strip('"').strip("'")
            existing[key] = rest.strip()

    to_drop = {
        "zz-scripts/chapter07/generate_data_chapter07.py",
        "zz-scripts/chapter07/launch_scalar_perturbations_solver.py",
        "zz-scripts/chapter07/tests/test_chapter07.py",
        "zz-scripts/chapter08/generate_data_chapter08.py",
        "zz-scripts/chapter08/plot_fig06_normalized_residuals_distribution.py",
    }

    changed = False
    for k in list(existing):
        if k in to_drop:
            existing.pop(k)
            changed = True

    if changed:
        new_body = "".join(f"\"{k}\" = {existing[k]}\n" for k in sorted(existing))
        new_s = s[:start] + header + "\n" + new_body + s[end:]
        p.write_text(new_s, encoding="utf-8")
        print("pyproject.toml: per-file-ignores nettoyés pour ch07/ch08.")
    else:
        print("pyproject.toml: rien à nettoyer pour ch07/ch08.")
PY

echo "==> (2) Pré-commit (tolérant) + commit/push si diff"
pre-commit run --all-files || true
git add pyproject.toml
if ! git diff --staged --quiet; then
  git commit -m "style(ruff): drop temporary per-file-ignores for ch07/ch08 after inline fixes"
  git push
else
  echo "Aucun changement à committer."
fi
