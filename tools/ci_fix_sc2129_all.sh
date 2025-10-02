#!/usr/bin/env bash
set -Eeuo pipefail

trap 'cleanup 0' EXIT

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WF_FILE="${1:-.github/workflows/sanity-main.yml}"
[[ -f "$WF_FILE" ]] || { echo "[ERREUR] Fichier introuvable: $WF_FILE" >&2; exit 1; }

echo "=== 0) Sauvegarde ==="
TS="$(date +%Y%m%dT%H%M%S)"
cp -v -- "$WF_FILE" "${WF_FILE}.bak.${TS}"

echo "=== 1) Réécriture SC2129 (groupement + fix __TMP) ==="
python3 - "$WF_FILE" <<'PY'
import re, sys

wf = sys.argv[1]
with open(wf, "r", encoding="utf-8") as f:
    L = f.readlines()

def ind(s): return len(s) - len(s.lstrip(" "))
def blank(s): return s.strip() == ""
def comment(s): return s.lstrip().startswith("#")

re_run_block  = re.compile(r'^(\s*)run:\s*([|>])\s*(#.*)?$')
re_run_inline = re.compile(r'^(\s*)run:\s*(?![|>])(\S.*)$')
heredoc = re.compile(r'(?<!\\)<<-?\s*[\'"]?[A-Za-z0-9_]+[\'"]?')

# cibles acceptées : $GITHUB_OUTPUT, $GITHUB_STEP_SUMMARY, $__TMP_*__
TGT = r'"?\$(?:\{)?(?P<env>GITHUB_OUTPUT|GITHUB_STEP_SUMMARY|__TMP_[A-Za-z0-9_]+__)(?:\})?"?'
redir = re.compile(r'(?P<body>.*?)\s*>>\s*(?P<tgt>'+TGT+r')\s*(?P<cm>#.*)?$')

def norm_tgt(t: str) -> str:
    t = t.strip()
    # "__TMP_XXX__" (sans $) -> "$__TMP_XXX__"
    if t.startswith('"__TMP_') and t.endswith('__"'):
        return '"$' + t[1:]
    if t.startswith('__TMP_') and t.endswith('__'):
        return '$' + t
    return t

def render_group(cmds, base_indent, tgt):
    pad = " " * (base_indent + 2)
    out = [pad + "{\n"]
    for s in cmds:
        if s.endswith("\n"):
            out.append(pad + s.lstrip())
        else:
            out.append(pad + s.lstrip() + "\n")
    out.append(pad + "} >> " + tgt + "\n")
    return out

def try_brace(block, i):
    """Si block[i] ouvre '{' et si on trouve '}' suivi d'une redirection >> tgt sur la même ligne, retourne ce segment."""
    if i >= len(block): return None
    if block[i].strip() != "{": return None
    k = i + 1
    while k < len(block) and block[k].strip() != "}":
        if heredoc.search(block[k]):  # ne traverse pas les here-docs
            return None
        k += 1
    if k >= len(block): return None
    # ligne de fermeture + redirection: "}" peut être suivi de >> tgt
    tail = block[k].split("}", 1)
    rest = tail[1] if len(tail) == 2 else ""
    m = redir.match(rest)
    if not m:
        return None
    tgt = norm_tgt(m.group("tgt"))
    body = block[i+1:k]
    return {"end": k+1, "tgt": tgt, "body": body, "orig": block[i:k+1]}

def process_block(block, base):
    out = []
    cur_tgt = None
    seq_cmds = []   # éléments { "body": [lines], "orig": [lines] }
    seq_gaps = []   # commentaires/vides tolérés au milieu

    def flush():
        nonlocal cur_tgt, seq_cmds, seq_gaps, out
        if cur_tgt is None:
            out.extend(seq_gaps)
            seq_gaps.clear()
            return
        if len(seq_cmds) <= 1:
            out.extend(seq_gaps)
            out.extend(seq_cmds[0]["orig"])
        else:
            body = []
            for piece in seq_cmds:
                # extrait seulement le contenu des commandes (sans la redirection)
                body.extend([l for l in piece["body"]])
            out.extend(seq_gaps)
            out.extend(render_group(body, base, cur_tgt))
        cur_tgt = None
        seq_cmds.clear()
        seq_gaps.clear()

    i = 0
    while i < len(block):
        s = block[i]
        if heredoc.search(s):
            flush()
            out.append(s)
            i += 1
            continue
        if blank(s) or comment(s):
            if cur_tgt is not None:
                seq_gaps.append(s)
            else:
                out.append(s)
            i += 1
            continue
        bb = try_brace(block, i)
        if bb:
            tgt = bb["tgt"]
            if cur_tgt is None:
                cur_tgt = tgt
                seq_cmds.append({"body": [l for l in bb["body"]], "orig": [l for l in bb["orig"]]})
                i = bb["end"]
                continue
            if tgt == cur_tgt:
                seq_cmds.append({"body": [l for l in bb["body"]], "orig": [l for l in bb["orig"]]})
                i = bb["end"]
                continue
            flush()
            cur_tgt = tgt
            seq_cmds.append({"body": [l for l in bb["body"]], "orig": [l for l in bb["orig"]]})
            i = bb["end"]
            continue
        m = redir.match(s)
        if m and any(x in m.group("tgt") for x in ("GITHUB_OUTPUT","GITHUB_STEP_SUMMARY","__TMP_")):
            tgt = norm_tgt(m.group("tgt"))
            body = (m.group("body") or "").rstrip() + "\n"
            if cur_tgt is None:
                cur_tgt = tgt
                seq_cmds.append({"body": [body], "orig": [s]})
                i += 1
                continue
            if tgt == cur_tgt:
                seq_cmds.append({"body": [body], "orig": [s]})
                i += 1
                continue
            flush()
            cur_tgt = tgt
            seq_cmds.append({"body": [body], "orig": [s]})
            i += 1
            continue
        # autre commande -> on clôt si une séquence était en cours
        flush()
        out.append(s)
        i += 1

    flush()
    return out

i = 0
while i < len(L):
    m = re_run_block.match(L[i])
    if m:
        base = ind(L[i])
        j = i + 1
        while j < len(L) and (ind(L[j]) > base or blank(L[j])):
            j += 1
        block = L[i+1:j]
        new_block = process_block(block, base)
        L = L[:i+1] + new_block + L[j:]
        i = i + 1 + len(new_block)
        continue
    m2 = re_run_inline.match(L[i])
    if m2:
        base = len(m2.group(1))
        block = [(" " * (base + 2)) + m2.group(2) + "\n"]
        new_block = process_block(block, base)
        L = L[:i] + [m2.group(1) + "run: |\n"] + new_block + L[i+1:]
        i = i + 1 + len(new_block)
        continue
    i += 1

with open(wf, "w", encoding="utf-8") as f:
    f.write("".join(L))
PY

echo
echo "=== 2) DIFF ==="
git --no-pager diff -- "$WF_FILE" || true

if ! git diff --quiet -- "$WF_FILE"; then
  echo
  echo "=== 3) COMMIT ==="
  git add -- "$WF_FILE"
  git commit -m "ci: SC2129 — groupe les appends en { … } >> cible et corrige les __TMP quotes"
else
  echo "[INFO] Aucun changement à commit."
fi
