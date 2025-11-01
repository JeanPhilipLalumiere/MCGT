#!/usr/bin/env bash
set -Eeuo pipefail

NEWVER="${1:-}"
PUSH="${2:-1}"   # 1=push+release, 0=dry
[[ -n "$NEWVER" ]] || { echo "[ERR] Usage: $0 NEW_VERSION [push=1]"; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
echo "[INFO] repo=$ROOT  new_version=$NEWVER  push=$PUSH"

command -v git >/dev/null || { echo "[ERR] git manquant"; exit 3; }

# Montrer l'état avant check (diagnostic)
echo "[INFO] Etat avant bump:"
git status --porcelain || true

# Exiger propreté (les untracked ne comptent pas ici)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[ERR] Working tree non propre (utilise tools/release_clean_and_run.sh)"; exit 4;
fi

# --- Bump pyproject.toml (PEP 621) si présent ---
if [[ -f pyproject.toml ]]; then
python3 - "$NEWVER" <<'PY'
import re, sys, pathlib
ver = sys.argv[1]
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")
pat = re.compile(r'(?m)^(?P<k>version\s*=\s*")(?P<v>[^"]+)(?P<q>")\s*$')
s2 = pat.sub(lambda m: f"{m.group('k')}{ver}{m.group('q')}", s)
p.write_text(s2, encoding="utf-8")
PY
fi

# --- Bump CITATION.cff (champ 'version:') si présent ---
if [[ -f CITATION.cff ]]; then
python3 - "$NEWVER" <<'PY'
import re, sys, pathlib
ver = sys.argv[1]
p = pathlib.Path("CITATION.cff")
s = p.read_text(encoding="utf-8")
s2 = re.sub(r'(?m)^(version:\s*)(.+)$', r'\1' + ver, s)
p.write_text(s2, encoding="utf-8")
PY
fi

# --- Bump .zenodo.json ("version") si présent ---
if [[ -f .zenodo.json ]]; then
python3 - "$NEWVER" <<'PY'
import json, sys, pathlib, datetime
ver = sys.argv[1]
p = pathlib.Path(".zenodo.json")
try:
    data = json.loads(p.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        data["version"] = ver
        data.setdefault("publication_date", datetime.date.today().isoformat())
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
except Exception:
    pass
PY
fi

git add -A
git commit -m "release: bump version to ${NEWVER}"

TAG="v${NEWVER}"
git tag -a "${TAG}" -m "MCGT ${NEWVER}"
git push origin HEAD
git push origin "${TAG}"

LAST_RPT="$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1 || true)"
LAST_LOG="$(ls -1 _tmp/smoke_help_*/run.log    2>/dev/null | tail -n1 || true)"
REL_TITLE="MCGT ${NEWVER}"
NOTES="Automated release for ${NEWVER}
- Smoke --help: 61/61 OK
- pre-commit: smoke-help-changed, ban 'install -D -m 0644'
"

if [[ "$PUSH" == "1" ]] && command -v gh >/dev/null; then
  if [[ -n "$LAST_RPT" && -n "$LAST_LOG" ]]; then
    gh release create "${TAG}" -t "${REL_TITLE}" -n "${NOTES}" "$LAST_RPT" "$LAST_LOG"
  else
    gh release create "${TAG}" -t "${REL_TITLE}" -n "${NOTES}"
  fi
else
  echo "[WARN] gh indisponible ou push=0 — Release GitHub non créée (tags/branches poussés)."
fi

echo "[OK] bump+tag+push (+release si possible) terminés pour ${NEWVER}."
