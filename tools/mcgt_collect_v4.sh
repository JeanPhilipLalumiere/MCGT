#!/usr/bin/env bash
# MCGT - COLLECT v4 (PRINT-ONLY, READ-ONLY, pauses anti-fermeture)
# - Ne modifie rien dans le repo (lecture seule).
# - N'échoue pas sur erreur (no 'set -e').
# - Ajoute des PAUSES pour que la fenêtre ne se ferme pas.
# - Concentre l’extraction sur: PR/checks, workflows requis, manifests, figures, deps.

PR_NUMBER="${PR_NUMBER:-20}"
REPO_DIR="${REPO_DIR:-$HOME/MCGT}"

pause() { read -r -p "${1:-Appuie sur Entrée pour continuer...}"; }

echo "======== MCGT / COLLECT v4 (print-only) ========"
date -Is

# (0) Contexte env (non bloquant)
if command -v conda >/dev/null 2>&1; then
  (conda activate mcgt-dev >/dev/null 2>&1 && echo "[env] conda: mcgt-dev activé") || echo "[env] conda: non activé (ok)"
else
  echo "[env] conda: absent (ok)"
fi
echo "[env] which python: $(command -v python || echo 'n/a')"
echo "[env] python -V: $(python -V 2>&1 || true)"
pause

# (1) Repo
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[repo] ERREUR: $REPO_DIR n'est pas un repo git"
  pause "Entrée pour quitter..."; exit 1
fi
cd "$REPO_DIR" || { echo "[repo] cd échoué"; pause; exit 1; }
echo "[repo] pwd: $(pwd)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'n/a')"
HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'n/a')"
echo "[git] branch: $BRANCH"
echo "[git] HEAD:   $HEAD_SHA"
git status --porcelain=1 | head -n 20 | sed 's/^/[status] /' || true
pause

# (2) Remote → owner/repo (sans suffixe .git)
REMOTE_URL="$(git config --get remote.origin.url 2>/dev/null || echo '')"
OWNER_REPO=""
if echo "$REMOTE_URL" | grep -qE "github.com[:/]"; then
  OWNER_REPO="$(echo "$REMOTE_URL" | sed -E 's/.*github.com[:\/]([^\/]+\/[^\/]+)(\.git)?/\1/; s/\.git$//')"
fi
echo "[git] origin: $REMOTE_URL"
echo "[git] owner/repo: ${OWNER_REPO:-<inconnu>}"
pause

# (3) PR #N : mergeability & checks (via gh si dispo)
echo "----- PR #$PR_NUMBER : état & checks (gh) -----"
if command -v gh >/dev/null 2>&1 && [ -n "$OWNER_REPO" ]; then
  echo "[gh] mergeability (titre/branches/mergeState/headRefOid/state/reviewDecision):"
  gh pr view "$PR_NUMBER" --repo "$OWNER_REPO" \
    --json number,title,headRefName,baseRefName,mergeStateStatus,headRefOid,state,reviewDecision \
    --jq '{number,title,headRefName,baseRefName,mergeStateStatus,headRefOid,state,reviewDecision}' 2>/dev/null || echo "(gh: champs indisponibles)"
  echo
  echo "[gh] statusCheckRollup (name/status/conclusion) :"
  gh pr view "$PR_NUMBER" --repo "$OWNER_REPO" --json statusCheckRollup \
    --jq '.statusCheckRollup[] | {name: .name, status: .status, conclusion: .conclusion}' 2>/dev/null \
    || echo "(gh: statusCheckRollup non accessible)"
else
  echo "(gh indisponible ou repo inconnu)"
fi
pause

# (4) Branch protection (main) — best effort
echo "----- Branch protection (main) -----"
if command -v gh >/dev/null 2>&1 && [ -n "$OWNER_REPO" ]; then
  gh api repos/"$OWNER_REPO"/branches/main/protection 2>/dev/null | jq '{required_status_checks, enforce_admins, required_pull_request_reviews}' 2>/dev/null \
    || echo "(gh: protection non accessible)"
else
  echo "(gh indisponible ou repo inconnu)"
fi
pause

# (5) Workflows requis — analyse fine
echo "----- Workflows requis (secret-scan.yml / pypi-build.yml) -----"
for WF in secret-scan.yml pypi-build.yml; do
  F=".github/workflows/$WF"
  if [ -f "$F" ]; then
    echo "### $F"
    echo "- name: $(grep -E '^name:' "$F" -m1 | sed 's/^name:[[:space:]]*//;s/^$/<vide>/')"
    echo "- events: $(grep -E '^\s*(pull_request|push|workflow_dispatch)\b' "$F" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' || echo 'n/a')"
    echo "- jobs:  $(grep -E '^\s*[a-zA-Z0-9_-]+:\s*$' "$F" | sed 's/^[[:space:]]*//;s/:$//' | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)"
    echo "- concurrency.cancel-in-progress: $(grep -n 'cancel-in-progress' "$F" | awk -F: '{print $NF}' | tr '\n' ' ' || echo 'n/a')"
    echo "- gitleaks action (si présent): $(grep -E 'gitleaks/gitleaks-action@' "$F" -n || echo '(non trouvé)')"
    echo "- SARIF upload (indicatif): $(grep -E 'upload-sarif|code-scanning' "$F" -n || echo '(non trouvé)')"
    echo "- if: $(grep -n '^\s*if:\s*' "$F" | head -n 5 | tr '\n' ' ' || echo 'n/a')"
    echo
  else
    echo "### $F : ABSENT"
  fi
done
echo "[tmp/bak] .github/workflows :"
(ls -1 .github/workflows | egrep '\.tmp|\.bak' -n || echo "(aucun)"); echo
pause

# (6) Derniers runs par workflow (best effort)
echo "----- Derniers runs GitHub Actions (secret-scan.yml / pypi-build.yml) -----"
if command -v gh >/dev/null 2>&1 && [ -n "$OWNER_REPO" ]; then
  for WF in secret-scan.yml pypi-build.yml; do
    echo "### $WF :"
    gh run list --repo "$OWNER_REPO" --workflow "$WF" --limit 5 2>/dev/null | nl -ba || echo "(liste indisponible)"
    RUN_ID="$(gh run list --repo "$OWNER_REPO" --workflow "$WF" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
    if [ -n "$RUN_ID" ]; then
      echo " - run id: $RUN_ID ; 120 dernières lignes de log:"
      gh run view "$RUN_ID" --repo "$OWNER_REPO" --log 2>/dev/null | tail -n 120 || echo "(lecture log échouée)"
    fi
    echo
  done
else
  echo "(gh indisponible ou repo inconnu)"
fi
pause

# (7) Manifests — métriques qualité (jq requis)
echo "----- Manifests (master/publication) : métriques -----"
HAS_JQ=0; command -v jq >/dev/null 2>&1 && HAS_JQ=1
for MF in assets/zz-manifests/manifest_master.json assets/zz-manifests/manifest_publication.json; do
  if [ -f "$MF" ]; then
    echo "### $MF"
    if [ "$HAS_JQ" -eq 1 ]; then
      CNT="$(jq '(.files // .Figures // .items // []) | length' "$MF" 2>/dev/null || echo -1)"
      MISS_SHA="$(jq '(.files // .Figures // .items // []) | map( (has("sha256") or has("sha")) | not ) | add' "$MF" 2>/dev/null || echo 0)"
      echo "- items: $CNT ; sans sha: ${MISS_SHA:-0}"
      echo "- meta: mtime=$(date -r "$MF" +%Y-%m-%dT%H:%M:%S), size=$(stat -c%s "$MF")"
      echo "- 3 premières entrées (path/sha) :"
      jq -r '(.files // .Figures // .items // []) | .[0:3] |
             map( [(.path // .filepath // .file // .name // "<?>"), (.sha256 // .sha // .hash // "<?>")] | @tsv )[]' "$MF" 2>/dev/null || true
      echo "- 5 paths manquants (si référencés):"
      jq -r '(.files // .Figures // .items // []) | map(.path // .filepath // .file // .name // empty) | .[]' "$MF" 2>/dev/null \
        | head -n 400 | while IFS= read -r p; do [ -n "$p" ] && [ ! -f "$p" ] && echo "MISSING $p"; done | head -n 5
    else
      echo "(jq absent)"; sed -n '1,30p' "$MF"
    fi
  else
    echo "### $MF : ABSENT"
  fi
done
pause

# (8) Figures — comptage + sha256 des 10 premières
echo "----- assets/zz-figures : comptage + sha256 (10 premières) -----"
if [ -d assets/zz-figures ]; then
  find assets/zz-figures -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) | sort | tee /tmp/_figlist_mcgt.txt >/dev/null
  echo "- total: $(wc -l < /tmp/_figlist_mcgt.txt | tr -d ' ')"
  head -n 10 /tmp/_figlist_mcgt.txt | while IFS= read -r f; do
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$f"
    else
      echo "sha256sum absent: $f"
    fi
  done
else
  echo "(assets/zz-figures absent)"
fi
pause

# (9) Dépendances & backend MPL
echo "----- Libs Python & Matplotlib backend -----"
python - <<'PY' 2>/dev/null || true
import importlib
mods = ["numpy","scipy","matplotlib","pandas","numba","PIL","jsonschema"]
for m in mods:
    try:
        mod = importlib.import_module(m if m!="PIL" else "PIL.Image")
        ver = getattr(mod, "__version__", getattr(mod, "VERSION", "n/a"))
        print(f"{m:<12} {ver}")
    except Exception as e:
        print(f"{m:<12} (absent) {e.__class__.__name__}")
try:
    import matplotlib
    print("mpl_backend ", matplotlib.get_backend())
except Exception:
    print("mpl_backend  (n/a)")
PY
pause

# (10) Heuristique secrets (échantillon)
echo "----- Heuristique secrets (échantillon 200) -----"
grep -RIn --exclude-dir=.git --exclude=*.png --exclude=*.pdf \
  -E "-----BEGIN .*PRIVATE KEY|AKIA[0-9A-Z]{16}|api[_-]?key|client[_-]?secret|GH[_-]?TOKEN|ghp_[0-9A-Za-z_]{36}" . 2>/dev/null | head -n 200 \
  || echo "(0 correspondance; gitleaks peut diverger)"
pause

# (11) Repo-wide *.tmp/*.bak (top 80)
echo "----- Repo-wide *.tmp / *.bak (top 80) -----"
(find . -type f \( -name '*.tmp*' -o -name '*.bak*' \) -not -path './.git/*' -printf '%p\n' 2>/dev/null || true) | head -n 80
pause

# (12) Règles potentiellement dangereuses (workflows)
echo "----- Workflows: if/cancel suspects (échantillon) -----"
if [ -d .github/workflows ]; then
  grep -RIn --include='*.yml' -E 'cancel-in-progress:\s*true|if:\s*github\.event_name\s*!?=\s*["'\'']pull_request["'\'']' .github/workflows 2>/dev/null | head -n 40 \
    || echo "(rien de suspect dans l'échantillon)"
else
  echo "(workflows absent)"
fi
pause

echo "======== RÉSUMÉ COURT v4 ========"
echo "* Branch/HEAD: $BRANCH @ $HEAD_SHA"
echo "* Owner/repo: ${OWNER_REPO:-<inconnu>}"
echo "* Workflows requis présents: $( [ -f .github/workflows/secret-scan.yml ] && echo secret-scan || echo -n ) $( [ -f .github/workflows/pypi-build.yml ] && echo pypi-build || echo -n )"
echo "* .github/workflows tmp/bak: $(ls -1 .github/workflows 2>/dev/null | egrep '\.tmp|\.bak' -n | wc -l | tr -d ' ')"
if command -v jq >/dev/null 2>&1 && [ -f assets/zz-manifests/manifest_master.json ]; then
  echo "* manifest_master.items: $(jq '(.files // .Figures // .items // []) | length' assets/zz-manifests/manifest_master.json 2>/dev/null || echo -1)"
fi
if [ -d assets/zz-figures ]; then
  echo "* figures (png/svg/pdf): $(find assets/zz-figures -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) | wc -l | tr -d ' ')"
fi
echo "=================================="
pause "Collecte terminée. Appuie sur Entrée pour quitter..."
exit 0
