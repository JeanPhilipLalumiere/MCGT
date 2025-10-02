#!/usr/bin/env bash
set -Eeuo pipefail

# ======== Anti-fermeture de fenêtre ========
trap 'cleanup 0' EXIT

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WF_FILE=".github/workflows/sanity-main.yml"
[[ -f "$WF_FILE" ]] || { echo "[ERREUR] Fichier introuvable: $WF_FILE" >&2; exit 1; }

echo "=== 0) Sauvegarde ==="
TS="$(date +%Y%m%dT%H%M%S)"
cp -v -- "$WF_FILE" "${WF_FILE}.bak.${TS}"

echo "=== 1) Réécriture ciblée (SC2015 + SC2129 GENERIQUE) ==="
python3 - "$WF_FILE" <<'PY'
import re, sys
wf = sys.argv[1]
with open(wf, "r", encoding="utf-8") as f:
    lines = f.readlines()

def ind(s): return len(s) - len(s.lstrip(" "))
def is_blank(s): return s.strip() == ""
def is_comment(s):
    t = s.lstrip()
    return t.startswith("#")

# --- A) Corriger le bloc "Job summary (Markdown)" (SC2015) si présent
name_re = re.compile(r'^\s*-\s*name:\s*Job summary\s*\(Markdown\)\s*$')
run_bar_re = re.compile(r'^\s*run:\s*\|\s*$')

i = 0
while i < len(lines):
    if name_re.match(lines[i]):
        j = i + 1
        while j < len(lines) and not run_bar_re.match(lines[j]):
            if re.match(r'^\s*-\s*name:\s*', lines[j]): break
            j += 1
        if j < len(lines) and run_bar_re.match(lines[j]):
            run_indent = ind(lines[j])
            # bornes du bloc script
            k = j + 1
            while k < len(lines):
                if ind(lines[k]) <= run_indent and not is_blank(lines[k]):
                    break
                if k+1 < len(lines) and re.match(r'^\s*-\s*name:\s*', lines[k+1]):
                    break
                k += 1
            block = """set -euo pipefail
{
  echo "## Sanity diag"
  echo
  if command -v jq >/dev/null 2>&1; then
    TS="$(jq -r '.timestamp // empty' .ci-out/sanity-diag/diag.json 2>/dev/null || true)"
    ERR="$(jq -r '.errors // empty' .ci-out/sanity-diag/diag.json 2>/dev/null || true)"
    WARN="$(jq -r '.warnings // empty' .ci-out/sanity-diag/diag.json 2>/dev/null || true)"
    if [ -s .ci-out/sanity-diag/diag.txt ]; then
      ISSUES="$(cat .ci-out/sanity-diag/diag.txt)"
    else
      ISSUES="$(jq -r '.issues[]? | "- [" + (.severity // "info") + "] " + (.code // "") + ": " + (.msg // "")' .ci-out/sanity-diag/diag.json 2>/dev/null || true)"
    fi
  else
    TS="$(date -u +%FT%TZ)"
    ERR=""
    WARN=""
    ISSUES="$(cat .ci-out/sanity-diag/diag.txt 2>/dev/null || true)"
  fi
  echo "- Timestamp: ${TS:-unknown}"
  echo "- Errors: ${ERR:-none}"
  echo "- Warnings: ${WARN:-none}"
  if [ -n "${ISSUES:-}" ]; then
    echo
    echo "### Issues"
    printf "%s\n" "$ISSUES"
  fi
} >> "$GITHUB_STEP_SUMMARY"
"""
            pad = " " * (run_indent + 2)
            injected = [lines[j]] + [pad + l + ("\n" if not l.endswith("\n") else "") for l in block.splitlines()]
            lines = lines[:j] + injected + lines[k:]
            i = j + len(injected)
            continue
    i += 1

# --- B) SC2129 GENERIQUE : regrouper toute ligne terminant par >> $GITHUB_OUTPUT (peu importe la commande)
OUT_PAT = r'(?:"?\$GITHUB_OUTPUT"?|\$\{GITHUB_OUTPUT\})'
# Exclure lignes de fermeture de bloc déjà groupé: "}" >> "$GITHUB_OUTPUT"
ALREADY_GROUPED = re.compile(r'^\s*\}\s*>>\s*' + OUT_PAT + r'\s*(?:;.*)?$')
# Exclure here-docs redirigés vers GITHUB_OUTPUT: '<<' ... '>> "$GITHUB_OUTPUT"'
HEREDOC_REDIRECT = re.compile(r'<<[-]?\s*[A-Za-z0-9_]+"?\s*>>\s*' + OUT_PAT + r'\s*$')

# Ligne candidate: n'importe quoi qui finit par >> $GITHUB_OUTPUT (avec ; … ou # … possibles)
ANY_TO_OUT = re.compile(
    r'^(?P<sp>\s*)(?P<cmd>.+?)(?P<redir>\s*;?\s*)>>\s*' + OUT_PAT + r'(?P<tail>\s*(?:;.*)?\s*(?:#.*)?)?$'
)

out = []
group = []      # tuples: (indent, original_line, kind)
in_group = False
base_sp = ""

def flush_group():
    global group, out, in_group, base_sp
    if not group:
        return
    # Ne pas regrouper si une seule vraie commande
    cmds = [g for g in group if g[2] == "cmd"]
    if len(cmds) <= 1:
        out.extend([g[1] for g in group])
    else:
        out.append(base_sp + "{\n")
        for sp, line, kind in group:
            if kind in ("blank","comment"):
                out.append(line)
                continue
            m = ANY_TO_OUT.match(line)
            if m:
                core = m.group("cmd").rstrip()
                tail = (m.group("tail") or "")
                # Retire juste la redirection finale, conserve le reste (incluant ; … et commentaires)
                out.append(sp + core + tail + ("\n" if not line.endswith("\n") else ""))
            else:
                out.append(line)  # sécurité
        out.append(base_sp + "} >> \"$GITHUB_OUTPUT\"\n")
    group = []
    in_group = False
    base_sp = ""

for line in lines:
    # ignorer cas déjà sûrs
    if ALREADY_GROUPED.match(line) or HEREDOC_REDIRECT.search(line):
        flush_group()
        out.append(line)
        continue

    m = ANY_TO_OUT.match(line)
    if m:
        if not in_group:
            in_group = True
            base_sp = m.group("sp")
        group.append((m.group("sp"), line, "cmd"))
        continue

    # tolérer commentaires/lignes vides au milieu
    if in_group and (is_blank(line) or is_comment(line)):
        group.append((line[:len(line)-len(line.lstrip(" "))], line, "blank" if is_blank(line) else "comment"))
        continue

    # fin de groupe si ligne normale
    flush_group()
    out.append(line)

flush_group()

with open(wf, "w", encoding="utf-8") as f:
    f.write("".join(out))
PY

echo
echo "=== 2) DIFF ==="
git --no-pager diff -- "$WF_FILE" || true

# 3) COMMIT si modifié
if ! git diff --quiet -- "$WF_FILE"; then
  echo
  echo "=== 3) COMMIT ==="
  git add -- "$WF_FILE"
  git commit -m "ci: actionlint — SC2015 (if/else) + SC2129 générique (regroupe toutes les lignes >> \$GITHUB_OUTPUT)"
else
  echo "[INFO] Aucun changement à commit."
fi

echo
echo "=== 4) PUSH sur main + relance CI (RID unique par headSha) ==="
git fetch origin --prune
CUR_BR="$(git rev-parse --abbrev-ref HEAD || true)"
if [[ "$CUR_BR" != "main" ]]; then
  git switch main
  git pull --ff-only
  git merge --ff-only "$CUR_BR" || { echo "[ERREUR] Merge FF impossible — faites une PR."; exit 1; }
fi
git push -u origin main

HEAD_SHA="$(git rev-parse HEAD)"

if command -v gh >/dev/null 2>&1; then
  echo "[INFO] Déclenchement du workflow ci-pre-commit.yml…"
  gh workflow run ci-pre-commit.yml -r main >/dev/null || true

  echo "[INFO] Recherche du run pour ${HEAD_SHA:0:7}…"
  RID=""
  tries=0
  while [[ -z "$RID" && $tries -lt 40 ]]; do
    sleep 5
    RID="$(gh run list --workflow ci-pre-commit.yml --branch main --limit 30 \
      --json databaseId,headSha,createdAt \
      -q 'map(select(.headSha=="'"$HEAD_SHA"'")) | sort_by(.createdAt) | last | .databaseId // empty' 2>/dev/null || true)"
    RID="$(printf "%s\n" "$RID" | sed '/^$/d' | tail -n1)"
    tries=$((tries+1))
  done

  if [[ -n "$RID" ]]; then
    echo "[INFO] RID=$RID — suivi en temps réel…"
    gh run watch --exit-status "$RID" || true
    echo
    echo "=== LOG CI (depuis 'Run pre-commit (all files)') ==="
    gh run view "$RID" --log | sed -n '/Run pre-commit (all files)/,$p' || true
  else
    echo "[WARN] Aucun run trouvé pour ${HEAD_SHA:0:7}. Ouvrez l’onglet Actions et relancez si besoin."
  fi
else
  echo "[INFO] gh introuvable — relancez la CI depuis l’UI GitHub si besoin."
fi

echo
echo "=== 5) Vérif locale (facultatif) ==="
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --all-files || true
fi
