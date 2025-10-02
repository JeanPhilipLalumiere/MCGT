#!/usr/bin/env bash
set -Eeuo pipefail

# Anti-fermeture (désactivez avec: PAUSE_ON_EXIT=0)
trap 'cleanup 0' EXIT

# --- 0) Préambule
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
WF_FILE=".github/workflows/sanity-main.yml"
[[ -f "$WF_FILE" ]] || { echo "[ERREUR] Fichier introuvable: $WF_FILE" >&2; exit 1; }

echo "=== 1) Sauvegarde ==="
TS="$(date +%Y%m%dT%H%M%S)"
cp -v -- "$WF_FILE" "${WF_FILE}.bak.${TS}"

echo "=== 2) Patch ciblé (fusion {…} >> cible + \$ sur __TMP) ==="
python3 - "$WF_FILE" <<'PY'
import sys, re
wf = sys.argv[1]
txt = open(wf, 'r', encoding='utf-8').read().splitlines(True)

# Trouve le step "- name: Meta summary", puis son bloc run: |
i = 0
while i < len(txt) and "- name: Meta summary" not in txt[i]:
    i += 1
if i == len(txt):
    sys.exit(0)  # rien à faire

# Cherche "run: |" ensuite
while i < len(txt) and not re.match(r'^\s*run:\s*\|\s*$', txt[i]):
    i += 1
if i == len(txt):
    sys.exit(0)

base_indent = len(txt[i]) - len(txt[i].lstrip(' '))
i_run = i + 1

# bornes du bloc run (indent > base_indent)
j = i_run
while j < len(txt):
    line = txt[j]
    if line.strip() == "": j += 1; continue
    if (len(line) - len(line.lstrip(' '))) <= base_indent: break
    j += 1

block = txt[i_run:j]

# repère la zone à remplacer :
# from:   __TMP_GITHUB_STEP_SUMMARY_0__="$(mktemp)"
# to:     if [ -f "$__TMP_GITHUB_STEP_SUMMARY_0__" ]; then
mk_re = re.compile(r'^\s*__TMP_GITHUB_STEP_SUMMARY_0__="\$?\(mktemp\)"\s*$')
if_re = re.compile(r'^\s*if\s+\[\s*-f\s+"\$__TMP_GITHUB_STEP_SUMMARY_0__"\s*\]\s*;\s*then\s*$')

mk_idx = next((k for k,l in enumerate(block) if mk_re.match(l)), None)
if_idx = next((k for k,l in enumerate(block) if if_re.match(l)), None)

if mk_idx is None or if_idx is None or if_idx <= mk_idx:
    # Rien à patcher proprement
    sys.exit(0)

indent = re.match(r'^(\s*)', block[mk_idx]).group(1)

# Nouveau segment fusionné
merged = [
    indent + "{\n",
    indent + '  echo "## Meta checks"\n',
    indent + '  echo "- actionlint: pinned v1.7.1 (skip si indisponible)"\n',
    indent + '  echo "- shellcheck: exécuté sur tools/*.sh (skip si absent)"\n',
    indent + "} >> \"$__TMP_GITHUB_STEP_SUMMARY_0__\"\n",
]

# Remplace les lignes entre mk_idx+1 et if_idx (exclus)
block = block[:mk_idx+1] + merged + block[if_idx:]
new = txt[:i_run] + block + txt[j:]

open(wf, 'w', encoding='utf-8').write(''.join(new))
PY

echo
echo "=== 3) DIFF ==="
git --no-pager diff -- "$WF_FILE" || true

if git diff --quiet -- "$WF_FILE"; then
  echo "[INFO] Aucun changement à commit."
else
  echo "=== 4) COMMIT ==="
  git add -- "$WF_FILE"
  git commit -m "ci(sanity-main): SC2129 — fusionne les appends vers \$__TMP_GITHUB_STEP_SUMMARY_0__ en un seul bloc"
fi

echo "=== 5) PUSH + relance CI ==="
git push -u origin main

if command -v gh >/dev/null 2>&1; then
  HEAD_SHA="$(git rev-parse HEAD)"
  echo "[INFO] HEAD_SHA=${HEAD_SHA}"
  echo "[INFO] Déclenchement ci-pre-commit.yml…"
  gh workflow run ci-pre-commit.yml -r main >/dev/null

  echo "[INFO] Recherche du run pour ${HEAD_SHA:0:7}…"
  for _ in $(seq 1 60); do
    RID="$(gh run list --workflow ci-pre-commit.yml --branch main \
      --json databaseId,headSha,createdAt \
      -q '[.[] | select(.headSha=="'"$HEAD_SHA"'")] | sort_by(.createdAt) | last | .databaseId' || true)"
    [[ -n "$RID" && "$RID" != "null" ]] && break
    sleep 2
  done
  if [[ -n "$RID" && "$RID" != "null" ]]; then
    echo "[INFO] RID=$RID — logs à partir de \"Run pre-commit (all files)\""
    gh run view "$RID" --log | sed -n '/Run pre-commit (all files)/,$p' || gh run view "$RID" --log
  else
    echo "[WARN] Run non trouvé; consultez la page Actions."
  fi
else
  echo "[INFO] gh absent — push fait. Ouvrez l’onglet Actions pour suivre le run."
fi
