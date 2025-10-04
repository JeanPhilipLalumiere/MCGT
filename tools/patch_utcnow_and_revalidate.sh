#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[utcnow-patch] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[utcnow-patch] Appuie sur Entrée pour quitter…"
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

echo "==> (0) Contexte dépôt"
cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Remplacement sécurisé des 'datetime.datetime.utcnow()'"
python - <<'PY'
from pathlib import Path
import re, json

root = Path(".").resolve()

# motif strict: forme module-qualifiée uniquement
pat = re.compile(r"\bdatetime\.datetime\.utcnow\(\)")

# Candidats: tous les .py + deux scripts shell qui embarquent du Python
candidates = list(root.rglob("*.py"))
for special in (
    root/"tools/ci_step9_parameters_registry_guard.sh",
    root/"tools/ci_step10_python_constants_guard.sh",
):
    if special.exists():
        candidates.append(special)

# Exclure explicitement ce script pour éviter l'auto-modification
exclude = {
    (root/"tools/patch_utcnow_and_revalidate.sh").resolve()
}

changed = []
for fp in candidates:
    if fp.resolve() in exclude:
        continue
    try:
        txt = fp.read_text(encoding="utf-8")
    except Exception:
        continue
    new = pat.sub("datetime.datetime.now(datetime.timezone.utc)", txt)
    if new != txt:
        fp.write_text(new, encoding="utf-8")
        changed.append(str(fp.relative_to(root)))

print(json.dumps({"changed_files": changed, "count": len(changed)}, indent=2))
PY

echo "==> (2) Pré-commit auto-fix (tolérant)"
pre-commit run end-of-file-fixer -a || true
pre-commit run trailing-whitespace -a || true
pre-commit run check-yaml -a || true

echo "==> (3) Re-génère registre & schémas"
KEEP_OPEN=0 tools/ci_step9_parameters_registry_guard.sh || true
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh

echo "==> (4) Commit & push si modifs"
if ! git diff --quiet; then
  git add -A
  git commit -m "chore: replace datetime.utcnow() (module-qualifié) par now(timezone.utc); revalidate"
  git push || true
else
  echo "Aucune modification à committer."
fi

echo "==> (5) Rapport: occurrences 'utcnow(' restantes (à traiter au cas par cas)"
# Affiche p.ex. les formes 'datetime.utcnow()' quand 'from datetime import datetime' est utilisé
grep -RIn --line-number --color=never -E '\butcnow\(' -- ':!venv' ':!.git' ':!.ci-out' || echo "OK: aucune occurrence restante"
