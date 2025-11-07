#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -Eeuo pipefail

trap 'cleanup 0' EXIT

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WF_FILE="${1:-.github/workflows/sanity-main.yml}"
[[ -f "$WF_FILE" ]] || {
  echo "[ERREUR] Fichier introuvable: $WF_FILE" >&2
  exit 1
}

echo "=== 0) Sauvegarde ==="
TS="$(date +%Y%m%dT%H%M%S)"
cp -v -- "$WF_FILE" "${WF_FILE}.bak.${TS}"

echo "=== 1) Fusion des {…} >> cible consécutifs (et normalisation __TMP) ==="
python3 - "$WF_FILE" <<'PY'
import re, sys
wf = sys.argv[1]
with open(wf, "r", encoding="utf-8") as f:
    L = f.readlines()

def ind(s): return len(s) - len(s.lstrip(" "))
blank = lambda s: s.strip()==""
comment = lambda s: s.lstrip().startswith("#")
heredoc = re.compile(r'(?<!\\)<<-?\s*[\'"]?[A-Za-z0-9_]+[\'"]?')

re_run = re.compile(r'^(\s*)run:\s*\|')
# cible capturée après ">>"
re_close = re.compile(
    r'^\s*\}\s*>>\s*(?P<tgt>'
    r'\"?\$?\{?GITHUB_OUTPUT\}?\"?'
    r'|\"?\$?\{?GITHUB_STEP_SUMMARY\}?\"?'
    r'|\"?__TMP_[A-Za-z0-9_]+__\"?'
    r')\s*(?:#.*)?$'
)

def norm_tgt(t: str) -> str:
    t = t.strip()
    # "__TMP_*__" -> "$__TMP_*__" en conservant les guillemets si présents
    if t.startswith('"__TMP_') and t.endswith('__"'):
        return '"$' + t[1:]
    if t.startswith("'__TMP_") and t.endswith("__'"):
        return "'$" + t[1:]
    if t.startswith('__TMP_') and t.endswith('__'):
        return '$' + t
    return t

def parse_group(block, i):
    # doit être une ligne "{" seule (après trim)
    if block[i].strip() != "{":
        return None
    k = i + 1
    while k < len(block) and block[k].strip() != "}":
        if heredoc.search(block[k]):   # ne traverse pas un here-doc
            return None
        k += 1
    if k >= len(block):
        return None
    m = re_close.match(block[k])
    if not m:
        return None
    tgt = norm_tgt(m.group("tgt"))
    body = block[i+1:k]  # on garde l'indentation d’origine
    return {"end": k+1, "tgt": tgt, "body": body, "open_i": i, "close_i": k}

def merge_block(block, base_indent):
    out = []
    cur_tgt = None
    acc = []      # liste de bodies à fusionner
    gaps = []     # commentaires/lignes vides entre blocs

    def flush():
        nonlocal cur_tgt, acc, gaps, out
        if cur_tgt is None:
            out.extend(gaps); gaps.clear()
            return
        pad = " " * (base_indent + 2)
        if len(acc) == 1:
            # restituer intact si un seul (avec gaps autour)
            out.extend(gaps); gaps.clear()
            out.append(pad + "{\n")
            out.extend(acc[0])
            out.append(pad + "} >> " + cur_tgt + "\n")
        else:
            out.extend(gaps); gaps.clear()
            out.append(pad + "{\n")
            # insérer les corps + gaps internes tels quels
            for n, body in enumerate(acc):
                out.extend(body)
            out.append(pad + "} >> " + cur_tgt + "\n")
        cur_tgt = None
        acc.clear()

    i = 0
    while i < len(block):
        s = block[i]
        if heredoc.search(s):
            flush(); out.append(s); i += 1; continue
        if blank(s) or comment(s):
            if cur_tgt is None: out.append(s)
            else: gaps.append(s)
            i += 1; continue
        g = parse_group(block, i)
        if g:
            if cur_tgt is None:
                cur_tgt = g["tgt"]; acc.append(g["body"])
            elif g["tgt"] == cur_tgt:
                acc.append(g["body"])
            else:
                flush()
                cur_tgt = g["tgt"]; acc.append(g["body"])
            i = g["end"]
            continue
        # toute autre ligne coupe la séquence
        flush(); out.append(s); i += 1
    flush()
    return out

i = 0
while i < len(L):
    m = re_run.match(L[i])
    if not m:
        i += 1; continue
    base = ind(L[i])
    j = i + 1
    # prendre tout le bloc "run: |" (indent strictement > base)
    while j < len(L) and (ind(L[j]) > base or L[j].strip()==""):
        j += 1
    block = L[i+1:j]
    new = merge_block(block, base)
    L = L[:i+1] + new + L[j:]
    i = i + 1 + len(new)

with open(wf, "w", encoding="utf-8") as f:
    f.write("".join(L))
PY

echo
echo "=== 2) DIFF ==="
git --no-pager diff -- "$WF_FILE" || true

if git diff --quiet -- "$WF_FILE"; then
  echo "[INFO] Aucun changement à commit."
else
  echo
  echo "=== 3) COMMIT ==="
  git add -- "$WF_FILE"
  git commit -m "ci: SC2129 — fusionne les blocs {…} >> cible et normalise les cibles __TMP_*__"
fi
