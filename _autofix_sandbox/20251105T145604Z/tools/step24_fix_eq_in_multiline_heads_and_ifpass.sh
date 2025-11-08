#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP24] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP24] 1) Cibler '=' en condition (incl. multi-ligne) + 'expected an indented block after if'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step24_targets.lst || true
wc -l zz-out/_step24_targets.lst

echo "[STEP24] 2) Fix '=' (têtes mono/multi-lignes) + ajouter 'pass' si corps manquant"
python3 - <<'PY'
from pathlib import Path
import re

targets = Path("zz-out/_step24_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN = "([{"; CLOSE = ")]}"
NEXT_KWS = re.compile(r'^\s*(elif|else|except|finally)\b')
HEAD_START = re.compile(r'^(\s*)(if|elif|while)\b')

def head_span(lines, i, max_look=20):
    """Retourne (j_last, text) couvrant la tête if/elif/while depuis i jusqu’au ':' au niveau 0."""
    indent = len(lines[i]) - len(lines[i].lstrip(" "))
    d = 0; sq = dq = False
    buf = []
    j = i
    while j < len(lines) and j < i + max_look:
        s = lines[j]
        buf.append(s)
        k = 0
        while k < len(s):
            c = s[k]
            if sq:
                if c == '\\\\': k += 2; continue
                if c == "'": sq = False
            elif dq:
                if c == '\\\\': k += 2; continue
                if c == '"': dq = False
            else:
                if c == '#':  # commentaire -> fin de ligne
                    break
                if c == "'": sq = True
                elif c == '"': dq = True
                elif c in OPEN: d += 1
                elif c in CLOSE: d = max(0, d-1)
                elif c == ':' and d == 0:
                    # ':' de fin de tête trouvé
                    return j, "".join(buf)
            k += 1
        j += 1
    return None, "".join(buf)  # pas de ':' trouvé (on laissera tomber le fix '=').

def eq_positions_at_top_level(head_text):
    """Positions des '=' au niveau 0 (hors (), [], {}), pas partie de ==, !=, <=, >=, :=."""
    pos = []
    d = 0; sq = dq = False
    i = 0
    while i < len(head_text):
        c = head_text[i]
        if sq:
            if c == '\\\\': i += 2; continue
            if c == "'": sq = False
        elif dq:
            if c == '\\\\': i += 2; continue
            if c == '"': dq = False
        else:
            if c == '#':  # commentaire -> ignorer fin
                break
            if c in OPEN: d += 1
            elif c in CLOSE: d = max(0, d-1)
            elif c == '=' and d == 0:
                prev = head_text[i-1] if i > 0 else ''
                nxt = head_text[i+1] if i+1 < len(head_text) else ''
                if nxt == '=' or prev in ('!', '<', '>') or prev == ':' :
                    pass  # ==, !=, <=, >=, := -> ok
                else:
                    pos.append(i)
        i += 1
    return pos

def apply_replacements_chunk(orig_chunk, positions):
    if not positions: return orig_chunk
    out = list(orig_chunk)
    for p in reversed(positions):
        out[p:p+1] = ['=','=']  # '=' -> '=='
    return "".join(out)

def insert_pass_if_needed(lines, head_start_i, head_end_j):
    """Ajoute un 'pass' si la première ligne utile après la tête n’est pas plus indentée."""
    base_indent = len(lines[head_start_i]) - len(lines[head_start_i].lstrip(" "))
    k = head_end_j + 1
    # sauter lignes vides/commentées
    while k < len(lines) and (lines[k].strip() == "" or lines[k].lstrip().startswith("#")):
        k += 1
    # si fichier finit ou bloc non indenté / mot-clé suivant -> insérer pass
    need_pass = (k >= len(lines) or
                 (len(lines[k]) - len(lines[k].lstrip(" ")) <= base_indent) or
                 NEXT_KWS.match(lines[k]))
    if need_pass:
        lines.insert(head_end_j + 1, " " * (base_indent + 4) + "pass\n")
        return True
    return False

tot_files = 0; tot_eq = 0; tot_pass = 0
for path in targets:
    p = Path(path)
    raw = p.read_text(encoding="utf-8")
    lines = raw.splitlines(keepends=True)
    changed_file = False
    i = 0
    while i < len(lines):
        m = HEAD_START.match(lines[i])
        if not m:
            i += 1; continue
        # capturer la tête potentiellement multi-ligne
        j_end, head_text = head_span(lines, i)
        if j_end is None:
            # tête cassée sans ':' -> on ne touche pas à l'égalité
            i += 1
            continue
        # appliquer '=' -> '==' au niveau 0 de la tête
        chunk = "".join(lines[i:j_end+1])
        rel_positions = eq_positions_at_top_level(head_text)
        if rel_positions:
            new_chunk = apply_replacements_chunk(chunk, rel_positions)
            if new_chunk != chunk:
                lines[i:j_end+1] = new_chunk.splitlines(keepends=True)
                changed_file = True
                tot_eq += len(rel_positions)
                # réviser j_end si le découpage a bougé (il ne bougera pas, juste 1 char/eq)
                j_end = i + (new_chunk.count("\n"))
        # insérer pass si nécessaire
        if insert_pass_if_needed(lines, i, j_end):
            changed_file = True
            tot_pass += 1
            # avancer après le 'pass'
            i = j_end + 2
        else:
            i = j_end + 1
    new = "".join(lines)
    if new != raw:
        p.write_text(new, encoding="utf-8")
        tot_files += 1
        print(f"[STEP24-FIX] {path}: eq_edits~={new.count('==')-raw.count('==')} pass_added~={'YES' if 'pass\n' in new and 'pass\n' not in raw else 'NO'}")
print(f"[RESULT] step24_changed_files={tot_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP24] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
