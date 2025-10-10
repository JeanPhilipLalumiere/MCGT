#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP23] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP23] 1) Cibler '=' en tête de condition + 'unexpected indent'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: unexpected indent/) print $1
}' "$CSV" | sort -u > zz-out/_step23_targets.lst || true
wc -l zz-out/_step23_targets.lst

echo "[STEP23] 2) Fix '=' dans if/elif/while (hors parenthèses) + normalisation d'indentation inattendue"
python3 - <<'PY'
from pathlib import Path
import io, re, tokenize

targets = Path("zz-out/_step23_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

def find_head_colon(line: str) -> int | None:
    """Index of the ':' that closes if/elif/while head (depth==0, outside quotes)."""
    d = 0
    sq = dq = False
    i = 0
    while i < len(line):
        c = line[i]
        if sq:
            if c == '\\\\': i += 2; continue
            if c == "'": sq = False
        elif dq:
            if c == '\\\\': i += 2; continue
            if c == '"': dq = False
        else:
            if c == "'": sq = True
            elif c == '"': dq = True
            elif c in "([{": d += 1
            elif c in ")]}": d = max(0, d-1)
            elif c == ":" and d == 0:
                return i
        i += 1
    return None

def fix_eq_in_head_line(line: str) -> tuple[str, bool]:
    """On remplace '=' par '==' dans la tête if/elif/while UNIQUEMENT au niveau 0 (pas dans (...) )."""
    m = re.match(r'^(\s*)(if|elif|while)\b(.*)$', line)
    if not m: return line, False
    # découper jusqu'au ':' de fin de tête
    colon = find_head_colon(line)
    if colon is None:  # tête multi-ligne ou cassée → ne pas toucher
        return line, False
    head = line[:colon]  # inclut le mot-clé
    tail = line[colon:]  # ':' et suite
    # tokeniser seulement la tête pour être robuste
    try:
        toks = list(tokenize.generate_tokens(io.StringIO(head).readline))
    except tokenize.TokenError:
        return line, False
    out = []
    depth = 0
    changed = False
    for t in toks:
        ttype, tstr, start, end, l = t
        if ttype == tokenize.OP:
            if tstr in "([{": depth += 1
            elif tstr in ")]}": depth = max(0, depth-1)
            elif tstr == "=" and depth == 0:
                # '=' top-level dans une condition → probablement un bug → '=='
                t = tokenize.TokenInfo(type=tokenize.OP, string="==", start=start, end=end, line=l)
                changed = True
        out.append(t)
    fixed_head = tokenize.untokenize(out)
    return fixed_head + tail, changed

CTRL_OPENERS = re.compile(r':\s*(#.*)?$|^\s*(if|elif|for|while|try|with|def|class)\b')

def count_paren(s: str) -> int:
    d=0; sq=dq=False; i=0
    while i < len(s):
        c=s[i]
        if sq:
            if c=='\\\\': i+=2; continue
            if c=="'": sq=False
        elif dq:
            if c=='\\\\': i+=2; continue
            if c=='"': dq=False
        else:
            if c in "([{": d+=1
            elif c in ")]}": d=max(0,d-1)
            elif c=='#': break
        i+=1
    return d

def fix_unexpected_indent(lines: list[str]) -> tuple[list[str], bool]:
    """Dé-dente les lignes indentes alors que la précédente significative
    n'ouvre pas de bloc et que le comptage de parenthèses est nul."""
    changed = False
    prev_sig = -1
    for i, s in enumerate(lines):
        if s.strip() == "" or s.lstrip().startswith("#"):
            continue
        # calculer indentation courante
        indent = len(s) - len(s.lstrip(" "))
        # retrouver la précédente significative
        j = i-1
        while j >= 0 and (lines[j].strip() == "" or lines[j].lstrip().startswith("#")):
            j -= 1
        if j >= 0:
            prev = lines[j]
            prev_indent = len(prev) - len(prev.lstrip(" "))
            opens_block = bool(CTRL_OPENERS.search(prev))
            paren_open = count_paren(prev) > 0
            if indent > prev_indent and not opens_block and not paren_open:
                # dé-dente au même niveau que prev
                new = " " * prev_indent + s.lstrip(" ")
                if new != s:
                    lines[i] = new
                    changed = True
        else:
            # début de fichier indente → dé-dente
            if indent > 0:
                lines[i] = s.lstrip(" ")
                changed = True
    return lines, changed

tot_files = eq_files = indent_files = 0
for path in targets:
    p = Path(path)
    raw = p.read_text(encoding="utf-8")
    new_lines = raw.splitlines(keepends=True)
    eq_changed_any = False
    # passe 1: '=' dans têtes monolignes
    for idx, s in enumerate(new_lines):
        fixed, ch = fix_eq_in_head_line(s)
        if ch:
            new_lines[idx] = fixed
            eq_changed_any = True
    # passe 2: normaliser indentations inattendues
    new_lines2, indent_changed = fix_unexpected_indent(new_lines)
    new = "".join(new_lines2)
    if new != raw:
        p.write_text(new, encoding="utf-8")
        tot_files += 1
        eq_files += int(eq_changed_any)
        indent_files += int(indent_changed)
        print(f"[STEP23-FIX] {path}: eq_heads={'YES' if eq_changed_any else 'NO'} unexpected_indent_fix={'YES' if indent_changed else 'NO'}")
print(f"[RESULT] step23_changed_files={tot_files} eq_head_files~={eq_files} indent_fixed_files~={indent_files}")
PY

echo "[STEP23] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
